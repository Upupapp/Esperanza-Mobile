// The Dokyu and Tulong on the resident's record (GET /citizen/records,
// owner 2026-10-13): what the offices recorded for them - imported from an
// office's own files, or encoded at its counter - shows in the Dokyu and
// Tulong lists under "From the office" and on Profile's "Dokyu & Tulong
// Received", read only; nothing shows while the barangay has not yet
// confirmed the record is theirs. Made-up residents only.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/resident_record.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/profile/received_records_screen.dart';
import 'package:esperanza_mobile/screens/tulong/tulong_screen.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/widgets/segmented_tabs.dart';

import 'support/dokyu_tulong_fixtures.dart';
import 'support/fake_api.dart';

Map<String, dynamic> _record({
  required String ref,
  required String type,
  required String service,
  required String status,
  bool fromOffice = true,
  Object? amount,
  String? purpose,
  String date = '2025-08-14',
}) => {
  'ref': ref,
  'type': type,
  'service': service,
  'service_key': null,
  'office': type == 'tulong' ? 'Municipal Social Welfare and Development Office' : 'Barangay Office',
  'status': status,
  'date': date,
  'amount': amount,
  'purpose': purpose,
  'reference': fromOffice ? 'AICS-2025-0071' : null,
  'from_office': fromOffice,
  'imported': fromOffice,
};

final _records = [
  _record(ref: 'TUL-2025-00071', type: 'tulong', service: 'Medical Assistance (AICS)', status: 'Completed', amount: '3000.00', purpose: 'Hospital bill'),
  _record(ref: 'TUL-2024-00094', type: 'tulong', service: 'Food / Relief Assistance', status: 'Completed', date: '2024-11-04'),
  _record(ref: 'DOK-2025-00019', type: 'dokyu', service: 'Barangay Indigency', status: 'Released', date: '2025-03-10'),
  _record(ref: 'TUL-2026-00012', type: 'tulong', service: 'Educational Assistance', status: 'Submitted', fromOffice: false, date: '2026-10-01'),
];

Future<RequestsService> _pump(WidgetTester tester, Widget home, {List<Map<String, dynamic>> records = const []}) async {
  SharedPreferences.setMockInitialValues({});
  DokyuTulongFixtures.install(records: records);
  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last);
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
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

void main() {
  tearDown(FakeApi.restore);

  group('GET /citizen/records', () {
    test('reads each record, the office\'s and their own', () {
      final r = ResidentRecord.fromApi(_records.first)!;
      expect(r.category, ServiceCategory.tulong);
      expect(r.fromOffice, isTrue);
      expect(r.amountValue, 3000);
      expect(r.date, DateTime(2025, 8, 14));
      expect(r.source, 'Recorded by Municipal Social Welfare and Development Office');
      expect(ResidentRecord.fromApi(_records.last)!.source, 'Filed by you');
      expect(ResidentRecord.fromApi({'ref': 'INC-2026-00001', 'type': 'incident'}), isNull, reason: 'only Dokyu and Tulong');
    });

    test('nothing while the barangay has not confirmed the record, and a failure is not an error', () async {
      api = ApiClient(
        baseUrl: 'https://test.invalid',
        httpClient: MockClient((_) async => http.Response(jsonEncode({'data': [], 'meta': {'pending': true}}), 200, headers: {'content-type': 'application/json'})),
      );
      final service = RequestsService();
      await service.loadRecords();
      expect(service.records, isEmpty);
      expect(service.recordsPending, isTrue);

      api = ApiClient(baseUrl: 'https://test.invalid', httpClient: MockClient((_) async => http.Response('down', 503)));
      await service.loadRecords();
      expect(service.records, isEmpty);
      expect(service.recordsFailed, isTrue);
    });

    test('the assistance received in all counts completed Tulong only', () async {
      DokyuTulongFixtures.install(records: _records);
      final service = RequestsService();
      await service.loadRecords();
      expect(service.records, hasLength(4));
      expect(service.officeRecords(ServiceCategory.tulong).map((r) => r.ref), ['TUL-2025-00071', 'TUL-2024-00094']);
      expect(service.officeRecords(ServiceCategory.dokyu).map((r) => r.ref), ['DOK-2025-00019']);
      expect(service.assistanceReceived, 3000);
    });
  });

  testWidgets('Tulong lists the office\'s records under Done, read only', (tester) async {
    // A small phone: the record's sheet scrolls rather than cutting off rows.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const TulongScreen(), records: _records);

    // Active: none of theirs, no office records still open.
    expect(find.text('From the office'), findsNothing);
    expect(find.text('Active (0)'), findsOneWidget);
    expect(find.text('Done (2)'), findsOneWidget, reason: 'the two finished office records count under Done');

    await tester.tap(find.descendant(of: find.byType(SegmentedTabs), matching: find.text('Done (2)')));
    await tester.pumpAndSettle();
    expect(find.text('From the office'), findsOneWidget);
    expect(find.text('Medical Assistance (AICS)'), findsOneWidget);

    // Opens a sheet with all of it; nothing to act on.
    await tester.tap(find.text('Medical Assistance (AICS)'));
    await tester.pumpAndSettle();
    expect(find.text('Hospital bill'), findsOneWidget);
    expect(find.text('₱3,000.00'), findsOneWidget);
    expect(find.text('AICS-2025-0071'), findsOneWidget);
    expect(find.text('Municipal Social Welfare and Development Office'), findsOneWidget);
    await tester.tapAt(const Offset(180, 20)); // the barrier closes it
    await tester.pumpAndSettle();
    expect(find.text('Hospital bill'), findsNothing);

    // The other one, further down; a Dokyu record belongs on Dokyu.
    await tester.scrollUntilVisible(find.text('Food / Relief Assistance'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Food / Relief Assistance'), findsOneWidget);
    expect(find.text('Barangay Indigency'), findsNothing);
  });

  testWidgets('Profile\'s Dokyu & Tulong Received lists everything on the record, with the total', (tester) async {
    await _pump(tester, const ReceivedRecordsScreen(), records: _records);
    expect(find.text('Medical Assistance (AICS)'), findsOneWidget);
    expect(find.text('Barangay Indigency'), findsOneWidget);
    expect(find.text('Educational Assistance'), findsOneWidget);
    expect(find.text('Filed by you'), findsOneWidget);
    // Last in the list, below the fold on a phone.
    await tester.scrollUntilVisible(find.text('Assistance received in all: ₱3,000.00'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Assistance received in all: ₱3,000.00'), findsOneWidget);
  });

  testWidgets('Profile\'s Dokyu & Tulong Received with nothing on the record yet', (tester) async {
    await _pump(tester, const ReceivedRecordsScreen());
    expect(find.text('Nothing on your record yet'), findsOneWidget);
  });
}
