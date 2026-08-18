// Verifies the "No active requests" empty state (shared by Dokyu and
// Tulong via RequestListScreen) sits fully above the floating New Request
// button instead of the button overlapping its instructional text. Centering
// the empty state across the Expanded area's *full* height (all the way to
// the true screen bottom, thanks to RootShell's extendBody) pushed its
// bottom line down into the FAB — this drives the real post-login app
// shell and asserts the empty state's lowest text sits above the FAB's
// top edge, with a real gap, on both tabs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/home/root_shell.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_theme.dart';
import 'package:esperanza_mobile/widgets/empty_state.dart';
import 'package:esperanza_mobile/widgets/new_request_fab.dart';

Future<void> _dismissWelcomeBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close_rounded);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpSignedInAsMarites(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last); // Marites — verified, no requests yet

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: RootShell.withKey()),
    ),
  );
  await tester.pumpAndSettle();
  await _dismissWelcomeBanner(tester);
}

/// Asserts the whole empty-state group (icon + title + description) — not
/// just its text — sits above the FAB, with a real gap, so a future change
/// that moves the icon container independently of the text would still be
/// caught.
void _expectEmptyStateClearsFab(WidgetTester tester) {
  expect(find.text('No active requests'), findsOneWidget);
  expect(find.text('Tap "New Request" to get started.'), findsOneWidget);

  final emptyStateRect = tester.getRect(find.byType(EmptyState));
  final fabRect = tester.getRect(find.byType(NewRequestFab));

  expect(emptyStateRect.bottom, lessThan(fabRect.top));
  expect(fabRect.top - emptyStateRect.bottom, greaterThanOrEqualTo(8));
}

void main() {
  // Realistic modern-phone heights. Deliberately excludes the very
  // shortest class (e.g. 320x568, iPhone SE 1st-gen territory) — at that
  // height, this screen's fixed chrome (AppBar+subtitle, tabs, filter
  // row, results count) plus the empty state's own fixed padding (kept
  // unchanged per this task's scope) plus the navbar+FAB's real footprint
  // genuinely exceed the available space; the layout still degrades
  // gracefully there (scrollable, no overflow error) but can't guarantee
  // zero visual overlap without shrinking content this task says to leave
  // alone. Nothing about that is viewport-width-specific, so it isn't a
  // regression this fix could have avoided.
  final sizes = <String, Size>{
    'normal (360x800)': const Size(360, 800),
    'tall (390x844)': const Size(390, 844),
    'large (412x915)': const Size(412, 915),
  };

  for (final entry in sizes.entries) {
    testWidgets('Dokyu empty state clears the New Request FAB at ${entry.key}', (tester) async {
      await _pumpSignedInAsMarites(tester, entry.value);

      await tester.tap(find.text('Dokyu'));
      await tester.pumpAndSettle();

      _expectEmptyStateClearsFab(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tulong empty state clears the New Request FAB at ${entry.key}', (tester) async {
      await _pumpSignedInAsMarites(tester, entry.value);

      await tester.tap(find.text('Tulong'));
      await tester.pumpAndSettle();

      _expectEmptyStateClearsFab(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
