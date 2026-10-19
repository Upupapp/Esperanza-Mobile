import '../services/json_read.dart';

/// Photo or video.
enum BalitaMediaKind { image, video }

/// One photo or video of a Balita post (esperanza-backend 2026-10-18,
/// BalitaMediaService::row): up to ten per post, in the order the writer
/// arranged them. [url] is a signed link the server keeps the same within the
/// hour; it is null while the file is still being checked.
class BalitaMedia {
  final int id;
  final BalitaMediaKind kind;
  final String? url;

  /// A still of a video, when the writer's browser could take one.
  final String? posterUrl;
  final int? width;
  final int? height;
  final int? durationMs;

  const BalitaMedia({
    required this.id,
    required this.kind,
    this.url,
    this.posterUrl,
    this.width,
    this.height,
    this.durationMs,
  });

  bool get isVideo => kind == BalitaMediaKind.video;

  /// Width over height, when the server knows both; null otherwise.
  double? get aspectRatio {
    final w = width, h = height;
    return w != null && h != null && w > 0 && h > 0 ? w / h : null;
  }

  /// "0:45" / "1:02:03".
  String? get durationLabel {
    final ms = durationMs;
    if (ms == null) return null;
    final total = (ms / 1000).round();
    final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  }

  factory BalitaMedia.fromApi(Map<String, dynamic> json) {
    final id = JsonRead.integer(json['id']);
    if (id == null) throw const FormatException('media without an id');
    return BalitaMedia(
      id: id,
      kind: JsonRead.string(json['kind']) == 'video' ? BalitaMediaKind.video : BalitaMediaKind.image,
      url: JsonRead.mediaUrl(json['url']),
      posterUrl: JsonRead.mediaUrl(json['poster_url']),
      width: JsonRead.integer(json['width']),
      height: JsonRead.integer(json['height']),
      durationMs: JsonRead.integer(json['duration_ms']),
    );
  }

  /// A post's `media`, or, from a server older than 2026-10-18 that sends
  /// only `image_url`, that one photo.
  static List<BalitaMedia> listFrom(Map<String, dynamic> json, String? imageUrl) {
    final raw = json['media'];
    if (raw is List) {
      final rows = <BalitaMedia>[];
      for (final r in raw) {
        if (r is! Map<String, dynamic>) continue;
        try {
          rows.add(BalitaMedia.fromApi(r));
        } on FormatException {
          // One unreadable row does not hide the rest.
        }
      }
      if (rows.isNotEmpty || imageUrl == null) return rows;
    }
    return imageUrl == null ? const [] : [BalitaMedia(id: -1, kind: BalitaMediaKind.image, url: imageUrl)];
  }
}
