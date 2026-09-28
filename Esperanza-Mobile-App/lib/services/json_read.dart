import 'api_client.dart';

/// Tolerant readers for API payloads.
///
/// Every parser in this app used to read fields with hard casts
/// (`json['id'] as int`, `json['likes'] as int?`). A hard cast throws a
/// `TypeError` the moment the backend serialises a value in a different but
/// equally valid JSON shape -- an id as `"12"`, a count as `3.0`, a flag as
/// `1` -- and a `TypeError` is not an [ApiException], so the screens that only
/// catch [ApiException] let it escape and the whole list failed with a generic
/// "Something went wrong". These readers coerce the shapes a Laravel JSON
/// resource realistically produces and return null for anything else, so the
/// caller's own `??` default decides what a missing value means.
class JsonRead {
  JsonRead._();

  static String? string(Object? v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    return null;
  }

  /// A string with surrounding whitespace removed, or null when that leaves
  /// nothing -- for fields where `""` and absent mean the same thing.
  static String? nonEmpty(Object? v) {
    final s = string(v)?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static int? integer(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.toInt();
    return null;
  }

  static bool? boolean(Object? v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      switch (v.trim().toLowerCase()) {
        case 'true' || '1' || 'yes':
          return true;
        case 'false' || '0' || 'no':
          return false;
      }
    }
    return null;
  }

  static DateTime? date(Object? v) {
    final s = string(v);
    return s == null ? null : DateTime.tryParse(s);
  }

  static Map<String, dynamic>? map(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, value) => MapEntry(k.toString(), value));
    return null;
  }

  static List<dynamic> list(Object? v) => v is List ? v : const [];

  static List<String> strings(Object? v) => list(v).map(string).whereType<String>().toList();

  /// Parses every row of [raw] with [parse], skipping any row that is not an
  /// object or that [parse] cannot read, instead of failing the whole list.
  /// One malformed announcement must never hide the other forty-nine.
  static List<T> rows<T>(Object? raw, T? Function(Map<String, dynamic> row) parse) {
    final out = <T>[];
    for (final item in list(raw)) {
      final row = map(item);
      if (row == null) continue;
      try {
        final parsed = parse(row);
        if (parsed != null) out.add(parsed);
      } catch (_) {
        // Skipped, see above.
      }
    }
    return out;
  }

  /// Media paths come back either absolute (`https://…/storage/x.jpg`) or
  /// relative to the API host (`/storage/x.jpg`, `storage/x.jpg`). A relative
  /// one handed straight to `Image.network` fails to load, so it is resolved
  /// against the origin of the active client's base URL (never its `/api/v1`
  /// path), so it follows `--dart-define=API_BASE_URL` like every request.
  static String? mediaUrl(Object? v, {String? baseUrl}) {
    final s = nonEmpty(v);
    if (s == null) return null;
    final parsed = Uri.tryParse(s);
    if (parsed == null) return null;
    if (parsed.hasScheme) return s;
    final base = Uri.tryParse(baseUrl ?? api.baseUrl);
    if (base == null || !base.hasScheme) return s;
    if (s.startsWith('//')) return '${base.scheme}:$s';
    final origin = '${base.scheme}://${base.authority}';
    return s.startsWith('/') ? '$origin$s' : '$origin/$s';
  }
}
