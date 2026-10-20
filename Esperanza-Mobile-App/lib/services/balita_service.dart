import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'json_read.dart';
import '../models/announcement.dart';

/// Balita: the LGU's announcements, against the real backend
/// (production-readiness programme, 2026-09-25). Previously a local,
/// frontend-only "database" persisted to SharedPreferences, simulating
/// likes/comments/shares itself -- the server is now the only source of
/// truth, so nothing here is persisted locally anymore.
///
/// Only the LGU posts to Balita (owner, 2026-10-20): residents read, like,
/// comment and share. Residents' own community posts, their composer, post
/// reports and the resident upload routes are gone from the app and the
/// server alike, so GET /announcements is the whole feed.
class BalitaService extends ChangeNotifier {
  List<Announcement> _posts = [];
  bool _loaded = false;
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

  /// The backend's limit (CitizenPortalController::commentOn*), enforced
  /// where the citizen types.
  static const commentMaxLength = 1000;

  /// GET /announcements, newest first. Public, so a Guest gets the same
  /// feed; with a signed-in citizen's token (ApiClient sends it on every
  /// request) it also says which posts they liked.
  Future<void> loadFeed() async {
    _loaded = false;
    scheduleMicrotask(notifyListeners);
    try {
      final rows = await api.getAllPages('/announcements', query: {'per_page': 50}, maxPages: 2);
      _posts = JsonRead.rows(rows, Announcement.fromAnnouncementApi)
        ..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// One announcement, for a "New in Balita" notification that opens it
  /// (Esperanza QA, 2026-10-07): the loaded feed's copy when it has one,
  /// otherwise GET /announcements/{id}, which is how an older post that is
  /// not in the first pages is still found. Added to the feed so a like or a
  /// comment on it updates the same object everywhere.
  Future<Announcement> loadAnnouncement(int id) async {
    for (final p in _posts) {
      if (p.remoteId == id) return p;
    }
    final res = await api.get('/announcements/$id');
    final post = Announcement.fromAnnouncementApi(res.map);
    _posts = [post, ..._posts];
    notifyListeners();
    return post;
  }

  // Every engagement route lives under the backend's `citizen` group
  // (esperanza-backend routes/api.php, `prefix('citizen')`); only the
  // announcements *read* is public. These used to omit the prefix, so every
  // like and comment answered 404.
  String _likePath(Announcement post) => '/citizen/announcements/${post.remoteId}/like';

  String _commentsPath(Announcement post) => '/citizen/announcements/${post.remoteId}/comments';

  /// Toggles like/unlike -- the endpoint is POST-to-toggle, returning
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

  /// The author deletes their own comment (2026-10-18).
  Future<void> deleteComment(Announcement post, PostComment comment) async {
    await api.delete('${_commentsPath(post)}/${comment.id}');
    if (post.commentsCount > 0) post.commentsCount -= 1;
    notifyListeners();
  }

  /// In-memory only now -- there is nothing left to erase from disk once
  /// Balita stopped persisting to SharedPreferences. Called on sign-out.
  void clear() {
    _posts = [];
    _loaded = false;
    notifyListeners();
  }
}
