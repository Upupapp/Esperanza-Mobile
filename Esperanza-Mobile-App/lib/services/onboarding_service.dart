import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the citizen has ever completed (or skipped) the
/// three-screen first-run welcome flow — a one-time, device-local flag,
/// same SharedPreferences-backed pattern as [CitizenSessionService]'s own
/// persistence, not a ChangeNotifier since nothing needs to react live to
/// it: it's read exactly once at splash time and written exactly once
/// when onboarding finishes.
class OnboardingService {
  OnboardingService._();

  static const _key = 'esperanza_onboarding_complete';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
