import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/access_level.dart';
import '../models/citizen_account.dart';
import '../theme/app_status.dart';
import 'api_client.dart';
import 'mock_catalog.dart';
import 'persistence_recovery.dart';

/// The real citizen session, backed by the backend's Sanctum bearer tokens
/// (production-readiness programme, 2026-09-25) — the mobile equivalent of
/// the Web Admin's `Alpine.store('citizenSession')` in resources/js/app.js,
/// after that store's own rewrite off its login-simulation.
///
/// [login]/[register]/[verify] call the real API via [ApiClient] and cache
/// the resulting account to SharedPreferences purely as a warm-start copy;
/// [refresh] always re-fetches GET /citizen/profile and overwrites it, the
/// same pattern the web client uses, so a status change the LGU made (e.g.
/// verifying the account) is visible on the next app open, not only after a
/// manual re-login.
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
    final status = AppStatusX.fromLabel(acc.status);
    // `Approved` and `Verified` are the same state under two names. The Web
    // Admin stores `Approved` and *displays* `Verified`
    // (constituents.blade.php: `$acct['status'] === 'Approved' ? 'Verified'`),
    // and its own comment says `Verified` grants full Dokyu/Tulong access.
    // Mobile writes only `Approved` today, so this is additive — but before
    // `verified` existed in AppStatus, a status arriving as `Verified` resolved
    // to `draft` and locked the citizen OUT of Dokyu, meaning the identical
    // word granted access on one surface and denied it on the other.
    final isVerified = status == AppStatus.approved || status == AppStatus.verified;
    return isVerified ? AccessLevel.verified : AccessLevel.unverified;
  }

  CitizenSessionService() {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _account = CitizenAccount.fromJson(jsonDecode(raw));
        final migrated = _migrateStaleDemoIdentity(_account!);
        if (migrated != null) {
          _account = migrated;
          await prefs.setString(_key, jsonEncode(migrated.toJson()));
        }
      } else {
        _isGuest = prefs.getBool(_guestKey) ?? false;
      }
    } catch (error) {
      // A payload persisted by an earlier build can fail to decode after a
      // model or enum changes shape. Before this guard that throw escaped an
      // un-awaited future started in the constructor, so notifyListeners()
      // never fired and AuthGate spun on the splash forever - recoverable
      // only by clearing app data. Discard the unreadable state instead; the
      // migrations here already exist for exactly this class of change.
      _account = null;
      _isGuest = false;
      // Only the session key — the guest flag is a separate, still-readable key.
      await PersistenceRecovery.discardUnreadable(
        service: 'CitizenSessionService',
        keys: const [_key],
        error: error,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }


  /// A browser signed in before the Perlita-Quiambao-to-Perlita-Quiambao demo
  /// identity correction has that exact stale [CitizenAccount] snapshot
  /// persisted (see [login]'s full-object jsonEncode) — a source-code fix
  /// alone never reaches it, since this only ever reads back whatever was
  /// saved. Remaps a stale snapshot to the current, correct demo account
  /// object (by matching its old id) rather than forcing a manual re-login;
  /// returns null for every other account, which is left untouched.
  CitizenAccount? _migrateStaleDemoIdentity(CitizenAccount stale) {
    if (stale.id == 'ESP-RES-2024-1203') return MockCatalog.demoAccounts.last;
    if (stale.id == 'ESP-RES-2024-1203-DUP') return MockCatalog.duplicateVerifiedDemoAccount;
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

  /// Real sign-in: POST /auth/citizen/login, then GET /citizen/profile for
  /// the fields the login response itself does not carry (see AuthController
  /// ::citizenLogin vs ::me/CitizenPortalController::profile on the
  /// backend). Throws [ApiException] on failure — the caller's own error
  /// state is what a login screen shows, same as the web client.
  Future<void> loginWithCredentials(String identifier, String password) async {
    final result = await api.post('/auth/citizen/login', body: {'identifier': identifier, 'password': password});
    final token = result.map['token'] as String?;
    if (token != null) await api.setToken(token);
    await refresh();
  }

  /// POST /auth/citizen/register. Returns the account_no and the OTP
  /// destination the backend actually sent to — never assume email; the
  /// citizen may have registered with a mobile number only.
  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final result = await api.post('/auth/citizen/register', body: payload);
    return result.map;
  }

  /// POST /auth/citizen/verify. The account is unusable (Pending Review,
  /// not yet Verified) until this succeeds — matching what the web
  /// registration flow now does.
  Future<void> verify({required String accountNo, required String code}) async {
    await api.post('/auth/citizen/verify', body: {'account_no': accountNo, 'code': code});
  }

  /// Re-derive the session from the server. Never trust the cached copy for
  /// a decision — a status the LGU changed, or a token the server has
  /// revoked, must take effect on the very next call, not only after a
  /// manual re-login.
  Future<void> refresh() async {
    final result = await api.get('/citizen/profile');
    final p = result.map;
    await login(
      CitizenAccount(
        id: p['account_no'] as String? ?? '',
        firstName: p['first_name'] as String? ?? '',
        lastName: p['last_name'] as String? ?? '',
        email: p['email'] as String? ?? '',
        mobile: p['mobile'] as String? ?? '',
        barangay: p['barangay'] as String? ?? '',
        purok: p['purok'] as String? ?? '',
        address: p['address'] as String? ?? '',
        birthdate: p['birthdate'] as String? ?? '',
        sex: p['sex'] as String? ?? '',
        civilStatus: p['civil_status'] as String? ?? '',
        occupation: p['occupation'] as String? ?? '',
        profileCompleteness: (p['profile_completeness'] as num?)?.round() ?? 0,
        status: p['status'] as String? ?? 'Draft',
      ),
    );
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
    try {
      await api.post('/auth/logout');
    } catch (_) {
      // Token already invalid or unreachable — the session is cleared
      // locally either way, same reasoning as the web client's logout().
    }
    await api.setToken(null);
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
