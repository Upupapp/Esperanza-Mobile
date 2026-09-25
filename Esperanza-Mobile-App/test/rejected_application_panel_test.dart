// Coverage for RequestDetailScreen's "Application Rejected" panel: the
// reason/guidance display, Apply Again opening a brand-new application
// without touching the original rejected request, the new application
// getting its own reference number, and Apply Again still respecting the
// Tulong eligibility rule (see utils/tulong_eligibility.dart) when another
// active application for the same assistance also exists.
//
// The old seeded Educational Assistance demo request this used to reach for
// (RequestsService(seedDemoData: true)) is gone along with the rest of
// local demo seeding -- this now builds its own fixture request via
// test/support/dokyu_tulong_fixtures.dart. The reason/guidance text is also
// different from before: guidance is no longer a per-catalog-item
// CatalogItem.demoRejectionReason-derived string (that field, and
// ServiceRequest.rejectionGuidance, are both unused now) -- the panel
// always builds a generic "Submit a new <service> application." from
// typeName, and reason is the server's own real decision_remarks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/shared/new_request_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/screens/shared/service_request_wizard_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';

import 'support/dokyu_tulong_fixtures.dart';
import 'support/fake_api.dart';

const _rejectionReason = 'Submitted school enrollment document could not be verified for the current academic '
    'term. Please submit an updated Certificate of Enrollment or Registration issued by the school.';
const _rejectedRef = 'AR-2026-DEMO06';

Map<String, dynamic> _rejectedEducationalAssistance({String? decisionRemarks = _rejectionReason}) => {
  'ref': _rejectedRef,
  'type': 'tulong',
  'service': 'Educational Assistance',
  'status': 'Rejected',
  'submitted': '2026-01-01T00:00:00.000',
  'office': 'Office of the Municipal Mayor',
  'decision_remarks': decisionRemarks,
};

Future<RequestsService> _readyRequests(WidgetTester tester, List<Map<String, dynamic>> seeded) async {
  SharedPreferences.setMockInitialValues({});
  DokyuTulongFixtures.install(requests: seeded);
  final requests = RequestsService();
  await requests.loadRequests();
  await requests.loadCatalog(); // Apply Again looks the item up from here.
  return requests;
}

Future<CitizenSessionService> _signedInAsVerifiedDemo(WidgetTester tester) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified
  return session;
}

Future<void> _pumpDetail(
  WidgetTester tester,
  RequestsService requests,
  CitizenSessionService session,
  String requestId,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
      ],
      child: MaterialApp(home: RequestDetailScreen(requestId: requestId)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(FakeApi.restore);

  group('Rejected Educational Assistance application', () {
    testWidgets('Application Rejected panel shows the reason, generic guidance, and an Apply Again button', (
      tester,
    ) async {
      final requests = await _readyRequests(tester, [_rejectedEducationalAssistance()]);
      final session = await _signedInAsVerifiedDemo(tester);

      await _pumpDetail(tester, requests, session, _rejectedRef);

      expect(find.text('Application Rejected'), findsOneWidget);
      expect(find.text(_rejectionReason), findsWidgets);
      expect(find.text('What you can do:'), findsOneWidget);
      expect(find.text('Submit a new Educational Assistance application.'), findsOneWidget);
      expect(find.text('Apply Again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Apply Again opens a brand-new Educational Assistance application, old request untouched', (
      tester,
    ) async {
      final requests = await _readyRequests(tester, [_rejectedEducationalAssistance()]);
      final session = await _signedInAsVerifiedDemo(tester);

      await _pumpDetail(tester, requests, session, _rejectedRef);
      await tester.ensureVisible(find.text('Apply Again'));
      await tester.tap(find.text('Apply Again'));
      await tester.pumpAndSettle();

      // Educational Assistance is sourced/formSpec'd -> the wizard, not the
      // older single-step screen.
      expect(find.byType(ServiceRequestWizardScreen), findsOneWidget);
      expect(find.byType(NewRequestScreen), findsNothing);

      // The original rejected request is completely unchanged -- nothing
      // in Apply Again mutates it, local or remote.
      final stillThere = requests.all.firstWhere((r) => r.referenceNumber == _rejectedRef);
      expect(stillThere.status, 'Rejected');
      expect(stillThere.adminRemarks, _rejectionReason);
    });

    testWidgets('submitting the reapplication creates a new request with its own reference number', (tester) async {
      final requests = await _readyRequests(tester, [_rejectedEducationalAssistance()]);
      final before = requests.all.length;

      DokyuTulongFixtures.install(
        requests: [_rejectedEducationalAssistance()],
        onSubmit: (body) => {
          'ref': 'AR-2026-0099',
          'type': 'tulong',
          'service': 'Educational Assistance',
          'status': 'Submitted',
          'submitted': '2026-03-01T00:00:00.000',
        },
      );

      final reapplied = await requests.submit(
        serviceKey: 'tulong_educational',
        formData: {'purpose': 'Tuition and allowance support — updated enrollment document attached'},
      );

      expect(requests.all.length, before + 1);
      expect(reapplied.referenceNumber, isNot(_rejectedRef));
      final original = requests.all.firstWhere((r) => r.referenceNumber == _rejectedRef);
      expect(original.status, 'Rejected'); // preserved in history, unchanged
      expect(reapplied.status, 'Submitted');
    });

    testWidgets('Apply Again still respects the Tulong eligibility rule when another application is active', (
      tester,
    ) async {
      final active = {
        'ref': 'AR-2026-0002',
        'type': 'tulong',
        'service': 'Educational Assistance',
        'status': 'Pending Review',
        'submitted': '2026-02-01T00:00:00.000',
      };
      final requests = await _readyRequests(tester, [_rejectedEducationalAssistance(), active]);
      final session = await _signedInAsVerifiedDemo(tester);

      await _pumpDetail(tester, requests, session, _rejectedRef);
      await tester.ensureVisible(find.text('Apply Again'));
      await tester.tap(find.text('Apply Again'));
      await tester.pumpAndSettle();

      // Blocked by the OTHER, currently-active application for the same
      // assistance — never reaches the wizard.
      expect(find.text('Active Application Exists'), findsOneWidget);
      expect(find.byType(ServiceRequestWizardScreen), findsNothing);
    });
  });

  group('Application Rejected panel gating', () {
    testWidgets('does not show for a Rejected request with no decision_remarks on file', (tester) async {
      final noReason = {
        'ref': 'DR-2026-0001',
        'type': 'dokyu',
        'service': 'Certificate of Indigency',
        'status': 'Rejected',
        'submitted': '2026-01-01T00:00:00.000',
        'office': 'Municipal Social Welfare and Development Office',
        'decision_remarks': null,
      };
      final requests = await _readyRequests(tester, [noReason]);
      final session = await _signedInAsVerifiedDemo(tester);

      await _pumpDetail(tester, requests, session, 'DR-2026-0001');

      expect(find.text('Application Rejected'), findsNothing);
      expect(find.text('Apply Again'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
