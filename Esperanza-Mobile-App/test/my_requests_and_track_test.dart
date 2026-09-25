// Coverage for: the new "My Requests" hamburger screen, the Tulong
// status-based reapplication rule, and the "Track This Request" fix (it
// must open the exact just-submitted request, never a stale/wrong one).
//
// Dokyu's own "repeat-request rule" (no cap on how many times the same
// document can be requested) used to have its own group here, submitting
// the same service 4 times through RequestsService directly and checking
// each got its own reference number. That was really exercising the fake
// backend's willingness to accept duplicates, not any mobile-side logic --
// there is no Dokyu-side gate to test (unlike Tulong's tulongEligibilityFor,
// Dokyu genuinely has none), so it added no coverage beyond what the "Track
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
import 'package:esperanza_mobile/utils/tulong_eligibility.dart';
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
/// [RequestsService] that has loaded them.
Future<RequestsService> _loadedWith(WidgetTester tester, List<Map<String, dynamic>> seeded) async {
  SharedPreferences.setMockInitialValues({});
  DokyuTulongFixtures.install(requests: seeded);
  final requests = RequestsService();
  await requests.loadRequests();
  return requests;
}

void main() {
  tearDown(FakeApi.restore);

  group('Tulong reapplication rule — status-based, per assistance type', () {
    testWidgets('Case A — no previous application for this assistance is eligible', (tester) async {
      final requests = await _loadedWith(tester, []);
      final result = tulongEligibilityFor(requests, typeName: 'Medical Assistance (AICS)');
      expect(result.isEligible, isTrue);
      expect(result.blockingRequest, isNull);
    });

    for (final activeStatus in [
      'Submitted',
      'Pending Review',
      'Under Verification',
      'Assigned',
      'Processing',
      'Under Review',
      'Resubmitted',
      'Approved',
    ]) {
      testWidgets('Case B/C — a "$activeStatus" application for this assistance blocks a new one', (tester) async {
        final requests = await _loadedWith(tester, [
          _summary(ref: 'AR-2026-0001', type: 'tulong', service: 'Medical Assistance (AICS)', status: activeStatus),
        ]);
        final result = tulongEligibilityFor(requests, typeName: 'Medical Assistance (AICS)');
        expect(result.isEligible, isFalse);
        expect(result.blockingRequest?.referenceNumber, 'AR-2026-0001');
      });
    }

    testWidgets('Case C — Mark to Release/Released also block a new application', (tester) async {
      for (final status in ['Mark to Release', 'Released']) {
        final requests = await _loadedWith(tester, [
          _summary(ref: 'AR-2026-0001', type: 'tulong', service: 'Medical Assistance (AICS)', status: status),
        ]);
        final result = tulongEligibilityFor(requests, typeName: 'Medical Assistance (AICS)');
        expect(result.isEligible, isFalse, reason: 'status=$status');
        expect(result.status, TulongEligibility.blockedReceived, reason: 'status=$status');
      }
    });

    testWidgets('Case D — a Rejected application allows reapplying to the same assistance', (tester) async {
      final requests = await _loadedWith(tester, [
        _summary(ref: 'AR-2026-0001', type: 'tulong', service: 'Medical Assistance (AICS)', status: 'Rejected'),
      ]);
      final result = tulongEligibilityFor(requests, typeName: 'Medical Assistance (AICS)');
      expect(result.isEligible, isTrue);
    });

    testWidgets('a Cancelled application also allows reapplying', (tester) async {
      final requests = await _loadedWith(tester, [
        _summary(ref: 'AR-2026-0001', type: 'tulong', service: 'Medical Assistance (AICS)', status: 'Cancelled'),
      ]);
      final result = tulongEligibilityFor(requests, typeName: 'Medical Assistance (AICS)');
      expect(result.isEligible, isTrue);
    });

    testWidgets('the restriction is per assistance type — an active Medical Assistance never blocks Educational Assistance', (
      tester,
    ) async {
      final requests = await _loadedWith(tester, [
        _summary(ref: 'AR-2026-0001', type: 'tulong', service: 'Medical Assistance (AICS)', status: 'Pending Review'),
      ]);
      expect(tulongEligibilityFor(requests, typeName: 'Medical Assistance (AICS)').isEligible, isFalse);
      expect(tulongEligibilityFor(requests, typeName: 'Educational Assistance').isEligible, isTrue);
    });
  });

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
      final requests = await _loadedWith(tester, [
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
      final requests = await _loadedWith(tester, [
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
      final requests = await _loadedWith(tester, [
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
      final requests = await _loadedWith(tester, []);
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
        final requests = await _loadedWith(tester, seeded);
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

  group('Tulong blocked-application dialog', () {
    // Exercises showTulongBlockedDialog directly — the exact same helper
    // ServiceCatalogScreen (early detection), NewRequestScreen, and
    // ServiceRequestWizardScreen all now call once tulongEligibilityFor
    // reports a block.
    Future<void> pumpGate(
      WidgetTester tester,
      RequestsService requests,
      CitizenSessionService session, {
      required String typeName,
    }) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = tulongEligibilityFor(requests, typeName: typeName);
                      if (result.isEligible) return;
                      final viewRequest = await showTulongBlockedDialog(context, result);
                      if (viewRequest && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: result.blockingRequest!.id)),
                        );
                      }
                    },
                    child: const Text('Attempt Submit'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an active application shows "Active Application Exists" with View Existing Request / Close', (
      tester,
    ) async {
      final requests = await _loadedWith(tester, [
        _summary(ref: 'AR-2026-ACTIVE', type: 'tulong', service: 'Medical Assistance (AICS)', status: 'Submitted'),
      ]);
      final session = await _signedInAsVerifiedDemo(tester);

      await pumpGate(tester, requests, session, typeName: 'Medical Assistance (AICS)');
      await tester.tap(find.text('Attempt Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Active Application Exists'), findsOneWidget);
      expect(find.text('You already have an active application for this assistance.'), findsOneWidget);
      expect(find.text('View Existing Request'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('View Existing Request'));
      await tester.pumpAndSettle();
      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(tester.widget<RequestDetailScreen>(find.byType(RequestDetailScreen)).requestId, 'AR-2026-ACTIVE');
    });

    testWidgets('an already-received assistance shows "Assistance Already Received" with View Previous Request / Close', (
      tester,
    ) async {
      final requests = await _loadedWith(tester, [
        _summary(ref: 'AR-2026-0001', type: 'tulong', service: 'Medical Assistance (AICS)', status: 'Approved'),
      ]);
      final session = await _signedInAsVerifiedDemo(tester);

      await pumpGate(tester, requests, session, typeName: 'Medical Assistance (AICS)');
      await tester.tap(find.text('Attempt Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Assistance Already Received'), findsOneWidget);
      expect(
        find.text(
          'You have already received this assistance and cannot submit another application for the same '
          'assistance at this time.',
        ),
        findsOneWidget,
      );
      expect(find.text('View Previous Request'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Assistance Already Received'), findsNothing);
      expect(find.byType(RequestDetailScreen), findsNothing);
    });

    testWidgets('does not gate a rejected-only history — Attempt Submit proceeds with no dialog', (tester) async {
      final requests = await _loadedWith(tester, [
        _summary(ref: 'AR-2026-0002', type: 'tulong', service: 'Medical Assistance (AICS)', status: 'Rejected'),
      ]);
      final session = await _signedInAsVerifiedDemo(tester);

      await pumpGate(tester, requests, session, typeName: 'Medical Assistance (AICS)');
      await tester.tap(find.text('Attempt Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Active Application Exists'), findsNothing);
      expect(find.text('Assistance Already Received'), findsNothing);
    });
  });
}
