// Verifies the new Dokyu/Tulong filtering feature: the RequestFilters
// model's actual filtering/sorting logic, and that RequestListScreen's
// Filter button opens the sheet, an applied filter narrows the visible
// list with an active chip + result count, and Clear All restores it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/request_filters.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/dokyu/dokyu_screen.dart';
import 'package:esperanza_mobile/widgets/filter_bottom_sheet.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/services/balita_service.dart';

import 'support/dokyu_tulong_fixtures.dart';
import 'support/fake_api.dart';

ServiceRequest _req({
  required String type,
  required String status,
  required String office,
  required DateTime submittedAt,
}) {
  return ServiceRequest(
    id: 'req-$type-$status-${submittedAt.millisecondsSinceEpoch}',
    referenceNumber: 'DR-2026-${submittedAt.millisecondsSinceEpoch % 10000}',
    applicantId: 'ESP-1',
    applicantName: 'Test Resident',
    typeName: type,
    category: ServiceCategory.dokyu,
    office: office,
    purpose: 'Test',
    submittedAt: submittedAt,
    status: status,
    statusHistory: [StatusHistoryEntry(status: status, at: submittedAt, actor: 'Citizen')],
    attachments: const <Attachment>[],
    expectedDays: '1-2 working days',
  );
}

void main() {
  tearDown(FakeApi.restore);

  group('RequestFilters.apply (unit)', () {
    final barangayClearance = _req(
      type: 'Barangay Clearance',
      status: 'Submitted',
      office: 'Barangay Hall',
      submittedAt: DateTime(2026, 1, 10),
    );
    final cedula = _req(
      type: 'Cedula (Community Tax Certificate)',
      status: 'Approved',
      office: "Treasurer's Office",
      submittedAt: DateTime(2026, 3, 5),
    );
    final all = [barangayClearance, cedula];

    test('search matches type name or reference number (case-insensitive)', () {
      final filtered = const RequestFilters(search: 'cedula').apply(all);
      expect(filtered, [cedula]);
    });

    // scopeOfOffice itself (still used by ServiceCatalogScreen's department-
    // grouping step, against the real, populated CatalogItem.office) is no
    // longer a RequestFilters facet -- GET /citizen/requests' own list
    // shape doesn't return ServiceRequest.office at all (production-
    // readiness programme, 2026-09-25), so there's no real per-request
    // office to filter list results by anymore.
    test('scopeOfOffice distinguishes Barangay vs LGU via the office name', () {
      expect(scopeOfOffice('Barangay Hall'), RequestScope.barangay);
      expect(scopeOfOffice("Treasurer's Office"), RequestScope.lgu);
    });

    test('status filter narrows to an exact status', () {
      final filtered = const RequestFilters(status: 'Approved').apply(all);
      expect(filtered, [cedula]);
    });

    test('date range filter is inclusive of both endpoints', () {
      final filtered = RequestFilters(dateRange: DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31))).apply(all);
      expect(filtered, [barangayClearance]);
    });

    test('sort newest/oldest reorders by submittedAt', () {
      final newest = const RequestFilters(sort: RequestSort.newest).apply(all);
      expect(newest.first, cedula); // March after January
      final oldest = const RequestFilters(sort: RequestSort.oldest).apply(all);
      expect(oldest.first, barangayClearance);
    });

    test('combining filters applies all facets together (AND)', () {
      final filtered = const RequestFilters(typeName: 'Cedula (Community Tax Certificate)', status: 'Approved').apply(all);
      expect(filtered, [cedula]);
      final none = const RequestFilters(typeName: 'Barangay Clearance', status: 'Approved').apply(all);
      expect(none, isEmpty);
    });

    test('isActive/activeCount reflect only set facets, not sort', () {
      const empty = RequestFilters();
      expect(empty.isActive, isFalse);
      expect(empty.activeCount, 0);
      const withTwo = RequestFilters(search: 'x', status: 'Approved', sort: RequestSort.oldest);
      expect(withTwo.isActive, isTrue);
      expect(withTwo.activeCount, 2);
    });
  });

  group('RequestListScreen filter UI (widget)', () {
    Future<void> pumpDokyuAsVerifiedResident(WidgetTester tester, {required List<ServiceRequest> seed}) async {
      SharedPreferences.setMockInitialValues({});
      // GET /citizen/requests' own thin summary shape (ref/type/service/
      // status/submitted) -- see RequestsService._requestFromSummary. Built
      // straight from each fixture's own final status, unlike the old
      // submit()-then-mutate-in-place approach that no longer applies now
      // that submit() hits the real API.
      DokyuTulongFixtures.install(
        requests: [
          for (final r in seed)
            {
              'ref': r.referenceNumber,
              'type': r.category.name,
              'service': r.typeName,
              'status': r.status,
              'submitted': r.submittedAt.toIso8601String(),
              'office': r.office,
            },
        ],
      );
      final session = CitizenSessionService();
      await session.login(MockCatalog.demoAccounts.last); // Perlita — Approved/verified
      final requests = RequestsService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider(create: (_) => BalitaService()),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: const MaterialApp(home: DokyuScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Filter button opens the sheet; applying a status filter narrows results with an active chip', (tester) async {
      await pumpDokyuAsVerifiedResident(
        tester,
        seed: [
          _req(type: 'Barangay Clearance', status: 'Submitted', office: 'Barangay Hall', submittedAt: DateTime.now()),
          _req(type: 'Cedula (Community Tax Certificate)', status: 'Approved', office: "Treasurer's Office", submittedAt: DateTime.now()),
        ],
      );

      expect(find.text('2 results'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter'));
      await tester.pumpAndSettle();
      expect(find.text('Filter Requests'), findsOneWidget);

      // The tile beneath the sheet also shows a "Submitted" status chip —
      // scope the finder to the sheet itself so the tap lands on the
      // filter pill, not the (still-mounted, just visually covered) tile.
      await tester.tap(find.descendant(of: find.byType(FilterBottomSheet), matching: find.text('Submitted')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('1 result'), findsOneWidget);
      expect(find.text('Filter (1)'), findsOneWidget);
      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Cedula (Community Tax Certificate)'), findsNothing);

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();
      expect(find.text('2 results'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty filtered results show the "no match" empty state with Clear Filters', (tester) async {
      await pumpDokyuAsVerifiedResident(
        tester,
        seed: [_req(type: 'Barangay Clearance', status: 'Submitted', office: 'Barangay Hall', submittedAt: DateTime.now())],
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filter'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'nonexistent request type');
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('No requests match your current filters.'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
