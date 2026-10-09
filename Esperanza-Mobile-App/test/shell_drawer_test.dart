// The side menu belongs to the shell, not to a tab (2026-10-09).
//
// It used to be each tab's own drawer, inside the tab's Scaffold, so it could
// only cover that tab: the floating bottom nav bar - the shell's - stayed on
// top of the open menu. And on Android 16 (predictive back) Back with the menu
// open closed the whole app instead of the menu. Both seen on the emulator.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/screens/home/root_shell.dart';
import 'package:esperanza_mobile/widgets/esperanza_curved_navbar.dart';
import 'package:esperanza_mobile/widgets/esperanza_drawer.dart';

import 'support/fake_api.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openGuestHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
  _phone(tester);
  await tester.pumpWidget(const EsperanzaMobileApp());
  await tester.pumpAndSettle();
  final guest = find.text('Continue as Guest');
  if (guest.evaluate().isNotEmpty) {
    await tester.ensureVisible(guest);
    await tester.tap(guest);
    await tester.pumpAndSettle();
  }
  final close = find.byIcon(Icons.close_rounded);
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

void main() {
  tearDown(FakeApi.restore);

  testWidgets('the menu opens over the whole shell, nav bar included', (tester) async {
    await _openGuestHome(tester);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(EsperanzaDrawer), findsOneWidget);
    // The drawer's Scaffold is the shell's - the one that also holds the nav
    // bar - so it is painted above it, not inside a tab beneath it.
    final drawerScaffold = tester.widget<Scaffold>(
      find.ancestor(of: find.byType(EsperanzaDrawer), matching: find.byType(Scaffold)).first,
    );
    expect(drawerScaffold.bottomNavigationBar, isA<EsperanzaCurvedNavBar>());
    expect(find.ancestor(of: find.byType(EsperanzaDrawer), matching: find.byType(RootShell)), findsOneWidget);
  });

  testWidgets('Back closes the open menu, not the app', (tester) async {
    await _openGuestHome(tester);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(EsperanzaDrawer), findsOneWidget);

    // The system Back button, as Android delivers it.
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue, reason: 'Back fell through to the platform: the app would have closed');
    expect(find.byType(EsperanzaDrawer), findsNothing);
    expect(find.byType(RootShell), findsOneWidget);
  });

  testWidgets('with the menu open, the app tells Android it handles Back', (tester) async {
    // Android 16's predictive back asks the app up front whether it will take
    // Back (SystemNavigator.setFrameworkHandlesBack). Answering "no" while the
    // menu is open is what closed the app on the emulator; the plain pop test
    // above cannot see that, because the test harness skips this handshake.
    final handles = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.setFrameworkHandlesBack') handles.add(call.arguments as bool);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await _openGuestHome(tester);
    // WidgetsApp only tells the engine once the app is resumed; the test
    // binding starts with no lifecycle state at all.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    handles.clear();
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(handles, isNotEmpty, reason: "opening the menu never told Android that Back is the app's");
    expect(handles.last, isTrue);
  });

  testWidgets('every tab opens the same shell menu', (tester) async {
    await _openGuestHome(tester);
    // Balita: its AppBar's menu button.
    await tester.tap(find.descendant(of: find.byType(EsperanzaCurvedNavBar), matching: find.text('Balita')));
    await tester.pumpAndSettle();
    // Each tab's first-visit promotional pop-up, if it shows.
    final close = find.byIcon(Icons.close_rounded);
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    // The shell keeps every tab built (an IndexedStack): the visible one's.
    await tester.tap(find.byType(ShellMenuButton).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(EsperanzaDrawer), findsOneWidget);
  });
}
