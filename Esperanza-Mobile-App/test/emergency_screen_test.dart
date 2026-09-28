// The Emergency tab's hotlines and evacuation centres, held to the design
// standard: a hotline is one full-size call target (44pt), and a centre
// shows its live headcount when the backend has one.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/sakuna/sakuna_screen.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_spacing.dart';

import 'support/fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  testWidgets('hotlines are full-size call targets; centres show live occupancy', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    FakeApi.installFull((r) => switch (r.path) {
      '/hotlines' => [
        {'office': 'Esperanza Police Station', 'contact': '0917 123 4567 / 0998 765 4321'},
        {'office': 'Evacuation desk', 'contact': 'To follow'},
      ],
      '/sakuna/centers' => [
        {'name': 'Poblacion Covered Court', 'barangay': 'Poblacion', 'capacity': 300, 'individuals': 120},
        {'name': 'Tawad Chapel', 'barangay': 'Tawad', 'capacity': 80},
      ],
      _ => <dynamic>[],
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(create: (_) => RequestsService()),
          ChangeNotifierProvider(create: (_) => BalitaService()),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: const MaterialApp(home: SakunaScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final call = find.bySemanticsLabel(RegExp(r'^Call Esperanza Police Station'));
    expect(call, findsOneWidget);
    expect(tester.getSize(call).height, greaterThanOrEqualTo(AppSizes.minTouchTarget));

    // No number, no call action.
    expect(find.bySemanticsLabel(RegExp(r'^Call Evacuation desk')), findsNothing);
    expect(find.text('To follow'), findsOneWidget);

    // Each hotline is its own node, not merged into the section around it.
    expect(tester.getSemantics(call).label, startsWith('Call Esperanza Police Station'));
    expect(tester.getSemantics(find.text('Evacuation Centers')).flagsCollection.isButton, isFalse);

    expect(find.textContaining('120 of 300 occupied'), findsOneWidget);
    expect(find.textContaining('Capacity: 80'), findsOneWidget);
    semantics.dispose();
  });
}
