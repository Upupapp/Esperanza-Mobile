// Signing out must actually erase the citizen's data from the device.
//
// `CitizenSessionService.logout()` cleared two of the app's ten preference
// keys: the session and the guest flag. Everything else stayed — the resident
// profile (birthdate, address, household, family, and the base64 profile
// photo), uploaded Master File documents, and the notification bookkeeping.
// All of it in plaintext XML on Android.
//
// That is not an abstract concern for this app. It is a municipal service used
// on shared and family handsets, and on a barangay-hall device the next person
// to sign in inherits a phone still holding the previous citizen's records.
// They would not *see* them — every service keys by account id — but "not
// rendered" is not "erased".
//
// These tests assert against **what is left in SharedPreferences**, not against
// the code path, for every service that still persists there. Trusting the
// code path is how the gap existed in the first place: `logout()` looked like
// it cleaned up, and did, for its own two keys.
//
// RequestsService itself is no longer part of that persisted-data story: it
// stopped writing anything to SharedPreferences once Dokyu/Tulong moved to the
// real API (production-readiness programme, 2026-09-25) -- the server is the
// only source of truth for a request's own state now, so there is nothing on
// disk left to erase. `SignOut.signOut` still takes it and still calls
// `requests.clear()`, so this file still confirms that wiring, just against
// in-memory state instead of a SharedPreferences key that no longer exists.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/services/sign_out.dart';

import 'support/fake_api.dart';

const _accountId = 'ESP-TEST-SIGNOUT';

CitizenAccount _account() => CitizenAccount(
      id: _accountId,
      firstName: 'Test',
      lastName: 'Resident',
      email: 'test@example.com',
      mobile: '0900 000 0000',
      barangay: 'Poblacion',
      purok: 'Purok 1',
      address: 'Purok 1, Brgy. Poblacion',
      birthdate: '1970-01-01',
      sex: '—',
      civilStatus: '—',
      occupation: '—',
      profileCompleteness: 100,
      status: 'Approved',
    );

// GET /citizen/requests' own thin summary shape -- see
// RequestsService._requestFromSummary. Nothing sends or reads
// ServiceRequest.toJson()'s full persisted shape anymore.
const _requestSummary = {
  'ref': 'ESP-2026-999999',
  'type': 'dokyu',
  'service': 'Barangay Clearance',
  'status': 'Submitted',
  'submitted': '2026-03-01T00:00:00.000',
};

// GET /community-posts' own row shape -- see
// BalitaService.loadFeed/Announcement.fromCommunityApi.
const _communityPost = {
  'id': 1,
  'author': 'Test Resident',
  'barangay': 'Poblacion',
  'category': 'Community',
  'body': 'Sign-out erasure fixture post.',
  'image_url': null,
  'status': 'Published',
  'visible': true,
  'likes': 0,
  'comments_count': 0,
  'liked_by_me': false,
  'mine': true,
  'created_at': '2026-03-01T00:00:00.000',
};

void _installFixtures() {
  FakeApi.installFull((req) {
    if (req.method == 'GET' && req.path == '/citizen/requests') return [_requestSummary];
    if (req.method == 'GET' && req.path == '/announcements') return <Map<String, dynamic>>[];
    if (req.method == 'GET' && req.path == '/community-posts') return [_communityPost];
    throw FakeApiError(messageEn: 'sign_out_erasure_test has no fixture for ${req.method} ${req.path}.');
  });
}

Future<void> _settle(WidgetTester tester, bool Function() ready, String what) async {
  var attempts = 0;
  while (!ready()) {
    attempts++;
    if (attempts > 100) throw StateError('$what never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  tearDown(FakeApi.restore);

  group('Signing out erases the account from the device', () {
    late CitizenSessionService session;
    late RequestsService requests;
    late ResidentProfileService profiles;
    late MasterFileService masterFile;
    late NotificationsService notifications;
    late BalitaService balita;

    Future<void> setUpSignedIn(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        // A device that already holds this citizen's data, as a real one would.
        'esperanza_read_notification_ids': jsonEncode(['notif-1', 'notif-2']),
        'esperanza_duplicate_alert_resolutions': jsonEncode({'scenario-a': 'kept'}),
        'esperanza_onboarding_complete': true,
      });
      _installFixtures();

      session = CitizenSessionService();
      requests = RequestsService();
      profiles = ResidentProfileService();
      masterFile = MasterFileService();
      notifications = NotificationsService();
      balita = BalitaService();

      await _settle(tester, () => !session.loading, 'CitizenSessionService');
      await _settle(tester, () => profiles.loaded, 'ResidentProfileService');
      await _settle(tester, () => masterFile.loaded, 'MasterFileService');
      await _settle(tester, () => notifications.loaded, 'NotificationsService');
      await requests.loadRequests();

      await session.login(_account());
    }

    Future<void> signOut() => SignOut.signOut(
          session,
          requests: requests,
          profiles: profiles,
          masterFile: masterFile,
          notifications: notifications,
          balita: balita,
        );

    testWidgets('the request history is gone in memory, not just from the screen', (tester) async {
      await setUpSignedIn(tester);
      expect(requests.all, hasLength(1), reason: 'fixture should be loaded before we test erasure');

      await signOut();
      await tester.pump(const Duration(milliseconds: 1));

      // Nothing to check on disk anymore -- RequestsService never wrote
      // 'esperanza_service_requests' in the first place (see this file's own
      // header comment). SignOut still coordinates requests.clear(), so the
      // in-memory list is what proves that wiring still runs.
      expect(requests.all, isEmpty);
      expect(requests.loaded, isFalse);
    });

    testWidgets('the Balita feed is gone in memory too, not just from the screen', (tester) async {
      await setUpSignedIn(tester);
      await balita.loadFeed(signedIn: true);
      expect(balita.loaded, isTrue, reason: 'fixture should be loaded before we test erasure');

      await signOut();
      await tester.pump(const Duration(milliseconds: 1));

      // Same reasoning as RequestsService above: Balita never persisted to
      // SharedPreferences either once it moved to the real API, so there is
      // nothing on disk to check -- only that the in-memory feed a shared
      // device's next citizen would otherwise see is actually gone.
      expect(balita.posts, isEmpty);
      expect(balita.loaded, isFalse);
    });

    testWidgets('notification bookkeeping is cleared', (tester) async {
      await setUpSignedIn(tester);
      await signOut();
      await tester.pump(const Duration(milliseconds: 1));

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString('esperanza_read_notification_ids'), isNull);
      expect(prefs.getString('esperanza_duplicate_alert_resolutions'), isNull);
      expect(prefs.getString('esperanza_unverified_duplicate_kept_account'), isNull);
    });

    testWidgets('the session and guest flag are cleared too', (tester) async {
      await setUpSignedIn(tester);
      await signOut();
      await tester.pump(const Duration(milliseconds: 1));

      expect(session.isSignedIn, isFalse);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString('esperanza_citizen_session'), isNull);
      expect(prefs.getBool('esperanza_guest_mode'), isNull);
    });

    testWidgets('onboarding completion survives — it is device state, not personal data', (tester) async {
      // Erasing this would re-show the three-screen welcome flow to whoever
      // picks the handset up next. That is noise, not privacy.
      await setUpSignedIn(tester);
      await signOut();
      await tester.pump(const Duration(milliseconds: 1));

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getBool('esperanza_onboarding_complete'), isTrue);
    });

    testWidgets('signing out with no account signed in does not throw', (tester) async {
      SharedPreferences.setMockInitialValues({});
      session = CitizenSessionService();
      requests = RequestsService();
      profiles = ResidentProfileService();
      masterFile = MasterFileService();
      notifications = NotificationsService();
      balita = BalitaService();
      await _settle(tester, () => !session.loading, 'CitizenSessionService');
      await _settle(tester, () => profiles.loaded, 'ResidentProfileService');
      await _settle(tester, () => masterFile.loaded, 'MasterFileService');
      await _settle(tester, () => notifications.loaded, 'NotificationsService');

      await expectLater(signOut(), completes);
    });
  });
}
