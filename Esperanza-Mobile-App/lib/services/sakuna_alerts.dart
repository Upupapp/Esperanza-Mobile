import 'api_client.dart';
import 'json_read.dart';
import 'message_language.dart';

/// One published emergency alert, as the public `GET /alerts` feed returns it
/// (esperanza-backend AlertService::publicFeed(): released, not cancelled,
/// newest first).
class PublicAlert {
  const PublicAlert({
    required this.ref,
    required this.type,
    required this.level,
    required this.title,
    required this.body,
    required this.barangays,
    required this.publishedAt,
    this.expiresAt,
  });

  final String ref;
  final String? type;
  final String? level;
  final String title;
  final String body;

  /// Empty when the alert is for the whole municipality.
  final List<String> barangays;
  final DateTime? publishedAt;

  /// When the office set it to end by itself; null while it has no end.
  final DateTime? expiresAt;

  /// The alert level in the chosen language (the staff Alerts tab's levels).
  String? get levelLabel {
    final l = level;
    if (l == null || !MessageLanguage.filipino.value) return l;
    return const {
      'Information': 'Impormasyon',
      'Advisory': 'Abiso',
      'Watch': 'Pagbabantay',
      'Warning': 'Babala',
      'Critical': 'Kritikal',
    }[l] ?? l;
  }

  /// Bilingual on the wire (`{fil, en}`): in the language chosen in
  /// Settings, as the website shows it (it used to be Filipino first always).
  static String _text(Object? v) {
    final m = JsonRead.map(v);
    if (m != null) return MessageLanguage.pick(fil: JsonRead.nonEmpty(m['fil']), en: JsonRead.nonEmpty(m['en'])) ?? '';
    return JsonRead.string(v) ?? '';
  }

  static PublicAlert? fromJson(Map<String, dynamic> row) {
    final ref = JsonRead.nonEmpty(row['ref']);
    final title = _text(row['title']);
    if (ref == null || title.isEmpty) return null;
    return PublicAlert(
      ref: ref,
      type: JsonRead.nonEmpty(row['type']),
      level: JsonRead.nonEmpty(row['level']),
      title: title,
      body: _text(row['body']),
      barangays: JsonRead.strings(row['barangays']),
      publishedAt: JsonRead.date(row['published_at'])?.toLocal(),
      expiresAt: JsonRead.date(row['expires_at'])?.toLocal(),
    );
  }
}

class SakunaAlerts {
  SakunaAlerts._();

  /// The alerts in force for [barangay] (municipality-wide ones included), or
  /// every alert when no barangay is known (a guest). Public: an alert must
  /// not wait for a sign-in.
  static Future<List<PublicAlert>> load({String? barangay}) async {
    final res = await api.get('/alerts', query: {if (barangay != null && barangay.isNotEmpty) 'barangay': barangay});
    return JsonRead.rows(res.list, PublicAlert.fromJson);
  }
}
