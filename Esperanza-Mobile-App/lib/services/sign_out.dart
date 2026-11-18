import 'balita_service.dart';
import 'citizen_session_service.dart';
import 'master_file_service.dart';
import 'notifications_service.dart';
import 'requests_service.dart';
import 'resident_profile_service.dart';

/// The one place that knows what signing out has to erase.
///
/// `CitizenSessionService.logout()` clears the session and the guest flag — two
/// of the app's ten preference keys. On its own that leaves the citizen's
/// resident profile (birthdate, address, household, family and the base64
/// profile photo), their whole request history, their uploaded Master File
/// documents and their notification bookkeeping sitting on the device, in
/// plaintext, after they have signed out.
///
/// That matters here more than it would elsewhere: this is a municipal app for
/// a whole municipality, and it will be used on shared and family handsets. The
/// next person to sign in would not *see* the previous citizen's data — every
/// service keys by account id — but it is still on disk and still recoverable.
///
/// This exists as a single coordinator rather than as logic inside each caller
/// because there are two sign-out entry points (the profile screen and the
/// drawer). Two copies of a rule is how they end up disagreeing.
///
/// It is deliberately **not** inside `CitizenSessionService`: that service owns
/// the session, not the other five services, and giving it references to them
/// would invert the dependency direction the whole app is built on.
class SignOut {
  SignOut._();

  /// Signs [session] out and erases everything that belonged to that account.
  ///
  /// Order matters: the data is erased *first*, then the session is cleared.
  /// Clearing the session first would leave nothing to identify which account's
  /// data to erase if any step after it failed. The erasure runs once more
  /// after the session is cleared, for what open screens brought back while
  /// the server was being told.
  ///
  /// With no one signed in, the next launch opens on the welcome pages
  /// (owner, 2026-10-12).
  static Future<void> signOut(
    CitizenSessionService session, {
    required RequestsService requests,
    required ResidentProfileService profiles,
    required MasterFileService masterFile,
    required NotificationsService notifications,
    required BalitaService balita,
  }) async {
    final accountId = session.account?.id;

    if (accountId != null) {
      // In-memory only now -- requests/Balita are no longer persisted to
      // SharedPreferences, so there is nothing on disk left to erase; the
      // next sign-in's own loadRequests()/loadFeed() replaces this from the
      // server. Balita specifically used to be excluded here ("public
      // municipal content, identical for everyone") -- that stopped being
      // true once the feed carried real per-citizen `liked_by_me` state
      // (production-readiness programme, 2026-09-25), so a shared device's
      // next citizen must not see the previous citizen's fetched feed
      // before their own fresh loadFeed() runs.
      requests.clear();
      balita.clear();
      await profiles.forgetAccount(accountId);
      await masterFile.forgetAccount(accountId);
      await notifications.forgetAccount(accountId);
    }

    await session.logout();

    // Again, now that no one is signed in (QA sweep 2026-11-18). logout()
    // waits on the server (push unregister, POST /auth/logout) while the
    // account is still set, and the erasure above has already notified:
    // an open Profile or Home rebuilds in that gap, and profileFor seeds the
    // forgotten account again, live updates refill the bell, the feed or the
    // Master File. Those copies would stay for the next resident, and the
    // next save would write them to disk. RequestsService needs no second
    // pass: its loads from that gap are dropped by their token.
    if (accountId != null) {
      balita.clear();
      await profiles.forgetAccount(accountId);
      await masterFile.forgetAccount(accountId);
      await notifications.forgetAccount(accountId);
    }
  }
}
