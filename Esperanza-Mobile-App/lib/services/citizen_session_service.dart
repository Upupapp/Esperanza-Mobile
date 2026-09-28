import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/access_level.dart';
import '../models/citizen_account.dart';
import '../theme/app_status.dart';
import 'api_client.dart';
import 'json_read.dart';
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
    ApiClient.addSessionExpiredListener(_onSessionExpired);
    _restore();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    ApiClient.removeSessionExpiredListener(_onSessionExpired);
    super.dispose();
  }

  /// The server answered 401 to a signed-in call: the token is gone, so the
  /// cached account is only a picture of a session that no longer exists.
  /// Cleared locally (no POST /auth/logout -- it would 401 too) so AuthGate
  /// returns the citizen to sign-in instead of every screen showing an error.
  /// Device-local data (resident profile drafts, Master File) is kept: an
  /// expired token is not the citizen asking to be forgotten.
  Future<void> _onSessionExpired() async {
    if (_account == null) return;
    _account = null;
    _isGuest = false;
    await api.setToken(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Memory is already cleared; a failed write only matters on restart,
      // where the next call 401s and lands here again.
    }
    if (!_disposed) notifyListeners();
  }

  /// Re-reads the profile in the background after a warm start from the
  /// cache. The doc comment on [refresh] always promised this; nothing
  /// called it, so a citizen the LGU verified stayed locked out of Dokyu
  /// until they signed out and in again. A network failure keeps the cached
  /// copy (offline start still works); a 401 clears it via
  /// [_onSessionExpired].
  Future<void> _revalidate() async {
    if (await api.getToken() == null) return;
    try {
      await refresh();
    } catch (_) {
      // See above.
    }
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
    if (_account != null) unawaited(_revalidate());
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
    final token = JsonRead.nonEmpty(result.map['token']);
    if (token == null) {
      // Proceeding would call GET /citizen/profile unauthenticated and show
      // an unrelated 401 as the reason sign-in failed.
      throw const ApiException(
        messageEn: 'Sign-in did not complete. Please try again.',
        messageFil: 'Hindi natapos ang pag-sign in. Pakisubukang muli.',
      );
    }
    await api.setToken(token);
    try {
      await refresh();
    } catch (_) {
      // A token with no session behind it: drop it, so the next launch does
      // not start half signed in.
      await api.setToken(null);
      rethrow;
    }
  }

  /// Registration step 1a: POST /auth/citizen/email/send-code. Runs before
  /// the account exists. Throws [ApiException] with code `EMAIL_TAKEN` when
  /// the address already belongs to a citizen, `CODE_TOO_SOON` on a quick
  /// resend; otherwise a code has been emailed.
  Future<void> sendEmailCode(String email) async {
    await api.post('/auth/citizen/email/send-code', body: {'email': email});
  }

  /// Registration step 1b: POST /auth/citizen/email/verify-code. Returns the
  /// single-use token that [register] presents as `email_verification_token`.
  Future<String> verifyEmailCode({required String email, required String code}) async {
    final result = await api.post('/auth/citizen/email/verify-code', body: {'email': email, 'code': code});
    final token = JsonRead.nonEmpty(result.map['verification_token']);
    if (token == null) {
      // Was a hard `as String` cast: a TypeError the register screen (which
      // catches ApiException only) could not show, leaving the step stuck.
      throw const ApiException(
        messageEn: 'The code could not be confirmed. Please request a new one.',
        messageFil: 'Hindi makumpirma ang code. Humingi ng bagong code.',
      );
    }
    return token;
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
    final accountNo = JsonRead.nonEmpty(p['account_no']);
    if (accountNo == null) {
      // Every per-account store (profile drafts, Master File, notification
      // read state) keys on this id; an empty one would merge accounts.
      throw const ApiException(
        messageEn: 'Your profile could not be loaded. Please try again.',
        messageFil: 'Hindi ma-load ang iyong profile. Pakisubukang muli.',
      );
    }
    String str(String key) => JsonRead.string(p[key]) ?? '';
    await login(
      CitizenAccount(
        id: accountNo,
        firstName: str('first_name'),
        lastName: str('last_name'),
        email: str('email'),
        mobile: str('mobile'),
        barangay: str('barangay'),
        purok: str('purok'),
        address: str('address'),
        birthdate: str('birthdate'),
        sex: str('sex'),
        civilStatus: str('civil_status'),
        occupation: str('occupation'),
        profileCompleteness: JsonRead.integer(p['profile_completeness']) ?? 0,
        status: JsonRead.nonEmpty(p['status']) ?? 'Draft',
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
