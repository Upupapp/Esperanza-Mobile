// Verifies the New Request FAB (shared by Dokyu and Tulong via
// RequestListScreen) sits clearly above the floating navbar instead of
// being partially covered by it. RequestListScreen is a Scaffold nested
// inside RootShell's own (which owns the navbar via bottomNavigationBar +
// extendBody: true) — without explicit clearance, its FAB's default
// position is measured from the true screen edge, landing it behind the
// bar. These tests drive the real post-login app shell (RootShell) at
// several viewport sizes and assert the FAB's rect never overlaps the
// navbar pill's rect, with a visible gap between them.
//
// Pumps RootShell directly (pre-logged-in, mirroring main.dart's
// _AuthGate composition) rather than going through LoginScreen's demo
// account cards — those have their own, unrelated overflow at narrow
// widths that has nothing to do with the FAB/navbar geometry under test
// here.
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
import 'package:esperanza_mobile/widgets/new_request_fab.dart';

Future<void> _dismissWelcomeBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close_rounded);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// Dokyu/Tulong no longer have their own bottom-nav slots — reaching them
/// now means tapping the center "+" launcher to open ServiceLauncherMenu,
/// then tapping the destination inside that menu. Found by its stable key
/// (`nav-center-action`, set in widgets/esperanza_curved_navbar.dart)
/// rather than by icon — the "+" is a single always-on circle now (no
/// separate inactive/active icon states to disambiguate between).
final _launcherFinder = find.byKey(const ValueKey('nav-center-action'));

Future<void> _openService(WidgetTester tester, String label) async {
  await tester.tap(_launcherFinder.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _pumpSignedInAsVerifiedDemo(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
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

/// Fails loudly (rather than silently passing) if either rect can't be
/// found, so a future navbar/FAB refactor that changes these keys/types
/// doesn't quietly stop testing anything.
void _expectFabClearsNavbar(WidgetTester tester) {
  final fabRect = tester.getRect(find.byType(NewRequestFab));
  final navbarRect = tester.getRect(find.byKey(const ValueKey('nav-bar-shape')));

  // No overlap at all — the FAB's bottom edge must sit above the navbar
  // pill's top edge.
  expect(fabRect.bottom, lessThan(navbarRect.top));
  // And with a real, visible gap — not just barely clearing by a pixel.
  expect(navbarRect.top - fabRect.bottom, greaterThanOrEqualTo(8));
  // Stayed bottom-right, not recentered — its right edge should still be
  // near the screen's right edge, not the horizontal middle.
  final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  expect(fabRect.right, greaterThan(screenWidth / 2));
}

void main() {
  // Matches the widths already validated elsewhere in this suite (see
  // nav_access_overflow_test.dart) rather than inventing new untested
  // dimensions.
  final sizes = <String, Size>{
    'small (320x568)': const Size(320, 568),
    'normal (360x800)': const Size(360, 800),
    'large (412x915)': const Size(412, 915),
  };

  for (final entry in sizes.entries) {
    testWidgets('Dokyu -> New Request FAB clears the floating navbar at ${entry.key}', (tester) async {
      await _pumpSignedInAsVerifiedDemo(tester, entry.value);

      await _openService(tester, 'Dokyu');

      _expectFabClearsNavbar(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tulong -> New Request FAB clears the floating navbar at ${entry.key}', (tester) async {
      await _pumpSignedInAsVerifiedDemo(tester, entry.value);

      await _openService(tester, 'Tulong');

      _expectFabClearsNavbar(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
