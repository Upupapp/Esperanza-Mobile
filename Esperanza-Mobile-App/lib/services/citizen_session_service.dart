import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/access_level.dart';
import '../models/citizen_account.dart';
import '../models/id_verification.dart';
import '../models/profile_photo.dart';
import '../theme/app_status.dart';
import 'api_client.dart';
import 'json_read.dart';
import 'mock_catalog.dart';
import 'persistence_recovery.dart';
import 'push_service.dart';

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

  /// True after the server ended the session (a 401), until the next sign-in:
  /// AuthGate says so on the sign-in screen. A Sign Out the resident chose
  /// leaves it false.
  bool get endedByServer => _endedByServer;
  bool _endedByServer = false;

  /// The profile photo as the LGU holds it; refreshed with every profile read
  /// (the app re-reads it on start), never persisted on the phone.
  ProfilePhotoView? _photo;
  ProfilePhotoView? get photo => _photo;

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
    // The server's access_level wins when it sent one: an approved account
    // whose identity the LGU revoked (or is re-checking) is Unverified there,
    // and must not look Verified here (2026-10-09). The status-derived answer
    // above stays the fallback for an account cached by an older build.
    final server = acc.serverAccessLevel;
    if (server != null) return server == 'Verified' ? AccessLevel.verified : AccessLevel.unverified;
    if (acc.identityStatus != null && acc.identityStatus != 'Verified') return AccessLevel.unverified;
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
    _endedByServer = true;
    await api.setToken(null);
    // No sign-out call can reach the server now: drop the push token instead.
    unawaited(PushService.forget());
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
    _endedByServer = false;
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

  /// GET /id-types: the valid IDs the LGU accepts for account verification.
  /// Public, because sign-up asks before an account exists.
  Future<List<String>> idTypes() async {
    final result = await api.get('/id-types');
    return JsonRead.strings(result.data);
  }

  /// GET /citizen/verification/id: the latest valid ID sent, its review
  /// (with the officer's reason when it was not accepted), and whether a new
  /// one may be sent. The web portal's Profile shows the same.
  Future<IdVerificationView> idVerification() async {
    final result = await api.get('/citizen/verification/id');
    return IdVerificationView.fromApi(result.data);
  }

  /// POST /citizen/verification/id: the valid ID (front, optional back) and a
  /// selfie the officer compares with it. The officer verifies the account on
  /// these (backlog B1); until 2026-10-04 they stayed on the phone. Returns
  /// the updated view; a new ID replaces one still waiting for review.
  Future<IdVerificationView> submitVerificationId({
    required String idType,
    required String frontPath,
    String? backPath,
    String? selfiePath,
  }) async {
    final result = await api.postMultipart(
      '/citizen/verification/id',
      fields: {'id_type': idType},
      files: {
        'front': frontPath,
        'back': ?backPath,
        'selfie': ?selfiePath,
      },
    );
    return IdVerificationView.fromApi(result.data);
  }

  /// POST /citizen/profile/photo. Waits for an officer; the Digital ID keeps
  /// the approved photo until then. A change too soon is refused by the
  /// server (PHOTO_CHANGE_TOO_SOON), surfaced as an ordinary ApiException.
  Future<ProfilePhotoView?> uploadProfilePhoto(List<int> bytes) async {
    final result = await api.postMultipart(
      '/citizen/profile/photo',
      bytesFiles: {'photo': (bytes: bytes, filename: 'profile-photo.jpg')},
    );
    _photo = ProfilePhotoView.fromApi(result.data) ?? _photo;
    notifyListeners();
    return _photo;
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
    await _applyProfile(result.map);
    // A confirmed session: this phone gets the resident's pushes (2026-10-15).
    if (!_isGuest && _account != null) unawaited(PushService.register());
  }

  /// PUT /citizen/profile (CitizenPortalController::updateProfile()) --
  /// only the keys in [changes] are sent. A verified account's identity
  /// fields (name, birthdate, sex, barangay) are corrected by the barangay,
  /// not the holder: the server refuses them with IDENTITY_LOCKED (422),
  /// surfaced as an ordinary [ApiException].
  Future<void> saveProfile(Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    final result = await api.put('/citizen/profile', body: changes);
    await _applyProfile(result.map);
  }

  /// POST /citizen/profile/contact: starts an email or mobile change. The
  /// code goes to the NEW address, so the change cannot land on a contact the
  /// holder does not control. Returns the masked destination to show.
  Future<String?> requestContactChange({required String channel, required String value}) async {
    final result = await api.post('/citizen/profile/contact', body: {'channel': channel, 'value': value});
    return JsonRead.nonEmpty(result.map['destination']);
  }

  /// POST /citizen/profile/contact/verify: confirms the pending change and
  /// adopts the profile the server returns.
  Future<void> verifyContactChange(String code) async {
    final result = await api.post('/citizen/profile/contact/verify', body: {'code': code});
    await _applyProfile(result.map);
  }

  /// The server locks the identifying fields of an APPROVED account - also
  /// while its identity is revoked, so they cannot be retyped before an
  /// officer looks again (CitizenPortalController, 2026-10-09).
  bool get identityLocked => _account?.status == 'Approved';

  Future<void> _applyProfile(Map<String, dynamic> p) async {
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
    _photo = ProfilePhotoView.fromApi(p['photo']);
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
        identityStatus: JsonRead.nonEmpty(p['identity_status']),
        serverAccessLevel: JsonRead.nonEmpty(p['access_level']),
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
    // While still signed in: the server forgets this phone for push.
    await PushService.unregister();
    try {
      await api.post('/auth/logout');
    } catch (_) {
      // Token already invalid or unreachable — the session is cleared
      // locally either way, same reasoning as the web client's logout().
    }
    await api.setToken(null);
    _account = null;
    _photo = null;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_guestKey);
    notifyListeners();
  }
}
