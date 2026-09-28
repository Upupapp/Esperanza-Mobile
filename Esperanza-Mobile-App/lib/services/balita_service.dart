import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'json_read.dart';
import '../models/announcement.dart';

/// Balita: announcements and the community feed, against the real backend
/// (production-readiness programme, 2026-09-25). Previously a local,
/// frontend-only "database" persisted to SharedPreferences, simulating
/// likes/comments/shares itself -- the server is now the only source of
/// truth, so nothing here is persisted locally anymore.
///
/// Two real tables, merged into one feed exactly like the Web Admin's own
/// citizen/announcements.blade.php does client-side (`kind: 'announcement' |
/// 'community'`) -- that file is the contract this mirrors: GET
/// /announcements (admin-published, public) and GET /community-posts
/// (citizen-authored, requires sign-in). A citizen can also create a
/// community post now (POST /community-posts) -- a real capability neither
/// frontend used before this (see [createPost]'s own doc comment).
class BalitaService extends ChangeNotifier {
  List<Announcement> _posts = [];
  bool _loaded = false;
  bool _communityUnavailable = false;
  final Set<String> _likesInFlight = {};

  BalitaService() {
    ApiClient.addSessionExpiredListener(clear);
  }

  @override
  void dispose() {
    ApiClient.removeSessionExpiredListener(clear);
    super.dispose();
  }

  List<Announcement> get posts => List.unmodifiable(_posts);
  bool get loaded => _loaded;

  /// True when the last [loadFeed] got announcements but the community half
  /// failed -- the feed is shown partial rather than not at all.
  bool get communityUnavailable => _communityUnavailable;

  /// GET /announcements + GET /citizen/community-posts, merged and sorted newest
  /// first. The community-posts fetch needs a signed-in citizen (it's
  /// under the `citizen` route prefix); a Guest still sees the public
  /// announcements half of the feed rather than nothing at all.
  Future<void> loadFeed({required bool signedIn}) async {
    _loaded = false;
    scheduleMicrotask(notifyListeners);
    try {
      // Announcements are public and are the half a citizen must always get.
      // The two used to share one Future.wait, so a failing /community-posts
      // (an unverified account refused, a server error on that table alone)
      // took the official LGU announcements down with it.
      final announcementsFuture = api.getAllPages('/announcements', query: {'per_page': 50}, maxPages: 2);
      final communityFuture = signedIn
          ? api.getAllPages('/citizen/community-posts', query: {'per_page': 50}, maxPages: 2).then<List<dynamic>?>((r) => r)
          : Future<List<dynamic>?>.value(const []);
      final communityGuarded = communityFuture.catchError((Object _) => null);

      final announcements = JsonRead.rows(await announcementsFuture, Announcement.fromAnnouncementApi);
      final communityRaw = await communityGuarded;
      _communityUnavailable = communityRaw == null;
      final community = JsonRead.rows(communityRaw, Announcement.fromCommunityApi)
          // Belt and braces for [Announcement.visible]: a post still in
          // moderation is shown only to its author.
          .where((p) => p.visible || p.mine);

      _posts = [...announcements, ...community]
        ..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  // Every engagement route lives under the backend's `citizen` group
  // (esperanza-backend routes/api.php, `prefix('citizen')`); only the
  // announcements *read* is public. These used to omit the prefix, so every
  // like, comment, community read and post answered 404.
  String _likePath(Announcement post) => post.kind == PostKind.announcement
      ? '/citizen/announcements/${post.remoteId}/like'
      : '/citizen/community-posts/${post.remoteId}/like';

  String _commentsPath(Announcement post) => post.kind == PostKind.announcement
      ? '/citizen/announcements/${post.remoteId}/comments'
      : '/citizen/community-posts/${post.remoteId}/comments';

  /// Toggles like/unlike -- both endpoints are POST-to-toggle, returning
  /// the server's own new `{liked, likes}` rather than the client guessing
  /// at the new count.
  ///
  /// A second tap while the first is still in flight is ignored: two
  /// toggles racing each other leave the server at its starting state while
  /// the UI shows whichever reply arrived last.
  Future<void> toggleLike(Announcement post) async {
    if (!_likesInFlight.add(post.id)) return;
    try {
      final res = await api.post(_likePath(post));
      post.likedByMe = JsonRead.boolean(res.map['liked']) ?? !(post.likedByMe ?? false);
      post.likes = JsonRead.integer(res.map['likes']) ?? post.likes;
      notifyListeners();
    } finally {
      _likesInFlight.remove(post.id);
    }
  }

  Future<List<PostComment>> loadComments(Announcement post) async {
    final rows = await api.getAllPages(_commentsPath(post), query: {'per_page': 50}, maxPages: 4);
    return JsonRead.rows(rows, PostComment.fromApi);
  }

  Future<PostComment> addComment(Announcement post, String body) async {
    final res = await api.post(_commentsPath(post), body: {'body': body.trim()});
    final comment = PostComment.fromApi(res.map);
    post.commentsCount += 1;
    notifyListeners();
    return comment;
  }

  /// Community posts only -- announcements have no report endpoint (a
  /// citizen doesn't "report" official LGU content). Throws [ApiException]
  /// as normal if [post] isn't a community post; callers gate the Report
  /// menu item on `post.kind == PostKind.community` first (see PostCard).
  Future<void> reportPost(Announcement post, String reason) async {
    await api.post('/citizen/community-posts/${post.remoteId}/report', body: {'reason': reason});
  }

  /// POST /community-posts -- a real citizen-posting capability (image
  /// upload, category, gated by CitizenCapabilities::COMMUNITY_POST at
  /// minimum AccessLevel.unverified) that neither this app nor the Web
  /// Admin's own citizen/announcements.blade.php used before this
  /// (production-readiness programme, 2026-09-25 -- confirmed against the
  /// backend directly, not assumed). Pre-moderated: the returned post is
  /// visible only to its own author (`mine: true`) until an information
  /// officer approves it, then everyone. Multipart only when [imageFilePath]
  /// is given -- the field is nullable server-side, so a plain JSON POST
  /// with no `image` key is a normal, valid text-only post.
  Future<Announcement> createPost({required String body, required String category, String? imageFilePath}) async {
    final res = imageFilePath != null
        ? await api.postMultipart(
            '/citizen/community-posts',
            filePath: imageFilePath,
            fileField: 'image',
            fields: {'body': body, 'category': category},
          )
        : await api.post('/citizen/community-posts', body: {'body': body, 'category': category});
    final Announcement post;
    try {
      post = Announcement.fromCommunityApi(res.map);
    } on FormatException {
      // Created on the server but unreadable here: reported as an error so
      // the composer does not close on a post the feed cannot show.
      throw const ApiException(
        messageEn: 'Your post was sent, but could not be shown. Pull down to refresh.',
        messageFil: 'Naipadala ang iyong post pero hindi maipakita. I-refresh ang feed.',
      );
    }
    _posts.insert(0, post);
    notifyListeners();
    return post;
  }

  /// In-memory only now -- there is nothing left to erase from disk once
  /// Balita stopped persisting to SharedPreferences. Called on sign-out.
  void clear() {
    _posts = [];
    _loaded = false;
    _communityUnavailable = false;
    notifyListeners();
  }
}
