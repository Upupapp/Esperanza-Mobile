// The Government Directory, brought level with the website's
// citizen/directory.blade.php: offices with their head, position, call and
// email; barangays (GET /barangays) with the citizen's own first; search.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/directory/directory_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/theme/app_spacing.dart';

import 'support/fake_api.dart';

Future<void> _pump(WidgetTester tester, {bool barangaysFail = false, bool signedIn = false}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final mine = MockCatalog.demoAccounts.last.barangay;
  FakeApi.installFull((r) {
    if (r.path == '/directory') {
      return [
        {
          'office': 'Office of the Mayor',
          'official_name': 'Hon. Testa Sintetiko',
          'position': 'Municipal Mayor',
          'contact': '0917 555 0100',
          'email': 'mayor@esperanza.invalid',
        },
        {'office': 'MSWDO', 'contact': 'To follow'},
        {'official_name': 'no office name: skipped'},
      ];
    }
    if (r.path == '/barangays') {
      if (barangaysFail) throw const FakeApiError(status: 503, code: 'UNAVAILABLE');
      return [
        {'name': 'Tawad', 'punong_barangay': 'Kap. Uno Dalawa', 'contact': '0917 555 0200'},
        {'name': mine, 'punong_barangay': 'Kap. Tatlo Apat', 'barangay_secretary': 'Sec. Lima Anim'},
      ];
    }
    return <dynamic>[];
  });
  final session = CitizenSessionService();
  if (signedIn) await tester.runAsync(() => session.login(MockCatalog.demoAccounts.last));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: session,
      child: const MaterialApp(home: DirectoryScreen()),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  testWidgets('an office shows its head and position, with full-size call and email', (tester) async {
    await _pump(tester);
    expect(find.text('Hon. Testa Sintetiko · Municipal Mayor'), findsOneWidget);
    final call = find.byTooltip('Call Office of the Mayor');
    final email = find.byTooltip('Email Office of the Mayor');
    expect(call, findsOneWidget);
    expect(email, findsOneWidget);
    expect(tester.getSize(call).height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
    // No number, no call button.
    expect(find.byTooltip('Call MSWDO'), findsNothing);
  });

  testWidgets('search narrows the offices', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'mayor');
    await tester.pump();
    expect(find.text('Office of the Mayor'), findsOneWidget);
    expect(find.text('MSWDO'), findsNothing);
  });

  testWidgets('the Barangays tab lists them, the citizen\'s own first', (tester) async {
    await _pump(tester, signedIn: true);
    await tester.tap(find.text('Barangays'));
    await tester.pumpAndSettle();
    final mine = MockCatalog.demoAccounts.last.barangay;
    expect(find.text('Your barangay'), findsOneWidget);
    expect(find.text('Brgy. $mine'), findsOneWidget);
    expect(find.text('Punong Barangay: Kap. Tatlo Apat'), findsOneWidget);
    expect(find.text('Secretary: Sec. Lima Anim'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Brgy. $mine')).dy, lessThan(tester.getTopLeft(find.text('Brgy. Tawad')).dy));
  });

  testWidgets('if the barangays fail, the offices still show', (tester) async {
    await _pump(tester, barangaysFail: true);
    expect(find.text('Office of the Mayor'), findsOneWidget);
    await tester.tap(find.text('Barangays'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Barangays could not be loaded'), findsOneWidget);
  });
}
