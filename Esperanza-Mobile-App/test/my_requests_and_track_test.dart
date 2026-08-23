// Coverage for: the new "My Requests" hamburger screen, the Dokyu
// (unlimited) vs Tulong (max 2 per exact assistance) repeat-request rules,
// and the "Track This Request" fix (it must open the exact
// just-submitted request, never a stale/wrong one).
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/my_requests_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_submitted_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/utils/tulong_application_limit.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:esperanza_mobile/widgets/app_dialogs.dart';
import 'package:esperanza_mobile/widgets/segmented_tabs.dart';

Future<RequestsService> _loaded(WidgetTester tester, {bool seedDemoData = false}) async {
  SharedPreferences.setMockInitialValues({});
  final requests = RequestsService(seedDemoData: seedDemoData);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

Future<CitizenSessionService> _signedInAsCristy(WidgetTester tester) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last); // Cristy — verified
  return session;
}

const _cristyId = 'ESP-RES-2024-1044';
const _cristyName = 'Cristy Bonghanoy';

Future<ServiceRequest> _submitDokyu(RequestsService requests, {String typeName = 'Barangay Clearance'}) {
  return requests.submit(
    applicantId: _cristyId,
    applicantName: _cristyName,
    typeName: typeName,
    category: ServiceCategory.dokyu,
    office: 'Barangay Hall',
    purpose: 'Test purpose',
    expectedDays: '1-2 working days',
    attachments: const [],
  );
}

Future<ServiceRequest> _submitTulong(RequestsService requests, {String typeName = 'Medical Assistance (AICS)'}) {
  return requests.submit(
    applicantId: _cristyId,
    applicantName: _cristyName,
    typeName: typeName,
    category: ServiceCategory.tulong,
    office: 'Municipal Social Welfare and Development Office',
    purpose: 'Test purpose',
    expectedDays: '3-5 working days',
    attachments: const [],
  );
}

void main() {
  group('Dokyu repeat-request rule — unlimited', () {
    testWidgets('the same Dokyu service can be requested any number of times, each with its own reference number', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      final r1 = await _submitDokyu(requests);
      final r2 = await _submitDokyu(requests);
      final r3 = await _submitDokyu(requests);
      final r4 = await _submitDokyu(requests);

      final refs = {r1.referenceNumber, r2.referenceNumber, r3.referenceNumber, r4.referenceNumber};
      expect(refs.length, 4); // every reference number is unique
      expect(requests.all.where((r) => r.typeName == 'Barangay Clearance').length, 4);
      // Older requests are preserved independently, never overwritten.
      expect(requests.all.any((r) => r.id == r1.id), isTrue);
      expect(requests.all.any((r) => r.id == r2.id), isTrue);
    });
  });

  group('Tulong repeat-application rule — max 2 per exact assistance', () {
    testWidgets('counts real submitted records: 0 before submitting, 1 after the first, 2 after the second', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      expect(
        tulongApplicationCountFor(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'),
        0,
      );
      await _submitTulong(requests);
      expect(
        tulongApplicationCountFor(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'),
        1,
      );
      expect(hasReachedTulongApplicationLimit(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'), isFalse);
      await _submitTulong(requests);
      expect(
        tulongApplicationCountFor(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'),
        2,
      );
      expect(hasReachedTulongApplicationLimit(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'), isTrue);
    });

    testWidgets('the limit is per assistance type — 2x Medical Assistance never blocks Educational Assistance', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      await _submitTulong(requests, typeName: 'Medical Assistance (AICS)');
      await _submitTulong(requests, typeName: 'Medical Assistance (AICS)');
      expect(hasReachedTulongApplicationLimit(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'), isTrue);
      expect(
        hasReachedTulongApplicationLimit(requests, applicantId: _cristyId, typeName: 'Educational Assistance'),
        isFalse,
      );
    });

    testWidgets('a Cancelled application does not count toward the limit', (tester) async {
      final requests = await _loaded(tester);
      final r1 = await _submitTulong(requests);
      await _submitTulong(requests);
      await requests.cancel(r1.id);
      // One of the two was cancelled — only 1 now counts, so a third
      // genuine submission must still be allowed.
      expect(
        tulongApplicationCountFor(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'),
        1,
      );
      expect(hasReachedTulongApplicationLimit(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'), isFalse);
    });

    testWidgets('the count is scoped per resident — another account applying for the same assistance is separate', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      await _submitTulong(requests); // Cristy #1
      await requests.submit(
        applicantId: 'ESP-RES-2024-1102', // Ronaldo — a different resident entirely
        applicantName: 'Ronaldo Bautista',
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        purpose: 'Test purpose',
        expectedDays: '3-5 working days',
        attachments: const [],
      );
      expect(
        tulongApplicationCountFor(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'),
        1,
      );
      expect(
        tulongApplicationCountFor(requests, applicantId: 'ESP-RES-2024-1102', typeName: 'Medical Assistance (AICS)'),
        1,
      );
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
      final requests = await _loaded(tester);
      final session = await _signedInAsCristy(tester);

      await _submitDokyu(requests, typeName: 'Barangay Clearance');
      await _submitTulong(requests, typeName: 'Medical Assistance (AICS)');

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

    testWidgets('sorts newest submission first, using deterministic pre-seeded timestamps', (tester) async {
      // Real back-to-back submit() calls can land within the same
      // OS-clock tick on Windows, making DateTime.now()-based ordering
      // flaky — pre-seed two requests with explicit, unambiguous
      // submittedAt values instead of relying on real-time gaps between
      // calls.
      final older = ServiceRequest(
        id: 'req-older',
        referenceNumber: 'DR-2026-0001',
        applicantId: _cristyId,
        applicantName: _cristyName,
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Test',
        submittedAt: DateTime(2026, 1, 1),
        status: 'Submitted',
        statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 1, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '1-2 working days',
      );
      final newer = ServiceRequest(
        id: 'req-newer',
        referenceNumber: 'AR-2026-0001',
        applicantId: _cristyId,
        applicantName: _cristyName,
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        purpose: 'Test',
        submittedAt: DateTime(2026, 6, 1),
        status: 'Submitted',
        statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 6, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '3-5 working days',
      );
      SharedPreferences.setMockInitialValues({
        'esperanza_service_requests': jsonEncode([older.toJson(), newer.toJson()]),
      });
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
      while (!requests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      final session = await _signedInAsCristy(tester);

      await pumpMyRequests(tester, requests, session);

      final firstCardText = tester
          .widgetList<Text>(find.descendant(of: find.byType(ListView), matching: find.byType(Text)))
          .elementAt(1) // index 0 is the category badge; index 1 is the service name
          .data;
      expect(firstCardText, 'Medical Assistance (AICS)'); // the newer (June) request renders first
    });

    testWidgets('tapping a request card opens the existing RequestDetailScreen for that exact request', (tester) async {
      final requests = await _loaded(tester);
      final session = await _signedInAsCristy(tester);
      final submitted = await _submitDokyu(requests);

      await pumpMyRequests(tester, requests, session);
      await tester.tap(find.text('Barangay Clearance'));
      await tester.pumpAndSettle();

      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(tester.widget<RequestDetailScreen>(find.byType(RequestDetailScreen)).requestId, submitted.id);
      expect(find.text(submitted.referenceNumber), findsOneWidget);
    });

    testWidgets('account scoping — Ronaldo does not see Cristy\'s requests, and vice versa', (tester) async {
      final requests = await _loaded(tester);
      await _submitDokyu(requests); // Cristy's
      await requests.submit(
        applicantId: 'ESP-RES-2024-1102',
        applicantName: 'Ronaldo Bautista',
        typeName: 'Certificate of Residency',
        category: ServiceCategory.dokyu,
        office: 'Civil Registrar',
        purpose: 'Test purpose',
        expectedDays: '1-2 working days',
        attachments: const [],
      );

      final ronaldoSession = CitizenSessionService();
      var attempts = 0;
      while (ronaldoSession.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await ronaldoSession.login(MockCatalog.demoAccounts.first); // Ronaldo

      await pumpMyRequests(tester, requests, ronaldoSession);
      expect(find.text('Certificate of Residency'), findsOneWidget);
      expect(find.text('Barangay Clearance'), findsNothing); // Cristy's own request never leaks in
    });

    testWidgets('empty state shows when the signed-in resident has no requests yet', (tester) async {
      final requests = await _loaded(tester);
      final session = await _signedInAsCristy(tester);
      await pumpMyRequests(tester, requests, session);
      expect(find.text('No requests yet'), findsOneWidget);
    });
  });

  group('Track This Request', () {
    testWidgets(
      'tapping Track This Request opens the exact just-submitted request, not a different/older one, with no navigation error',
      (tester) async {
        final requests = await _loaded(tester);
        final older = await _submitDokyu(requests, typeName: 'Barangay Clearance');
        // A real (not fake-clock) gap — submit()'s id is derived from
        // DateTime.now().microsecondsSinceEpoch, which two back-to-back
        // calls can otherwise collide on.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        final justSubmitted = await _submitDokyu(requests, typeName: 'Certificate of Residency');
        expect(justSubmitted.id, isNot(older.id));

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
        // Proves it did NOT open the older seeded/other request.
        expect(find.text(older.referenceNumber), findsNothing);
      },
    );
  });

  group('Application Limit Reached dialog', () {
    // Exercises the exact same sequence _submit() in new_request_screen.dart
    // / service_request_wizard_screen.dart runs once the limit is reached —
    // AppDialogs.confirm with this title/message/buttons, then a push to
    // MyRequestsScreen only if "View My Requests" was chosen.
    Future<void> pumpGate(WidgetTester tester, RequestsService requests, CitizenSessionService session) async {
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
                      if (!hasReachedTulongApplicationLimit(
                        requests,
                        applicantId: _cristyId,
                        typeName: 'Medical Assistance (AICS)',
                      )) {
                        return;
                      }
                      final viewRequests = await AppDialogs.confirm(
                        context,
                        title: 'Application Limit Reached',
                        message:
                            'You have already submitted two applications for this assistance. You cannot submit another '
                            'application for the same assistance at this time.',
                        confirmLabel: 'View My Requests',
                        cancelLabel: 'Close',
                      );
                      if (viewRequests && context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyRequestsScreen()));
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

    testWidgets('shows the exact required title/message/buttons on a third attempt, and Close just dismisses it', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      final session = await _signedInAsCristy(tester);
      await _submitTulong(requests);
      await _submitTulong(requests);

      await pumpGate(tester, requests, session);
      await tester.tap(find.text('Attempt Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Application Limit Reached'), findsOneWidget);
      expect(
        find.text(
          'You have already submitted two applications for this assistance. You cannot submit another '
          'application for the same assistance at this time.',
        ),
        findsOneWidget,
      );
      expect(find.text('View My Requests'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Application Limit Reached'), findsNothing);
      expect(find.byType(MyRequestsScreen), findsNothing);
      // No third application was ever recorded.
      expect(
        tulongApplicationCountFor(requests, applicantId: _cristyId, typeName: 'Medical Assistance (AICS)'),
        2,
      );
    });

    testWidgets('"View My Requests" opens My Requests and shows the two prior Tulong applications', (tester) async {
      final requests = await _loaded(tester);
      final session = await _signedInAsCristy(tester);
      await _submitTulong(requests);
      await _submitTulong(requests);

      await pumpGate(tester, requests, session);
      await tester.tap(find.text('Attempt Submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View My Requests'));
      await tester.pumpAndSettle();

      expect(find.byType(MyRequestsScreen), findsOneWidget);
      expect(find.text('Medical Assistance (AICS)'), findsWidgets); // both prior applications preserved
    });

    testWidgets('does not gate a second, still-allowed application', (tester) async {
      final requests = await _loaded(tester);
      final session = await _signedInAsCristy(tester);
      await _submitTulong(requests); // only 1 so far — the gate must not trigger

      await pumpGate(tester, requests, session);
      await tester.tap(find.text('Attempt Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Application Limit Reached'), findsNothing);
    });
  });
}
