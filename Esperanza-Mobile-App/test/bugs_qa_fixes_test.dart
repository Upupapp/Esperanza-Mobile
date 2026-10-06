// "Esperanza bugs QA" (2026-10-06): what a tester found on the phone, pinned
// so it cannot come back. Synthetic data only (this repository is public).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/my_requests_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_list_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notification_feed.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';

import 'support/fake_api.dart';

const _ref = 'DOK-2026-00901';

Map<String, dynamic> _detail({String status = 'Under Verification'}) => {
  'ref': _ref,
  'type': 'dokyu',
  'service': 'Barangay Certification (Synthetic)',
  'status': status,
  'submitted': '2026-10-06T00:00:00Z',
  'office': 'Barangay Office',
  'requirements': [
    {
      'key': 'req_1',
      'label': 'Valid ID',
      'status': 'Approved',
      'attachable': false,
      'file': {'name': 'synthetic-id.pdf', 'mime': 'application/pdf', 'bytes': 2048, 'url': null, 'uploaded_at': '2026-10-06T01:00:00Z'},
    },
    {'key': 'req_2', 'label': 'Cedula', 'status': 'Pending Review', 'attachable': true, 'file': null},
    {'key': 'req_3', 'label': 'Brief interview / social case study with MSWDO', 'status': 'Pending Review', 'attachable': true, 'file': null},
  ],
  'history': [
    {'to': 'Submitted', 'at': '2026-10-06T00:00:00Z'},
  ],
};

Future<void> _pumpDetail(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final requests = RequestsService();
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    if (++attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
      ],
      child: const MaterialApp(home: RequestDetailScreen(requestId: _ref)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(FakeApi.restore);

  testWidgets('an accepted document stays on the list, in green, with no Replace', (tester) async {
    FakeApi.installFull((req) => _detail());
    await _pumpDetail(tester);

    expect(find.text('Valid ID'), findsOneWidget, reason: 'it is not dropped once accepted');
    expect(find.text('Accepted by the office · synthetic-id.pdf'), findsOneWidget);
    expect(find.textContaining('1 of 3 accepted by the office.'), findsOneWidget);
    // Each open document says whether it is owed; the interview has nothing to upload.
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Done at the office'), findsOneWidget);
    expect(find.text('Nothing to upload: the office does this with you.'), findsOneWidget);
    expect(find.textContaining('1 required document still needs to be attached.'), findsOneWidget);
  });

  testWidgets('the open request re-reads itself, so an approval shows without a restart', (tester) async {
    var calls = 0;
    FakeApi.installFull((req) {
      calls++;
      return _detail(status: calls > 1 ? 'Approved' : 'Under Verification');
    });
    await _pumpDetail(tester);
    expect(find.text('Under Verification'), findsWidgets);

    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(calls, greaterThan(1));
    expect(find.text('Approved'), findsWidgets);
  });

  testWidgets('My Requests reads the list when opened, and again when pulled down', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    Map<String, dynamic> row(String ref) =>
        {'ref': ref, 'type': 'dokyu', 'service': 'Barangay Certification (Synthetic)', 'status': 'Submitted', 'submitted': '2026-10-06T00:00:00Z'};
    FakeApi.installFull((r) {
      if (r.path == '/citizen/requests') {
        calls++;
        return [row('DOK-2026-00901'), if (calls > 1) row('DOK-2026-00902')];
      }
      throw const FakeApiError(messageEn: 'not configured');
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => RequestsService())],
        child: const MaterialApp(home: MyRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1, reason: 'opening the screen reads the list, not the copy loaded at start-up');
    expect(find.text('DOK-2026-00901'), findsOneWidget);
    expect(find.text('DOK-2026-00902'), findsNothing);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'pulling down reads it again');
    expect(find.text('DOK-2026-00902'), findsOneWidget, reason: 'a request filed on the website meanwhile shows up');
  });

  test('an incident update opens the incident, read or not', () {
    final n = ServerNotification(
      id: 1,
      category: 'sakuna',
      title: 'Papunta na ang tulong',
      body: 'b',
      pill: 'Processing',
      ref: 'INC-2026-00901',
      unread: false,
      pinned: false,
      at: DateTime(2026, 10, 6),
    );
    final d = serverNotificationDestination(n);
    expect(d, isA<RequestDetailScreen>());
    expect((d! as RequestDetailScreen).requestId, 'INC-2026-00901');
  });

  testWidgets('Incident Reports opened from Sakuna has a way back', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RequestsService()),
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: const MaterialApp(
          home: RequestListScreen(
            category: ServiceCategory.sakunaIncident,
            title: 'Incident Reports',
            subtitle: 's',
            catalog: [],
            accent: AppColors.rose600,
            icon: Icons.report_outlined,
            pushed: true,
          ),
        ),
      ),
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.drawer, isNull, reason: 'a drawer replaces the back arrow');
  });
}
