import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language of the messages the server sends in both Filipino and
/// English: error messages and notifications (live test 2026-10-07, UX-15).
/// The app's screens are in English, and those messages arrived in
/// Filipino beside them; English is the default so the two match, and
/// Settings offers Filipino. Kept on this device.
class MessageLanguage {
  MessageLanguage._();

  static const _key = 'esperanza_message_language';

  /// true when messages are shown in Filipino.
  static final ValueNotifier<bool> filipino = ValueNotifier<bool>(false);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      filipino.value = prefs.getString(_key) == 'fil';
    } catch (_) {
      // Unreadable storage: English, the default.
    }
  }

  static Future<void> set({required bool filipino}) async {
    MessageLanguage.filipino.value = filipino;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, filipino ? 'fil' : 'en');
    } catch (_) {
      // Holds for this session; the next start falls back to English.
    }
  }

  /// One of a `{fil, en}` pair, in the chosen language, else the other.
  static String? pick({String? fil, String? en}) {
    final first = filipino.value ? fil : en;
    final second = filipino.value ? en : fil;
    return (first != null && first.trim().isNotEmpty) ? first : second;
  }
}
