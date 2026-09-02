import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/access_level.dart';
import '../models/citizen_account.dart';
import '../theme/app_status.dart';
import 'mock_catalog.dart';
import 'persistence_guard.dart';

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

  /// Restores the signed-in session, or falls back to signed-out.
  ///
  /// Nothing awaits this future, so it must not be allowed to throw: an
  /// escaping error would leave [_loading] true forever and strand `AuthGate`
  /// on its spinner. [_loading] is therefore cleared in a `finally`, on every
  /// path including one nobody predicted. Falling back to the sign-in screen
  /// costs the citizen a sign-in; the alternative costs them the app.
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final decoded = await readJsonGuarded(prefs, _key);
      if (decoded != null) {
        try {
          _account = CitizenAccount.fromJson(decoded as Map<String, dynamic>);
          final migrated = _migrateStaleDemoIdentity(_account!);
          if (migrated != null) {
            _account = migrated;
            await prefs.setString(_key, jsonEncode(migrated.toJson()));
          }
        } catch (error) {
          // Readable JSON, unreadable session — a shape this build no longer
          // understands. Drop it and start signed out rather than half-restored.
          debugPrint('persistence: unusable session, signing out — $error');
          _account = null;
          await prefs.remove(_key);
        }
      }
      if (_account == null) {
        _isGuest = prefs.getBool(_guestKey) ?? false;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// A browser signed in before the Marites-Ferrer-to-Cristy-Bonghanoy demo
  /// identity correction has that exact stale [CitizenAccount] snapshot
  /// persisted (see [login]'s full-object jsonEncode) — a source-code fix
  /// alone never reaches it, since this only ever reads back whatever was
  /// saved. Remaps a stale snapshot to the current, correct demo account
  /// object (by matching its old id) rather than forcing a manual re-login;
  /// returns null for every other account, which is left untouched.
  CitizenAccount? _migrateStaleDemoIdentity(CitizenAccount stale) {
    if (stale.id == 'ESP-RES-2024-1203') return MockCatalog.demoAccounts.last;
    if (stale.id == 'ESP-RES-2024-1203-DUP') return MockCatalog.duplicateCristyAccount;
    return null;
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
