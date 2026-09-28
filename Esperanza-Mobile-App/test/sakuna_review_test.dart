// The Emergency tab's review: published emergency alerts (public GET
// /alerts) that never reached the app, and evacuation centres that did not
// say whether they were open.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/sakuna/sakuna_screen.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/services/sakuna_alerts.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _alert({List<String> barangays = const []}) => {
  'ref': 'ALT-2026-0007',
  'type': 'Typhoon',
  'level': 'Signal No. 2',
  'title': {'fil': 'Bagyong Ompong: Signal No. 2', 'en': 'Typhoon Ompong: Signal No. 2'},
  'body': {'fil': 'Maghanda sa paglikas.', 'en': 'Prepare to evacuate.'},
  'barangays': barangays,
  'published_at': '2026-09-28T01:00:00Z',
};

Future<List<FakeApiRequest>> _pump(
  WidgetTester tester,
  dynamic Function(FakeApiRequest) alerts, {
  bool signedIn = false,
}) async {
  final sent = <FakeApiRequest>[];
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  FakeApi.installFull((r) {
    sent.add(r);
    return switch (r.path) {
      '/alerts' => alerts(r),
      '/sakuna/centers' => [
        {
          'name': 'Poblacion Covered Court',
          'barangay': 'Poblacion',
          'address': 'J.P. Rizal St.',
          'capacity': 300,
          'individuals': 120,
          'status': 'Processing',
        },
        {'name': 'Tawad Chapel', 'barangay': 'Tawad', 'capacity': 80, 'status': 'Archived'},
      ],
      _ => <dynamic>[],
    };
  });
  final session = CitizenSessionService();
  if (signedIn) await tester.runAsync(() => session.login(MockCatalog.demoAccounts.last));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: const MaterialApp(home: SakunaScreen()),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
  return sent;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  test('an alert is read in Filipino first; a row without a ref or title is skipped', () async {
    FakeApi.installFull(
      (r) => [
        _alert(),
        {'ref': 'ALT-X'},
      ],
    );
    final alerts = await SakunaAlerts.load();
    expect(alerts, hasLength(1));
    expect(alerts.single.title, 'Bagyong Ompong: Signal No. 2');
  });

  testWidgets('a published alert is at the top of the Emergency tab', (tester) async {
    await _pump(
      tester,
      (_) => [
        _alert(barangays: ['Baras']),
      ],
    );
    expect(find.text('Active Alerts'), findsOneWidget);
    expect(find.text('Typhoon · Signal No. 2'), findsOneWidget);
    expect(find.text('Bagyong Ompong: Signal No. 2'), findsOneWidget);
    expect(find.textContaining('Brgy. Baras'), findsWidgets);
    expect(
      tester.getTopLeft(find.text('Bagyong Ompong: Signal No. 2')).dy,
      lessThan(tester.getTopLeft(find.text('Report an Incident')).dy),
    );
  });

  testWidgets('a signed-in citizen is asked for their own barangay\'s alerts', (tester) async {
    final sent = await _pump(tester, (_) => <dynamic>[], signedIn: true);
    final request = sent.firstWhere((r) => r.path == '/alerts');
    expect(request.query['barangay'], MockCatalog.demoAccounts.last.barangay);
    expect(find.text('No emergency alerts in force right now.'), findsOneWidget);
  });

  testWidgets('an alert feed that fails does not take the hotlines and centres with it', (tester) async {
    await _pump(tester, (_) => throw const FakeApiError(status: 503, code: 'UNAVAILABLE'));
    expect(find.text('Emergency alerts could not be checked.'), findsOneWidget);
    expect(find.text('Poblacion Covered Court'), findsOneWidget);
  });

  testWidgets('each centre says whether it is open, and shows its address', (tester) async {
    await _pump(tester, (_) => <dynamic>[]);
    expect(find.text('Open now'), findsOneWidget);
    expect(find.text('Not open'), findsOneWidget);
    expect(find.textContaining('J.P. Rizal St.'), findsOneWidget);
  });
}
