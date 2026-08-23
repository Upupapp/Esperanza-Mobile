/// Mirrors one post from config/esperanza_balita.php ('Balita' = news in
/// Filipino) as consumed by citizen/announcements.blade.php and the
/// dashboard's Balita preview. Likes/comments/shares/new posts are a pure
/// frontend simulation persisted via BalitaService (SharedPreferences,
/// same pattern as RequestsService) — there is no backend for the social
/// feed, and [toJson]/[fromJson] exist only to support that local
/// persistence, never a network call.
class Announcement {
  final String id;
  final String official; // e.g. "Esperanza LGU" — empty if a personal/resident post
  final String author;
  final String? barangay;
  final String body;
  final String time;
  final PostMedia? media;
  int likes;
  bool liked;
  int shares;
  int viewCount;
  final List<PostComment> comments;

  Announcement({
    required this.id,
    required this.official,
    required this.author,
    this.barangay,
    required this.body,
    required this.time,
    this.media,
    required this.likes,
    this.liked = false,
    this.shares = 0,
    this.viewCount = 0,
    List<PostComment>? comments,
    // Copied rather than assigned directly: several seed posts in
    // MockCatalog pass `comments: const []` (or a `const [PostComment(...)]`
    // literal) for a clean declaration, but a const list is immutable at
    // runtime — BalitaService.addComment's `post.comments.add(...)` would
    // throw "Cannot add to an unmodifiable list" the moment someone tried
    // to leave the very first comment on one of those posts. A growable
    // copy here means the constructor's own contract (comments can always
    // be appended to) holds regardless of how a caller constructed the
    // list it passed in.
  }) : comments = comments != null ? List.of(comments) : [];

  bool get isOfficial => official.isNotEmpty;
  int get commentCount => comments.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'official': official,
        'author': author,
        'barangay': barangay,
        'body': body,
        'time': time,
        'media': media?.toJson(),
        'likes': likes,
        'liked': liked,
        'shares': shares,
        'viewCount': viewCount,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'],
        official: json['official'],
        author: json['author'],
        barangay: json['barangay'],
        body: json['body'],
        time: json['time'],
        media: json['media'] != null ? PostMedia.fromJson(json['media']) : null,
        likes: json['likes'],
        liked: json['liked'] ?? false,
        shares: json['shares'] ?? 0,
        viewCount: json['viewCount'] ?? 0,
        comments: (json['comments'] as List? ?? []).map((c) => PostComment.fromJson(c)).toList(),
      );
}

/// A single mock comment on a Balita post, added either from seed data or
/// locally by the signed-in citizen via the Comments sheet.
class PostComment {
  final String author;
  final String body;
  final String time;

  PostComment({required this.author, required this.body, this.time = 'Just now'});

  Map<String, dynamic> toJson() => {'author': author, 'body': body, 'time': time};

  factory PostComment.fromJson(Map<String, dynamic> json) =>
      PostComment(author: json['author'], body: json['body'], time: json['time'] ?? 'Just now');
}

enum PostMediaType { image, video }

/// A single media attachment on a Balita post — either a bundled seed
/// asset (`isAsset: true`, used only by MockCatalog's sample posts) or a
/// real file the citizen picked on-device via image_picker (`isAsset:
/// false`, `path` is a local filesystem path). Never a remote URL: there
/// is no upload/backend for Balita, by design — this is local-only
/// simulation, same as `Attachment.localPath` for document requests.
class PostMedia {
  final String path;
  final PostMediaType type;
  final bool isAsset;
  final String? fileName;

  const PostMedia({
    required this.path,
    required this.type,
    this.isAsset = false,
    this.fileName,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'type': type.name,
        'isAsset': isAsset,
        'fileName': fileName,
      };

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
        path: json['path'],
        type: PostMediaType.values.firstWhere((t) => t.name == json['type']),
        isAsset: json['isAsset'] ?? false,
        fileName: json['fileName'],
      );
}

/// Mirrors an entry from citizen/events.blade.php's $events array, plus
/// an optional poster [imagePath]/[category] the Web Admin would attach
/// when publishing a real event — each event is its own independent
/// entry/card even when several share a venue or general topic (e.g. a
/// basketball tournament's separate match-day posters), never merged
/// into one combined container.
class EventItem {
  final String title;
  final String date;
  final String time;
  final String venue;
  final String? imagePath;
  final String? category;

  EventItem({
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    this.imagePath,
    this.category,
  });
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
