import 'package:shared_preferences/shared_preferences.dart';

/// Which promotional posters this phone has already shown. Each section's
/// full-screen poster used to open on every app start, so a resident closed
/// a pop-up before every section they visited (QA run 2026-10-04, M12a). Now
/// each poster shows once per phone; a new poster (another asset) shows again.
class BannerMemory {
  BannerMemory._();

  static const _prefix = 'banner_seen.';

  /// Runs [show] unless [assetPath] was shown before, and remembers it. With
  /// no storage (a test without a mock) it shows, as it always did.
  static Future<void> showOnce(String assetPath, void Function() show) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('$_prefix$assetPath') ?? false) return;
      await prefs.setBool('$_prefix$assetPath', true);
    } catch (_) {
      // Shown, and not remembered.
    }
    show();
  }
}
