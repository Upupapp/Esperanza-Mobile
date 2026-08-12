import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/access_level.dart';
import '../models/citizen_account.dart';
import '../theme/app_status.dart';

/// Frontend-only session simulation — the mobile equivalent of the Web
/// Admin's `Alpine.store('citizenSession')` in resources/js/app.js. No real
/// backend call is made; the signed-in account is just persisted locally
/// via SharedPreferences (the mobile analogue of the Web Admin's
/// localStorage-based session). Registration here creates a local
/// CitizenAccount the same shape a real backend's `residents` table would
/// need — see ESPERANZA_MOBILE_WEB_ALIGNMENT.md Section 8.
///
/// This is also the single source of truth for [accessLevel] — the only
/// place in the app that decides Guest vs Authenticated/unverified vs
/// Verified, so individual screens never need to re-derive that logic
/// themselves (see widgets/access_guard.dart).
class CitizenSessionService extends ChangeNotifier {
  static const _key = 'esperanza_citizen_session';
  static const _guestKey = 'esperanza_guest_mode';

  CitizenAccount? _account;
  bool _loading = true;
  bool _isGuest = false;

  CitizenAccount? get account => _account;
  bool get isSignedIn => _account != null;
  bool get isGuest => _isGuest;
  bool get loading => _loading;

  /// Guest (not signed in, browsing public content) < Authenticated but
  /// unverified (has an account, `status` isn't yet 'Approved') <
  /// Verified (`status == 'Approved'`) — reuses the same universal status
  /// vocabulary as service requests (see theme/app_status.dart) rather
  /// than inventing a parallel one.
  AccessLevel get accessLevel {
    final acc = _account;
    if (acc == null) return AccessLevel.guest;
    return AppStatusX.fromLabel(acc.status) == AppStatus.approved ? AccessLevel.verified : AccessLevel.unverified;
  }

  CitizenSessionService() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _account = CitizenAccount.fromJson(jsonDecode(raw));
    } else {
      _isGuest = prefs.getBool(_guestKey) ?? false;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(CitizenAccount account) async {
    _account = account;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(account.toJson()));
    await prefs.remove(_guestKey);
    notifyListeners();
  }

  /// Section 5/6 — enters the app without an account. Guests get Home +
  /// public Balita only; everything else routes through [AccessGuard].
  Future<void> continueAsGuest() async {
    _account = null;
    _isGuest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.setBool(_guestKey, true);
    notifyListeners();
  }

  /// Ends a guest session so Sign In / Create Account start from a clean
  /// slate — called from RestrictedFeatureNotice before navigating away.
  Future<void> endGuestSession() async {
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
    notifyListeners();
  }

  Future<void> logout() async {
    _account = null;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_guestKey);
    notifyListeners();
  }

  Future<void> updateProfile(CitizenAccount updated) async {
    _account = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(updated.toJson()));
    notifyListeners();
  }
}
