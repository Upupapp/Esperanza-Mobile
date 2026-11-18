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

  /// The website's page size (scope-citizen.js FEED_PAGE).
  static const pageSize = 20;

  int _page = 0;
  int _lastPage = 0;
  bool _loadingMore = false;

  /// More posts on the server than are loaded (the website's "Load more").
  bool get hasMore => _page < _lastPage;
  bool get loadingMore => _loadingMore;

  /// GET /announcements, the first page, newest first. Public, so a Guest
  /// gets the same feed; with a signed-in citizen's token (ApiClient sends it
  /// on every request) the server keeps to their barangay's posts and the
  /// municipality's, and says which they liked.
  Future<void> loadFeed() async {
    _loaded = false;
    scheduleMicrotask(notifyListeners);
    try {
      final res = await api.get('/announcements', query: {'per_page': pageSize, 'page': 1});
      _posts = _sorted(JsonRead.rows(res.list, Announcement.fromAnnouncementApi));
      _page = 1;
      _lastPage = JsonRead.integer(res.meta?['last_page']) ?? 1;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Bumped by [clear] (sign-out): a background refresh that was under way
  /// then must not bring the previous resident's feed back.
  int _generation = 0;

  /// The first page again, in the background (live updates, 2026-11-15):
  /// the feed on screen stays until it arrives, and stays if this fails (it
  /// throws). New posts come in at the top and changed ones (a like or
  /// comment count, an edit) are replaced; posts from the pages loaded below
  /// it are kept, so a resident who loaded more is not sent back to the top.
  /// A post whose like is still being sent keeps its own copy. Nothing
  /// happens before the first [loadFeed] has finished: that one is fresh.
  Future<void> refreshFeed() async {
    if (!_loaded) return;
    final generation = _generation;
    final res = await api.get('/announcements', query: {'per_page': pageSize, 'page': 1});
    if (generation != _generation || !_loaded) return;
    final first = JsonRead.rows(res.list, Announcement.fromAnnouncementApi);
    final ids = {for (final p in first) p.id};
    final known = {for (final p in _posts) p.id: p};
    // A short first page is the whole feed. A full one: what is kept from
    // before is what lies below it (older than its oldest post); one that
    // was on the first page and is not any more was taken down.
    DateTime? oldest;
    for (final p in first) {
      final at = p.at;
      if (at != null && (oldest == null || at.isBefore(oldest))) oldest = at;
    }
    final below = first.length < pageSize
        ? const <Announcement>[]
        : [
            for (final p in _posts)
              if (!ids.contains(p.id) && oldest != null && (p.at ?? DateTime(0)).isBefore(oldest)) p,
          ];
    _posts = _sorted([
      for (final p in first) _likesInFlight.contains(p.id) ? (known[p.id] ?? p) : p,
      ...below,
    ]);
    final last = JsonRead.integer(res.meta?['last_page']) ?? 1;
    if (_page <= 1 || first.length < pageSize) _page = 1;
    _lastPage = last > _page ? last : _page;
    notifyListeners();
  }

  /// The next page, added under what is loaded (each post once).
  Future<void> loadMore() async {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final next = _page + 1;
      final res = await api.get('/announcements', query: {'per_page': pageSize, 'page': next});
      final known = {for (final p in _posts) p.id};
      _posts = _sorted([
        ..._posts,
        ...JsonRead.rows(res.list, Announcement.fromAnnouncementApi).where((p) => !known.contains(p.id)),
      ]);
      _page = next;
      _lastPage = JsonRead.integer(res.meta?['last_page']) ?? next;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  static List<Announcement> _sorted(List<Announcement> posts) =>
      posts..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));

  /// Posts opened on their own ([loadAnnouncement]) that the loaded feed
  /// does not hold, by [Announcement.remoteId]. Kept apart from [posts]: in
  /// the feed, a weeks-old post read as the newest Balita on Home, and a post
  /// for another barangay (which the server's feed leaves out for this
  /// resident) showed in their "All" feed; and the feed's first page,
  /// arriving after it at a cold start, replaced the feed without it (QA
  /// sweep 2026-11-18). Screens find a post with [find] / [findById].
  final Map<int, Announcement> _opened = {};

  /// The post with this [Announcement.remoteId]: the feed's copy, else one
  /// opened on its own.
  Announcement? find(int remoteId) {
    for (final p in _posts) {
      if (p.remoteId == remoteId) return p;
    }
    return _opened[remoteId];
  }

  /// The same, by [Announcement.id].
  Announcement? findById(String id) {
    for (final p in _posts) {
      if (p.id == id) return p;
    }
    for (final p in _opened.values) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// One announcement, for a "New in Balita" notification that opens it
  /// (Esperanza QA, 2026-10-07): the loaded feed's copy when it has one,
  /// otherwise GET /announcements/{id}, which is how an older post that is
  /// not in the first pages is still found. Kept so a like or a comment on
  /// it updates the same object on every screen that shows it, but not in
  /// the feed (see [_opened]).
  Future<Announcement> loadAnnouncement(int id) async {
    final known = find(id);
    if (known != null) return known;
    final generation = _generation;
    final res = await api.get('/announcements/$id');
    final post = Announcement.fromAnnouncementApi(res.map);
    // Signed out meanwhile: kept away from the next resident.
    if (generation != _generation) return post;
    // The feed brought it in meanwhile: that copy, once.
    final arrived = find(id);
    if (arrived != null) return arrived;
    _opened[id] = post;
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
    _generation++;
    _posts = [];
    _opened.clear();
    _loaded = false;
    _page = 0;
    _lastPage = 0;
    notifyListeners();
  }
}
