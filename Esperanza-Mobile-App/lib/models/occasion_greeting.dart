import '../services/json_read.dart';

/// The kind of occasion a pop-up greets residents for: a birthday, a
/// barangay or municipal fiesta, a national holiday, an LGU event, or a
/// custom one (2026-10-21). The kinds and their names in both languages come
/// from the server (`type`, `type_label`), never typed here.
class GreetingOccasion {
  final String key;
  final String? en;
  final String? fil;

  /// A custom occasion's own name ("Pista ng Barangay Baras"), as an older
  /// server sent it.
  final String? name;

  const GreetingOccasion({required this.key, this.en, this.fil, this.name});

  /// What to call it, in the resident's language; null when the server named
  /// it in neither (a custom occasion with no label).
  String? label({required bool filipino}) => name ?? (filipino ? fil ?? en : en ?? fil);

  /// From a pop-up: `type` and `type_label` (2026-10-21), or the
  /// `occasion` fields a server from before then sent.
  static GreetingOccasion? fromApi(Object? raw) {
    final json = JsonRead.map(raw) ?? const <String, dynamic>{};
    final type = JsonRead.nonEmpty(json['type']);
    final key = type ?? JsonRead.nonEmpty(json['occasion']);
    if (key == null) return null;
    final label =
        JsonRead.map(type != null ? json['type_label'] : json['occasion_label']) ??
        JsonRead.map(json['occasion_label']) ??
        const <String, dynamic>{};
    return GreetingOccasion(
      key: key,
      en: JsonRead.nonEmpty(label['en']),
      fil: JsonRead.nonEmpty(label['fil']),
      // A server since 2026-10-21 names the kind (Pista ng Barangay), as the
      // website shows it; the occasion's own name is the staff's working
      // title. Only an older server's custom greeting is called by its name.
      name: type == null ? JsonRead.nonEmpty(json['occasion_name']) : null,
    );
  }
}

/// An occasion pop-up, as GET /citizen/popups/active sends it (2026-10-21).
/// The server has already decided it is for this resident now: its audience
/// (barangay, senior citizens, sectors), its window, how often it may show,
/// whether it was put away - and, for a birthday pop-up, that today is the
/// resident's birthday.
class OccasionGreeting {
  final int id;
  final String title;
  final String message;
  final GreetingOccasion? occasion;

  /// The picture, whole; null shows the design's own art.
  final String? imageUrl;

  /// What a screen reader says for [imageUrl].
  final String imageAlt;

  /// The resident's birthday greeting: drawn in the birthday design.
  final bool birthday;

  /// Whether it offers "Huwag nang ipakita" (don't show this one again).
  final bool dismissible;

  /// The pop-up's post while it is in Balita: "Tingnan sa Balita".
  final int? postId;

  /// The officer's own button: a label, and an https link it opens.
  final String? buttonLabel;
  final String? buttonUrl;

  const OccasionGreeting({
    required this.id,
    required this.title,
    required this.message,
    this.occasion,
    this.imageUrl,
    String? imageAlt,
    this.birthday = false,
    this.dismissible = false,
    this.postId,
    this.buttonLabel,
    this.buttonUrl,
  }) : imageAlt = imageAlt ?? title;

  factory OccasionGreeting.fromApi(Map<String, dynamic> json) {
    final id = JsonRead.integer(json['id']);
    final title = JsonRead.nonEmpty(json['title']);
    if (id == null || title == null) throw const FormatException('pop-up without an id or a title');
    final button = JsonRead.map(json['button']) ?? const <String, dynamic>{};
    final url = JsonRead.nonEmpty(button['url']);
    final occasion = GreetingOccasion.fromApi(json);
    return OccasionGreeting(
      id: id,
      title: title,
      message: JsonRead.string(json['message']) ?? '',
      occasion: occasion,
      // `poster_url` is what a server from before 2026-10-21 sent.
      imageUrl: JsonRead.mediaUrl(json['image_url']) ?? JsonRead.mediaUrl(json['poster_url']),
      imageAlt: JsonRead.nonEmpty(json['image_alt']),
      birthday: JsonRead.boolean(json['birthday']) ?? occasion?.key == 'birthday',
      dismissible: JsonRead.boolean(json['dismissible']) ?? false,
      postId: JsonRead.integer(json['post_id']),
      buttonLabel: JsonRead.nonEmpty(button['label']),
      // Only a web link is ever opened from a pop-up.
      buttonUrl: url != null && url.startsWith('https://') ? url : null,
    );
  }
}
