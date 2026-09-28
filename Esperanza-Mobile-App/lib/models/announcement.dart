import 'package:intl/intl.dart';
import '../services/json_read.dart';

/// Which real table a [Announcement] came from — GET /announcements
/// (admin-published, read-only from mobile) or GET /community-posts
/// (citizen-authored, real POST /community-posts exists too — see
/// BalitaService.createPost). One merged, sorted feed either way, exactly
/// like the Web Admin's own citizen/announcements.blade.php does client-side
/// (`kind: 'announcement' | 'community'`) — that file is the contract this
/// mirrors, not a guess made independently here.
enum PostKind { announcement, community }

/// One Balita feed item — an admin-published announcement or a citizen
/// community post, both real now (production-readiness programme,
/// 2026-09-25). [id] is source-prefixed ('ann-5' / 'cp-12') since both
/// tables have their own independent integer id sequence; [remoteId] is
/// the real numeric id the two engagement endpoints (like/comment/report)
/// need.
class Announcement {
  final String id;
  final int remoteId;
  final PostKind kind;
  final String author;
  final String? barangay;
  final String? category;
  final String body;
  final String? imageUrl;
  final DateTime? at;
  int likes;

  /// Whether the signed-in citizen has already liked this post.
  ///
  /// Null for a just-loaded announcement — GET /announcements is public and
  /// unauthenticated, so it has no way to say whether *this* citizen already
  /// liked something, unlike GET /community-posts, which does return
  /// `liked_by_me` for the real signed-in citizen. Starting every
  /// announcement heart unfilled (rather than guessing) is what the Web
  /// Admin's own client-side code does too, and stays correct for the rest
  /// of this session the moment the citizen actually toggles one.
  bool? likedByMe;

  int commentsCount;

  /// Real, but never incremented by a citizen action — there is no
  /// POST .../share endpoint anywhere in the backend. Balita's own Share
  /// button still works (the OS share sheet is a real action even without
  /// a server-side counter), it just never changes this number.
  final int shares;

  /// Community posts only: the real EditorialWorkflow status
  /// ('Pending Review' until an information officer approves it, then
  /// published). Null for an announcement — nothing publishes without
  /// already being published, by construction of the public endpoint that
  /// serves them.
  final String? status;

  /// Community posts only: false while the post is [status] Pending Review
  /// and not [mine] — never actually reached, since GET /community-posts
  /// only ever returns a citizen's own posts plus everyone's *visible*
  /// ones. Kept because the real API returns it and a UI badge is cheap
  /// insurance against a future backend change silently starting to send
  /// invisible posts through.
  final bool visible;

  /// Community posts only: whether the signed-in citizen authored this
  /// post — drives the "Pending Review" badge and hides Report on a
  /// citizen's own post (matching the Web Admin's own
  /// `x-show="post.kind === 'community' && !post.mine"`).
  final bool mine;

  Announcement({
    required this.id,
    required this.remoteId,
    required this.kind,
    required this.author,
    this.barangay,
    this.category,
    required this.body,
    this.imageUrl,
    this.at,
    required this.likes,
    this.likedByMe,
    required this.commentsCount,
    this.shares = 0,
    this.status,
    this.visible = true,
    this.mine = false,
  });

  bool get isOfficial => kind == PostKind.announcement;

  /// "Just now" / "12 mins ago" / "3 hrs ago" / an absolute date beyond a
  /// day old — same thresholds as the Web Admin's own `fmtTime`.
  String get timeLabel {
    final when = at;
    if (when == null) return '';
    final minutes = DateTime.now().difference(when).inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '$minutes min${minutes == 1 ? '' : 's'} ago';
    final hours = (minutes / 60).round();
    if (hours < 24) return '$hours hr${hours == 1 ? '' : 's'} ago';
    return DateFormat('MMM d, yyyy').format(when);
  }

  /// GET /announcements (PublicContentController::announcementRow()).
  factory Announcement.fromAnnouncementApi(Map<String, dynamic> json) {
    final id = JsonRead.integer(json['id']);
    // The id addresses the like/comment endpoints; a row without one would
    // render but fail every interaction, so it is rejected (and skipped by
    // BalitaService's per-row parse) instead.
    if (id == null) throw const FormatException('announcement without an id');
    return Announcement(
      id: 'ann-$id',
      remoteId: id,
      kind: PostKind.announcement,
      author: JsonRead.nonEmpty(json['author']) ?? 'Esperanza LGU',
      barangay: JsonRead.nonEmpty(json['barangay']),
      category: JsonRead.nonEmpty(json['category']),
      body: JsonRead.string(json['body']) ?? '',
      imageUrl: JsonRead.mediaUrl(json['image_url']),
      at: JsonRead.date(json['published_at']) ?? JsonRead.date(json['created_at']),
      likes: JsonRead.integer(json['likes']) ?? 0,
      // Was never read for announcements, so a liked announcement came back
      // un-liked on every refresh and the next tap un-liked it on the server.
      likedByMe: JsonRead.boolean(json['liked_by_me']) ?? false,
      commentsCount: JsonRead.integer(json['comments_count']) ?? 0,
      shares: JsonRead.integer(json['shares']) ?? 0,
    );
  }

  /// GET /community-posts (CitizenPortalController::postRow()).
  factory Announcement.fromCommunityApi(Map<String, dynamic> json) {
    final id = JsonRead.integer(json['id']);
    if (id == null) throw const FormatException('community post without an id');
    return Announcement(
      id: 'cp-$id',
      remoteId: id,
      kind: PostKind.community,
      author: JsonRead.string(json['author']) ?? '',
      barangay: JsonRead.nonEmpty(json['barangay']),
      category: JsonRead.nonEmpty(json['category']),
      body: JsonRead.string(json['body']) ?? '',
      imageUrl: JsonRead.mediaUrl(json['image_url']),
      at: JsonRead.date(json['created_at']),
      likes: JsonRead.integer(json['likes']) ?? 0,
      likedByMe: JsonRead.boolean(json['liked_by_me']) ?? false,
      commentsCount: JsonRead.integer(json['comments_count']) ?? 0,
      status: JsonRead.nonEmpty(json['status']),
      visible: JsonRead.boolean(json['visible']) ?? true,
      mine: JsonRead.boolean(json['mine']) ?? false,
    );
  }
}

/// One comment on an announcement or a community post — both real now
/// (GET/POST .../comments), same shape either way (commentRow()).
class PostComment {
  final int id;
  final String author;
  final String body;

  /// Whether the signed-in citizen wrote this comment.
  final bool mine;
  final DateTime? at;

  const PostComment({required this.id, required this.author, required this.body, this.mine = false, this.at});

  factory PostComment.fromApi(Map<String, dynamic> json) => PostComment(
    id: JsonRead.integer(json['id']) ?? 0,
    author: JsonRead.string(json['author']) ?? '',
    body: JsonRead.string(json['body']) ?? '',
    mine: JsonRead.boolean(json['mine']) ?? false,
    at: JsonRead.date(json['created_at']),
  );
}

/// Mirrors an entry from citizen/events.blade.php's $events array.
class EventItem {
  final String title;
  final String date;
  final String time;
  final String venue;
  final String? imagePath;
  final String? category;

  /// The parsed [date], kept so a list can be put in calendar order; null
  /// for the bundled mock events and for an unparseable date.
  final DateTime? startsAt;

  EventItem({
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    this.imagePath,
    this.category,
    this.startsAt,
  });

  /// Upcoming events first (soonest first), then past ones (most recent
  /// first), then undated ones -- the order the server sent was not
  /// guaranteed to be either, and Home's two-item preview showed whichever
  /// rows happened to come back first, past or not.
  static List<EventItem> inCalendarOrder(Iterable<EventItem> events, {DateTime? now}) {
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = dateOnly(now ?? DateTime.now());
    final upcoming = <EventItem>[];
    final past = <EventItem>[];
    final undated = <EventItem>[];
    for (final e in events) {
      final d = e.startsAt;
      if (d == null) {
        undated.add(e);
      } else if (!dateOnly(d).isBefore(today)) {
        upcoming.add(e);
      } else {
        past.add(e);
      }
    }
    upcoming.sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
    past.sort((a, b) => b.startsAt!.compareTo(a.startsAt!));
    return [...upcoming, ...past, ...undated];
  }

  /// GET /events (PublicContentController::events()) -- key/name/title/
  /// date/time/venue/barangay/category/recurrence/timezone. `title` falls
  /// back to `name` exactly like the Web Admin's own citizen/events.blade.php
  /// (`e.title || e.name`) -- that file is the contract for which of the
  /// two is authoritative, not a guess made independently here.
  ///
  /// [imagePath] is always null: the real `events` table has no poster/image
  /// column at all (confirmed against app/Models/Event.php, not assumed),
  /// unlike MockCatalog's own seed events, which bundle real poster artwork
  /// for genuine past municipal events. EventCard already treats it as
  /// optional, so a real event renders as a text-only card rather than
  /// missing its poster silently -- there is no image to fall back to.
  factory EventItem.fromApi(Map<String, dynamic> json) {
    final rawDate = JsonRead.nonEmpty(json['date']);
    final parsed = rawDate != null ? DateTime.tryParse(rawDate) : null;
    return EventItem(
      title: JsonRead.nonEmpty(json['title']) ?? JsonRead.nonEmpty(json['name']) ?? '',
      date: parsed != null ? DateFormat('MMM d, yyyy').format(parsed) : (rawDate ?? ''),
      time: JsonRead.string(json['time']) ?? '',
      venue: JsonRead.string(json['venue']) ?? '',
      category: JsonRead.nonEmpty(json['category']),
      startsAt: parsed,
    );
  }
}

/// A government office entry, mirroring citizen/directory.blade.php.
class DirectoryOffice {
  final String name;
  final String head;
  final String contact;
  final String address;
  final String hours;

  DirectoryOffice({
    required this.name,
    required this.head,
    required this.contact,
    required this.address,
    required this.hours,
  });
}
