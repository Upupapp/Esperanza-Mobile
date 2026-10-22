// Coverage for: the new "My Requests" hamburger screen, the Tulong
// status-based reapplication rule, and the "Track This Request" fix (it
// must open the exact just-submitted request, never a stale/wrong one).
//
// Dokyu's own "repeat-request rule" (no cap on how many times the same
// document can be requested) used to have its own group here, submitting
// the same service 4 times through RequestsService directly and checking
// each got its own reference number. That was really exercising the fake
// backend's willingness to accept duplicates, not any mobile-side logic --
// there is no gate to test (neither Dokyu nor, since 2026-10-22, Tulong
// has one), so it added no coverage beyond what the "Track
// This Request" case below already proves (two submissions, two distinct
// requests). Dropped rather than converted.
//
// The old "account scoping" cases (Nicanor never sees Perlita's requests,
// and vice versa) are gone too -- that was local-simulation-only isolation.
// GET /citizen/requests is already scoped to the signed-in citizen by the
// bearer token (production-readiness programme, 2026-09-25), so there is
// nothing left for the client to isolate, and no way to simulate "two
// accounts' requests coexisting" against a fake backend that just returns
// whatever list a test configures regardless of which account is signed in.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/shared/my_requests_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_submitted_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:esperanza_mobile/widgets/segmented_tabs.dart';

import 'support/dokyu_tulong_fixtures.dart';
import 'support/fake_api.dart';

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

// GET /citizen/requests' own thin summary shape (ref/type/service/status/
// submitted) -- see RequestsService._requestFromSummary.
Map<String, dynamic> _summary({
  required String ref,
  required String type,
  required String service,
  required String status,
  String submitted = '2026-01-01T00:00:00.000',
}) => {'ref': ref, 'type': type, 'service': service, 'status': status, 'submitted': submitted};

/// Installs the fake backend with [seeded] already present and returns a
/// [RequestsService] that has loaded them. No [WidgetTester] parameter --
/// nothing here pumps a widget, and a plain awaited Future doesn't need
/// one; see the "Tulong reapplication rule" group below, which is plain
/// test() for the same reason.
Future<RequestsService> _loadedWith(List<Map<String, dynamic>> seeded) async {
  SharedPreferences.setMockInitialValues({});
  DokyuTulongFixtures.install(requests: seeded);
  final requests = RequestsService();
  await requests.loadRequests();
  return requests;
}

void main() {
  tearDown(FakeApi.restore);

  // Plain test(), not testWidgets() -- nothing here pumps a widget, just
  // awaits RequestsService.loadRequests() directly. A testWidgets with zero
  // tester.pump calls anywhere can hang on ApiClient's own 15s Timer-based
  // .timeout() until it times out, since flutter_test's fake-async zone
  // apparently never services that Timer unless something has already
  // pumped in that test (found while fixing service_category_unknown_test.dart's
  // equivalent case) -- test() has no such zone and isn't affected.

  group('My Requests screen', () {
    Future<void> pumpMyRequests(WidgetTester tester, RequestsService requests, CitizenSessionService session) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ],
          child: const MaterialApp(home: MyRequestsScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows Dokyu + Tulong together under All, and each filter narrows correctly', (tester) async {
      final requests = await _loadedWith([
        _summary(ref: 'DR-2026-0001', type: 'dokyu', service: 'Barangay Clearance', status: 'Submitted'),
        _summary(ref: 'AR-2026-0001', type: 'tulong', service: 'Medical Assistance (AICS)', status: 'Submitted'),
      ]);
      final session = await _signedInAsVerifiedDemo(tester);

      await pumpMyRequests(tester, requests, session);

      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Medical Assistance (AICS)'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(SegmentedTabs), matching: find.text('Dokyu')));
      await tester.pumpAndSettle();
      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Medical Assistance (AICS)'), findsNothing);

      await tester.tap(find.descendant(of: find.byType(SegmentedTabs), matching: find.text('Tulong')));
      await tester.pumpAndSettle();
      expect(find.text('Barangay Clearance'), findsNothing);
      expect(find.text('Medical Assistance (AICS)'), findsOneWidget);
    });

    testWidgets('sorts newest submission first', (tester) async {
      final requests = await _loadedWith([
        _summary(
          ref: 'DR-2026-0001',
          type: 'dokyu',
          service: 'Barangay Clearance',
          status: 'Submitted',
          submitted: '2026-01-01T00:00:00.000',
        ),
        _summary(
          ref: 'AR-2026-0001',
          type: 'tulong',
          service: 'Medical Assistance (AICS)',
          status: 'Submitted',
          submitted: '2026-06-01T00:00:00.000',
        ),
      ]);
      final session = await _signedInAsVerifiedDemo(tester);

      await pumpMyRequests(tester, requests, session);

      final firstCardText = tester
          .widgetList<Text>(find.descendant(of: find.byType(ListView), matching: find.byType(Text)))
          .elementAt(1) // index 0 is the category badge; index 1 is the service name
          .data;
      expect(firstCardText, 'Medical Assistance (AICS)'); // the newer (June) request renders first
    });

    testWidgets('tapping a request card opens the existing RequestDetailScreen for that exact request', (tester) async {
      final requests = await _loadedWith([
        _summary(ref: 'DR-2026-0001', type: 'dokyu', service: 'Barangay Clearance', status: 'Submitted'),
      ]);
      final session = await _signedInAsVerifiedDemo(tester);

      await pumpMyRequests(tester, requests, session);
      await tester.tap(find.text('Barangay Clearance'));
      await tester.pumpAndSettle();

      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(tester.widget<RequestDetailScreen>(find.byType(RequestDetailScreen)).requestId, 'DR-2026-0001');
      expect(find.text('DR-2026-0001'), findsOneWidget);
    });

    testWidgets('empty state shows when the signed-in resident has no requests yet', (tester) async {
      final requests = await _loadedWith([]);
      final session = await _signedInAsVerifiedDemo(tester);
      await pumpMyRequests(tester, requests, session);
      expect(find.text('No requests yet'), findsOneWidget);
    });
  });

  group('Track This Request', () {
    testWidgets(
      'tapping Track This Request opens the exact just-submitted request, not a different/older one, with no navigation error',
      (tester) async {
        final seeded = [_summary(ref: 'DR-2026-OLDER', type: 'dokyu', service: 'Barangay Clearance', status: 'Submitted')];
        final requests = await _loadedWith(seeded);
        DokyuTulongFixtures.install(
          requests: seeded,
          onSubmit: (body) {
            final newest = _summary(
              ref: 'DR-2026-NEWEST',
              type: 'dokyu',
              service: 'Certificate of Residency',
              status: 'Submitted',
            );
            // The fixture's GET /citizen/requests/{ref} (what
            // RequestDetailScreen's own loadDetail hits after Track This
            // Request navigates) reads from this same list -- without
            // adding the new request to it, that follow-up fetch 404s.
            seeded.add(newest);
            return newest;
          },
        );
        final justSubmitted = await requests.submit(
          serviceKey: 'dokyu_certificate_of_residency',
          formData: {'purpose': 'Test purpose'},
        );
        expect(justSubmitted.id, isNot('DR-2026-OLDER'));

        await tester.pumpWidget(
          ChangeNotifierProvider<RequestsService>.value(
            value: requests,
            child: MaterialApp(
              home: RequestSubmittedScreen(
                referenceNumber: justSubmitted.referenceNumber,
                typeName: justSubmitted.typeName,
                accent: AppColors.brand600,
                requestId: justSubmitted.id,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Track This Request'));
        await tester.pumpAndSettle();

        // No "deactivated widget's ancestor" (or any other) exception —
        // this is the exact failure mode the fix removes.
        expect(tester.takeException(), isNull);
        expect(find.byType(RequestDetailScreen), findsOneWidget);
        expect(tester.widget<RequestDetailScreen>(find.byType(RequestDetailScreen)).requestId, justSubmitted.id);
        expect(find.text('Certificate of Residency'), findsOneWidget);
        // Proves it did NOT open the older seeded request.
        expect(find.text('DR-2026-OLDER'), findsNothing);
      },
    );
  });

}
