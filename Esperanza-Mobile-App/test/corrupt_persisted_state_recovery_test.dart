// Regression coverage for the permanent-splash-hang class of failure.
//
// Every service restores its state from SharedPreferences in a future kicked
// off by its own constructor, and nothing awaits that future. Before the
// guards this file covers, an undecodable payload threw *inside* that
// un-awaited future: the `_loaded`/`_loading` flag was never flipped and
// `notifyListeners()` never fired, so `AuthGate` (main.dart) rendered its
// `CircularProgressIndicator` forever. The only user-facing recovery was
// clearing app data.
//
// That is not a hypothetical for this codebase — it already ships five
// separate migrations for persisted data that changed shape
// (`_migrateStaleDemoIdentity`, `_migrateSeniorCitizenIdCategory`,
// `_migrateObsoleteTrackingLabels`, ...), and every one of them runs *after*
// the decode that would have thrown. A model or enum renamed in a future
// build is exactly the trigger.
//
// Each case below asserts the weaker, correct contract: whatever the stored
// bytes are, the service must finish loading and expose empty//default state
// rather than never finishing. `_settle` is what actually encodes "must not
// hang" — it gives up after 100 pumps, which is precisely what the
// unguarded code did.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';

/// Pumps until [isLoaded] reports true, failing loudly instead of hanging the
/// suite. Before the restore guards this threw for every payload below.
Future<void> _settle(WidgetTester tester, bool Function() isLoaded, String what) async {
  var attempts = 0;
  while (!isLoaded()) {
    attempts++;
    if (attempts > 100) {
      throw StateError('$what never finished loading — the splash would spin forever.');
    }
    await tester.pump(const Duration(milliseconds: 1));
  }
}

/// Three shapes of unreadable payload, each a real way persisted state goes
/// bad: bytes that are not JSON at all, valid JSON of the wrong type, and
/// valid JSON of the right type naming an enum value this build no longer has.
const _notJson = '{this is not json';
const _wrongType = '{"unexpected":"object where a list belongs"}';

void main() {
  group('A corrupt or incompatible persisted payload never bricks the splash', () {
    testWidgets('CitizenSessionService falls back to signed-out', (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_citizen_session': _notJson});

      final session = CitizenSessionService();
      await _settle(tester, () => !session.loading, 'CitizenSessionService');

      expect(session.isSignedIn, isFalse);
      expect(session.account, isNull);
    });

    testWidgets('CitizenSessionService discards the bad session so the next launch is clean', (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_citizen_session': _notJson});

      final session = CitizenSessionService();
      await _settle(tester, () => !session.loading, 'CitizenSessionService');
      // The discard is best-effort and fire-and-forget; let it land.
      await tester.pump(const Duration(milliseconds: 1));

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString('esperanza_citizen_session'), isNull);
    });

    testWidgets('RequestsService drops an unreadable list rather than hanging', (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_service_requests': _wrongType});

      final requests = RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true);
      await _settle(tester, () => requests.loaded, 'RequestsService');

      expect(requests.all, isEmpty);
    });

    testWidgets('BalitaService survives a non-JSON payload', (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_balita_posts': _notJson});

      final balita = BalitaService();
      await _settle(tester, () => balita.loaded, 'BalitaService');
    });

    testWidgets('MasterFileService survives a payload of the wrong type', (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_master_file_documents': '["a list, not a map"]'});

      final masterFile = MasterFileService();
      await _settle(tester, () => masterFile.loaded, 'MasterFileService');
    });

    testWidgets('NotificationsService survives a non-JSON payload', (tester) async {
      SharedPreferences.setMockInitialValues({
        'esperanza_read_notification_ids': _notJson,
        'esperanza_duplicate_alert_resolutions': _notJson,
      });

      final notifications = NotificationsService();
      await _settle(tester, () => notifications.loaded, 'NotificationsService');
    });

    testWidgets('ResidentProfileService survives a payload of the wrong type', (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_resident_profiles': _wrongType});

      final profiles = ResidentProfileService();
      await _settle(tester, () => profiles.loaded, 'ResidentProfileService');
    });
  });

  group('An enum value this build no longer knows decodes to a fallback, not a throw', () {
    testWidgets('an unknown ServiceCategory keeps the rest of the request readable', (tester) async {
      // Everything else in this payload is well-formed; only `category` names
      // a value that a future build could plausibly have renamed or removed.
      final request = ServiceRequest(
        id: 'unknown-category-fixture',
        referenceNumber: 'ESP-2026-000001',
        applicantId: 'ESP-RES-0000-0000',
        applicantName: 'Test Fixture',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Regression fixture',
        submittedAt: DateTime(2026, 3, 1),
        status: 'Submitted',
        statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 3, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '1-2 working days',
      );
      final json = request.toJson();
      json['category'] = 'aCategoryThisBuildNoLongerHas';

      SharedPreferences.setMockInitialValues({
        'esperanza_service_requests': jsonEncode([json]),
      });

      final requests = RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true);
      await _settle(tester, () => requests.loaded, 'RequestsService');

      // The request survives — the whole list used to be lost to the throw.
      expect(requests.all, hasLength(1));
      expect(requests.all.single.referenceNumber, 'ESP-2026-000001');
      expect(requests.all.single.category, ServiceCategory.dokyu);
    });
  });
}
