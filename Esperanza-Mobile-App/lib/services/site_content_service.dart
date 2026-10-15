import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../content/privacy_policy_v1.dart';
import 'api_client.dart';
import 'json_read.dart';
import 'message_language.dart';

/// Where a [PublishedDocument] on screen came from.
enum ContentSource {
  /// Just loaded from the server: what the Municipality publishes today.
  live,

  /// The copy saved on this phone the last time it loaded.
  saved,

  /// The published version 1 that ships inside the app.
  bundled,
}

class PublishedSection {
  const PublishedSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// One document the Municipality publishes from the Web Admin (Settings >
/// Site Content), as `GET /site-content/{docKey}` returns it
/// (esperanza-backend PublicContentController::siteContent()).
class PublishedDocument {
  const PublishedDocument({
    required this.version,
    required this.title,
    required this.effectiveDate,
    required this.intro,
    required this.sections,
    required this.source,
  });

  final int? version;
  final String title;
  final DateTime? effectiveDate;
  final String? intro;
  final List<PublishedSection> sections;
  final ContentSource source;

  /// Null when the payload has no sections at all: an empty policy is not a
  /// policy, so the caller keeps whatever it already has.
  static PublishedDocument? fromJson(Map<String, dynamic> json, ContentSource source, {String fallbackTitle = 'Privacy Policy'}) {
    final sections = <PublishedSection>[];
    for (final raw in JsonRead.list(json['sections'])) {
      final row = JsonRead.map(raw);
      if (row == null) continue;
      final heading = JsonRead.nonEmpty(row['heading']) ?? JsonRead.nonEmpty(row['title']);
      final body = JsonRead.nonEmpty(row['body']) ?? JsonRead.nonEmpty(row['content']);
      if (heading == null && body == null) continue;
      sections.add(PublishedSection(heading ?? '', body ?? ''));
    }
    if (sections.isEmpty) return null;
    return PublishedDocument(
      version: JsonRead.integer(json['version']),
      title: JsonRead.nonEmpty(json['title']) ?? fallbackTitle,
      effectiveDate: JsonRead.date(json['effective_date']),
      intro: JsonRead.nonEmpty(json['intro']),
      sections: sections,
      source: source,
    );
  }
}

/// One question from the LGU's published FAQs (`/site-content/faqs`), in
/// the language chosen in Settings when the LGU wrote both.
class HelpFaq {
  final String question;
  final String answer;
  final String? category;

  /// The question as the LGU wrote it in English: the key "Was this
  /// helpful?" answers are counted under, the same one the website sends.
  final String key;
  const HelpFaq({required this.question, required this.answer, this.category, required this.key});

  static HelpFaq? fromJson(Map<String, dynamic> row) {
    final q = MessageLanguage.pick(fil: JsonRead.nonEmpty(row['q_fil']), en: JsonRead.nonEmpty(row['q']));
    final a = MessageLanguage.pick(fil: JsonRead.nonEmpty(row['a_fil']), en: JsonRead.nonEmpty(row['a']));
    if (q == null || a == null) return null;
    return HelpFaq(
      question: q,
      answer: a,
      category: JsonRead.nonEmpty(row['category']),
      key: JsonRead.nonEmpty(row['q']) ?? q,
    );
  }
}

/// A way to reach the LGU's support team (`/site-content/support` channels).
class SupportChannel {
  final String key;
  final String label;
  final String value;
  const SupportChannel({required this.key, required this.label, required this.value});

  static SupportChannel? fromJson(Map<String, dynamic> row) {
    final label = MessageLanguage.pick(fil: JsonRead.nonEmpty(row['label_fil']), en: JsonRead.nonEmpty(row['label']));
    final value = JsonRead.nonEmpty(row['value']);
    if (label == null || value == null) return null;
    return SupportChannel(key: JsonRead.nonEmpty(row['key']) ?? '', label: label, value: value);
  }
}

/// A video tutorial. Only one with a link is shown, as on the web portal,
/// which hides the tab while none has a video.
class HelpTutorial {
  final String title;
  final String videoUrl;
  final String? duration;
  const HelpTutorial({required this.title, required this.videoUrl, this.duration});

  static HelpTutorial? fromJson(Map<String, dynamic> row) {
    final title = JsonRead.nonEmpty(row['title']);
    final url = JsonRead.nonEmpty(row['video_url']);
    if (title == null || url == null) return null;
    return HelpTutorial(title: title, videoUrl: url, duration: JsonRead.nonEmpty(row['duration']));
  }
}

/// What the web portal's Help page shows from the LGU: its FAQs, tutorials,
/// support channels and office hours. Each part is empty when it could not
/// be loaded; the app's own help still shows.
class HelpContent {
  final List<HelpFaq> faqs;
  final List<HelpTutorial> tutorials;
  final List<SupportChannel> channels;
  final String? officeHours;
  final String? intro;
  const HelpContent({
    this.faqs = const [],
    this.tutorials = const [],
    this.channels = const [],
    this.officeHours,
    this.intro,
  });

  bool get isEmpty => faqs.isEmpty && tutorials.isEmpty && channels.isEmpty && officeHours == null;
}

class SiteContentService {
  SiteContentService._();

  static const _savedKey = 'esperanza_site_content_privacy';
  static const _savedTermsKey = 'esperanza_site_content_terms';

  /// Shown at once, before anything loads, so the policy is never a spinner.
  static PublishedDocument get bundledPrivacyPolicyDocument =>
      PublishedDocument.fromJson(Map<String, dynamic>.from(bundledPrivacyPolicy), ContentSource.bundled)!;

  /// The Privacy Policy the Municipality publishes. Falls back to the copy
  /// saved on the last successful load, then to the bundled version 1: a
  /// citizen offline can always read it, and it never shows a placeholder.
  static Future<PublishedDocument> privacyPolicy() async {
    try {
      final res = await api.get('/site-content/privacy');
      final live = PublishedDocument.fromJson(res.map, ContentSource.live);
      if (live != null) {
        await _save(res.map);
        return live;
      }
    } on ApiException {
      // Offline, or nothing published yet (404): fall through.
    }
    return await _saved() ?? bundledPrivacyPolicyDocument;
  }

  /// The Terms and Conditions the Municipality publishes (the web portal's
  /// /citizen/legal/terms), else the copy saved on the last load. Null when
  /// neither exists: offline on first use.
  static Future<PublishedDocument?> terms() async {
    try {
      final res = await api.get('/site-content/terms');
      final live = PublishedDocument.fromJson(res.map, ContentSource.live, fallbackTitle: 'Terms and Conditions');
      if (live != null) {
        await _save(res.map, key: _savedTermsKey);
        return live;
      }
    } on ApiException {
      // Offline, or nothing published yet: fall through.
    }
    return _saved(key: _savedTermsKey, fallbackTitle: 'Terms and Conditions');
  }

  /// FAQs, tutorials and support channels, read together as the web
  /// portal's Help page does. A part that fails is left empty.
  static Future<HelpContent> help() async {
    Future<Map<String, dynamic>> read(String key) async {
      try {
        return (await api.get('/site-content/$key')).map;
      } on ApiException {
        return const {};
      }
    }

    final parts = await Future.wait([read('faqs'), read('tutorials'), read('support')]);
    final support = parts[2];
    return HelpContent(
      faqs: JsonRead.rows(parts[0]['sections'], HelpFaq.fromJson),
      tutorials: JsonRead.rows(parts[1]['sections'], HelpTutorial.fromJson),
      channels: JsonRead.rows(support['channels'], SupportChannel.fromJson),
      officeHours: MessageLanguage.pick(
        fil: JsonRead.nonEmpty(support['office_hours_fil']),
        en: JsonRead.nonEmpty(support['office_hours']),
      ),
      intro: JsonRead.nonEmpty(support['intro']),
    );
  }

  static Future<void> _save(Map<String, dynamic> json, {String key = _savedKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(json));
    } catch (_) {
      // Saving is a convenience; the live copy is already on screen.
    }
  }

  static Future<PublishedDocument?> _saved({String key = _savedKey, String fallbackTitle = 'Privacy Policy'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final json = JsonRead.map(jsonDecode(raw));
      return json == null ? null : PublishedDocument.fromJson(json, ContentSource.saved, fallbackTitle: fallbackTitle);
    } catch (_) {
      return null;
    }
  }
}
