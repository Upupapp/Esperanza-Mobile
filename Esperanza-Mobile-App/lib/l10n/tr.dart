import '../services/message_language.dart';
import 'filipino_text.dart';

/// A phrase of the app's own, in the language chosen in Settings (or the
/// LGU's default until one is chosen). The Filipino is the website's own
/// wording (tool/l10n/build_filipino.py); a phrase the website has no
/// Filipino for stays English (owner, 2026-10-23).
///
/// Write the English as the literal, `tr('Request a Document')`, so the
/// tool can find it; run the tool after adding one.
String tr(String english) {
  if (!MessageLanguage.filipino.value) return english;
  return filipinoText[english] ?? english;
}
