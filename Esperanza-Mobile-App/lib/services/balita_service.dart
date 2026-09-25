import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
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

  List<Announcement> get posts => List.unmodifiable(_posts);
  bool get loaded => _loaded;

  /// GET /announcements + GET /community-posts, merged and sorted newest
  /// first. The community-posts fetch needs a signed-in citizen (it's
  /// under the `citizen` route prefix); a Guest still sees the public
  /// announcements half of the feed rather than nothing at all.
  Future<void> loadFeed({required bool signedIn}) async {
    _loaded = false;
    scheduleMicrotask(notifyListeners);
    try {
      final calls = <Future<ApiResult>>[api.get('/announcements', query: {'per_page': 50})];
      if (signedIn) calls.add(api.get('/community-posts', query: {'per_page': 50}));
      final results = await Future.wait(calls);

      final announcements = results[0].list.map(
        (e) => Announcement.fromAnnouncementApi(e as Map<String, dynamic>),
      );
      final community = signedIn
          ? results[1].list.map((e) => Announcement.fromCommunityApi(e as Map<String, dynamic>))
          : const <Announcement>[];

      _posts = [...announcements, ...community]
        ..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  String _likePath(Announcement post) =>
      post.kind == PostKind.announcement ? '/announcements/${post.remoteId}/like' : '/community-posts/${post.remoteId}/like';

  String _commentsPath(Announcement post) => post.kind == PostKind.announcement
      ? '/announcements/${post.remoteId}/comments'
      : '/community-posts/${post.remoteId}/comments';

  /// Toggles like/unlike -- both endpoints are POST-to-toggle, returning
  /// the server's own new `{liked, likes}` rather than the client guessing
  /// at the new count.
  Future<void> toggleLike(Announcement post) async {
    final res = await api.post(_likePath(post));
    post.likedByMe = res.map['liked'] as bool?;
    post.likes = res.map['likes'] as int? ?? post.likes;
    notifyListeners();
  }

  Future<List<PostComment>> loadComments(Announcement post) async {
    final res = await api.get(_commentsPath(post), query: {'per_page': 50});
    return res.list.map((e) => PostComment.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<PostComment> addComment(Announcement post, String body) async {
    final res = await api.post(_commentsPath(post), body: {'body': body});
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
    await api.post('/community-posts/${post.remoteId}/report', body: {'reason': reason});
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
            '/community-posts',
            filePath: imageFilePath,
            fileField: 'image',
            fields: {'body': body, 'category': category},
          )
        : await api.post('/community-posts', body: {'body': body, 'category': category});
    final post = Announcement.fromCommunityApi(res.map);
    _posts.insert(0, post);
    notifyListeners();
    return post;
  }

  /// In-memory only now -- there is nothing left to erase from disk once
  /// Balita stopped persisting to SharedPreferences. Called on sign-out.
  void clear() {
    _posts = [];
    _loaded = false;
    notifyListeners();
  }
}
