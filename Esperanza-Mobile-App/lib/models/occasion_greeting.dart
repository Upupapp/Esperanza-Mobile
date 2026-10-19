import '../services/json_read.dart';

/// The occasion an official Balita post greets residents for (2026-10-19): a
/// festival, a holiday, the town's foundation day... The kinds and their
/// names in both languages come from the LGU's list (the web frontend's
/// config/esperanza_balita.php, served by the backend), never typed here.
class GreetingOccasion {
  final String key;
  final String? en;
  final String? fil;

  /// A custom occasion's own name ("Pista ng Barangay Baras").
  final String? name;

  const GreetingOccasion({required this.key, this.en, this.fil, this.name});

  /// What to call it, in the resident's language.
  String label({required bool filipino}) => name ?? (filipino ? fil ?? en : en ?? fil) ?? key;

  static GreetingOccasion? fromApi(Object? raw) {
    final json = JsonRead.map(raw) ?? const <String, dynamic>{};
    final key = JsonRead.nonEmpty(json['occasion']);
    if (key == null) return null;
    final label = JsonRead.map(json['occasion_label']) ?? const <String, dynamic>{};
    return GreetingOccasion(
      key: key,
      en: JsonRead.nonEmpty(label['en']),
      fil: JsonRead.nonEmpty(label['fil']),
      name: JsonRead.nonEmpty(json['occasion_name']),
    );
  }
}

/// An occasion greeting's pop-up, as GET /citizen/greetings/active sends it.
/// The server has already decided it is for this resident now: approved,
/// inside its window, for their barangay or the whole municipality, and
/// allowed by how often it may show.
class OccasionGreeting {
  final int id;
  final String title;
  final String message;
  final GreetingOccasion? occasion;
  final String? posterUrl;

  /// The greeting's post while it is in Balita: "Tingnan sa Balita".
  final int? postId;

  /// The officer's own button: a label, and an https link it opens.
  final String? buttonLabel;
  final String? buttonUrl;

  const OccasionGreeting({
    required this.id,
    required this.title,
    required this.message,
    this.occasion,
    this.posterUrl,
    this.postId,
    this.buttonLabel,
    this.buttonUrl,
  });

  factory OccasionGreeting.fromApi(Map<String, dynamic> json) {
    final id = JsonRead.integer(json['id']);
    final title = JsonRead.nonEmpty(json['title']);
    if (id == null || title == null) throw const FormatException('greeting without an id or a title');
    final button = JsonRead.map(json['button']) ?? const <String, dynamic>{};
    final url = JsonRead.nonEmpty(button['url']);
    return OccasionGreeting(
      id: id,
      title: title,
      message: JsonRead.string(json['message']) ?? '',
      occasion: GreetingOccasion.fromApi(json),
      posterUrl: JsonRead.mediaUrl(json['poster_url']),
      postId: JsonRead.integer(json['post_id']),
      buttonLabel: JsonRead.nonEmpty(button['label']),
      // Only a web link is ever opened from a greeting.
      buttonUrl: url != null && url.startsWith('https://') ? url : null,
    );
  }
}
