import 'package:intl/intl.dart';
import '../services/json_read.dart';
import '../utils/date_text.dart';
import 'balita_media.dart';

/// One Balita feed item — an announcement the LGU published (GET
/// /announcements, real since the production-readiness programme,
/// 2026-09-25). Only the LGU posts to Balita (owner, 2026-10-20); residents'
/// community posts are gone. [id] keeps its 'ann-5' form, the key the feed
/// and the viewer find a post by; [remoteId] is the real numeric id the
/// like and comment endpoints need.
class Announcement {
  final String id;
  final int remoteId;
  final String author;
  final String? barangay;
  final String? category;
  final String body;

  /// Announcements only: the headline. [body] still leads with it (see
  /// [_withTitle]), so anything that shares or searches the body keeps it;
  /// the feed card uses this to draw it as a headline instead of as one more
  /// line of body text.
  final String? title;

  /// The first photo, for the screens that show one (Home's preview); the
  /// post's photos and videos are [media].
  final String? imageUrl;

  /// Every photo and video, in order (2026-10-18): up to ten.
  final List<BalitaMedia> media;

  /// The event this post was made from, when it was (2026-10-21): the card
  /// shows its day, time and place and opens it.
  final PostEvent? event;

  final DateTime? at;
  int likes;

  /// Whether the signed-in citizen has already liked this post.
  ///
  /// GET /announcements is public; given the citizen's token it says which
  /// posts they liked (see [Announcement.fromAnnouncementApi]). Null only
  /// for a post built without that answer, which shows as not liked and
  /// stays correct for the rest of the session the moment the citizen
  /// toggles it.
  bool? likedByMe;

  int commentsCount;

  /// Real, but never incremented by a citizen action — there is no
  /// POST .../share endpoint anywhere in the backend. Balita's own Share
  /// button still works (the OS share sheet is a real action even without
  /// a server-side counter), it just never changes this number.
  final int shares;

  Announcement({
    required this.id,
    required this.remoteId,
    required this.author,
    this.barangay,
    this.category,
    required this.body,
    this.title,
    this.imageUrl,
    this.media = const [],
    this.event,
    this.at,
    required this.likes,
    this.likedByMe,
    required this.commentsCount,
    this.shares = 0,
  });

  /// "Just now" / "12 mins ago" / "3 hrs ago" / an absolute date beyond a
  /// day old — same thresholds as the Web Admin's own `fmtTime`.
  String get timeLabel {
    final when = at;
    return when == null ? '' : timeAgo(when);
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
      author: JsonRead.nonEmpty(json['author']) ?? 'Esperanza LGU',
      barangay: JsonRead.nonEmpty(json['barangay']),
      category: JsonRead.nonEmpty(json['category']),
      body: _withTitle(JsonRead.nonEmpty(json['title']), JsonRead.string(json['body']) ?? ''),
      title: JsonRead.nonEmpty(json['title']),
      imageUrl: JsonRead.mediaUrl(json['image_url']),
      media: BalitaMedia.listFrom(json, JsonRead.mediaUrl(json['image_url'])),
      // `post_type` and `greeting` are gone (2026-10-21): occasion pop-ups
      // are their own feature, and every post reads as a post.
      event: PostEvent.fromApi(json['event']),
      at: JsonRead.date(json['published_at']) ?? JsonRead.date(json['created_at']),
      likes: JsonRead.integer(json['likes']) ?? 0,
      // GET /announcements is public, but given the citizen's bearer token
      // (ApiClient sends it on every request) it says which announcements
      // they liked (esperanza-backend, backlog B2). It is null for an
      // anonymous read, which shows as not liked.
      likedByMe: JsonRead.boolean(json['liked_by_me']) ?? false,
      commentsCount: JsonRead.integer(json['comments_count']) ?? 0,
      shares: JsonRead.integer(json['shares']) ?? 0,
    );
  }

  /// Announcements carry a separate `title` (announcementRow()) that the
  /// feed card has no slot for; it leads the body so a headline is never
  /// dropped, unless the body already opens with it.
  static String _withTitle(String? title, String body) {
    if (title == null || body.trimLeft().startsWith(title)) return body;
    return body.isEmpty ? title : '$title\n\n$body';
  }
}

/// The event a Balita post carries (announcementRow() `event`, 2026-10-21):
/// null when the post was not made from one, or the event is no longer on
/// the calendar.
class PostEvent {
  final String key;
  final DateTime? date;
  final String? time;
  final String? venue;

  const PostEvent({required this.key, this.date, this.time, this.venue});

  static PostEvent? fromApi(Object? raw) {
    final json = JsonRead.map(raw);
    final key = json == null ? null : JsonRead.nonEmpty(json['key']);
    if (json == null || key == null) return null;
    final rawDate = JsonRead.nonEmpty(json['date']);
    return PostEvent(
      key: key,
      date: rawDate != null ? DateTime.tryParse(rawDate) : null,
      time: JsonRead.nonEmpty(json['time']),
      venue: JsonRead.nonEmpty(json['venue']),
    );
  }

  /// "Sun, Oct 25 · 2:00 PM · Municipal Plaza".
  String get line => [if (date != null) DateFormat('EEE, MMM d').format(date!), ?time, ?venue].join(' · ');
}

/// One comment on an announcement (GET/POST
/// /citizen/announcements/{id}/comments, commentRow()).
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
  /// The server's key for it: what a reminder and a notification name. Null
  /// for the bundled mock events.
  final String? key;
  final String title;
  final String date;
  final String time;
  final String venue;
  final String? imagePath;

  /// Its first photo from the Web Admin (GET /events `image_url`,
  /// 2026-10-21): the poster of a real event. [imagePath] is the bundled
  /// artwork of the mock events.
  final String? imageUrl;

  /// The Balita post that carries it, while that post is in the feed.
  final int? balitaPostId;
  final String? category;

  /// Set when the event is for one barangay; null when it is municipality-wide
  /// (GET /events `barangay`, validated against the barangays table).
  final String? barangay;

  /// Free text from the Web Admin ("Every Saturday"), when it repeats.
  final String? recurrence;

  /// What happens there, written in the Web Admin (GET /events
  /// `description`, up to 2,000 characters); null for older events.
  final String? description;

  /// The parsed [date], kept so a list can be put in calendar order; null
  /// for the bundled mock events and for an unparseable date.
  final DateTime? startsAt;

  EventItem({
    this.key,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    this.imagePath,
    this.imageUrl,
    this.balitaPostId,
    this.category,
    this.barangay,
    this.recurrence,
    this.description,
    this.startsAt,
  });

  /// Whether its date is before [today] (a date-only comparison, so an
  /// event is upcoming all day on its own date). An undated event is never
  /// past.
  bool isPast(DateTime today) {
    final d = startsAt;
    return d != null && DateTime(d.year, d.month, d.day).isBefore(DateTime(today.year, today.month, today.day));
  }

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
  /// [imagePath] is the bundled artwork of MockCatalog's seed events; a real
  /// event's poster is its first photo, [imageUrl] (2026-10-21). An event
  /// without one renders as the plain panel.
  factory EventItem.fromApi(Map<String, dynamic> json) {
    final rawDate = JsonRead.nonEmpty(json['date']);
    final parsed = rawDate != null ? DateTime.tryParse(rawDate) : null;
    return EventItem(
      key: JsonRead.nonEmpty(json['key']),
      title: JsonRead.nonEmpty(json['title']) ?? JsonRead.nonEmpty(json['name']) ?? '',
      date: parsed != null ? DateFormat('MMM d, yyyy').format(parsed) : (rawDate ?? ''),
      time: JsonRead.string(json['time']) ?? '',
      venue: JsonRead.string(json['venue']) ?? '',
      category: JsonRead.nonEmpty(json['category']),
      barangay: JsonRead.nonEmpty(json['barangay']),
      recurrence: JsonRead.nonEmpty(json['recurrence']),
      description: JsonRead.nonEmpty(json['description']),
      imageUrl: JsonRead.mediaUrl(json['image_url']),
      balitaPostId: JsonRead.integer(json['balita_post_id']),
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
