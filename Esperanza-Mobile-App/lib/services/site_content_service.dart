import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../content/privacy_policy_v1.dart';
import 'api_client.dart';
import 'json_read.dart';

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
  static PublishedDocument? fromJson(Map<String, dynamic> json, ContentSource source) {
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
      title: JsonRead.nonEmpty(json['title']) ?? 'Privacy Policy',
      effectiveDate: JsonRead.date(json['effective_date']),
      intro: JsonRead.nonEmpty(json['intro']),
      sections: sections,
      source: source,
    );
  }
}

class SiteContentService {
  SiteContentService._();

  static const _savedKey = 'esperanza_site_content_privacy';

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

  static Future<void> _save(Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedKey, jsonEncode(json));
    } catch (_) {
      // Saving is a convenience; the live copy is already on screen.
    }
  }

  static Future<PublishedDocument?> _saved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_savedKey);
      if (raw == null) return null;
      final json = JsonRead.map(jsonDecode(raw));
      return json == null ? null : PublishedDocument.fromJson(json, ContentSource.saved);
    } catch (_) {
      return null;
    }
  }
}
