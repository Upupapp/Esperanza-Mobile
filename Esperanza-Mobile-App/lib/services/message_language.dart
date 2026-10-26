import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'json_read.dart';

/// The app's language: its own screens (tr(), in the website's wording) and
/// the messages the server sends in both Filipino and English, error
/// messages and notifications alike.
///
/// As on the website (app.js `lang` store): the resident's own choice in
/// Settings, kept on this device; until they make one, the LGU's Default
/// Language (GET /portal-settings `default_language`), which is not stored
/// as a choice so a later change by the LGU still applies (owner,
/// 2026-10-23; before, English always).
class MessageLanguage {
  MessageLanguage._();

  static const _key = 'esperanza_message_language';

  /// The LGU's default as last read, so the next start opens in it before
  /// the server answers. Not the resident's choice.
  static const _serverKey = 'esperanza_server_default_language';

  /// true when the app is shown in Filipino.
  static final ValueNotifier<bool> filipino = ValueNotifier<bool>(false);

  /// The resident chose a language in Settings.
  static bool _chosen = false;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chosen = prefs.getString(_key);
      _chosen = chosen == 'fil' || chosen == 'en';
      filipino.value = (chosen ?? prefs.getString(_serverKey)) == 'fil';
    } catch (_) {
      // Unreadable storage: English until the server says otherwise.
    }
  }

  /// Reads the LGU's Default Language and follows it while the resident has
  /// not chosen one. Offline or an older server: nothing changes.
  static Future<void> followServerDefault() async {
    try {
      final result = await api.get('/portal-settings');
      await applyServerDefault(JsonRead.nonEmpty(result.map['default_language']));
    } on ApiException {
      // Keeps the language it opened in.
    }
  }

  static Future<void> applyServerDefault(String? language) async {
    if (language != 'fil' && language != 'en') return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverKey, language!);
    } catch (_) {
      // Applies for this session.
    }
    if (!_chosen) filipino.value = language == 'fil';
  }

  static Future<void> set({required bool filipino}) async {
    _chosen = true;
    MessageLanguage.filipino.value = filipino;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, filipino ? 'fil' : 'en');
    } catch (_) {
      // Holds for this session; the next start falls back to the default.
    }
  }

  /// One of a `{fil, en}` pair, in the chosen language, else the other.
  static String? pick({String? fil, String? en}) {
    final first = filipino.value ? fil : en;
    final second = filipino.value ? en : fil;
    return (first != null && first.trim().isNotEmpty) ? first : second;
  }
}
