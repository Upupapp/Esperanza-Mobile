// Regression coverage for a real bug: several auth-adjacent buttons used
// `Navigator.pushAndRemoveUntil(MaterialPageRoute(...), (route) => false)`,
// which removes *every* route including the app's root route — the one
// that hosts `_AuthGate` (main.dart), the single place that reactively
// swaps between LoginScreen/RootShell based on CitizenSessionService.
// Once that root route is gone, any *later* login()/logout() has nothing
// left listening, so the app gets stuck on whatever screen was showing —
// this is what made the Ronaldo/Marites demo accounts appear to "stop
// opening" when reached via Guest -> Sign In, a restricted-feature
// notice's Sign In button, or a fresh registration's "Continue to App".
// These tests drive those exact paths end-to-end through the real app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Home shows the promotional HomeWelcomeBanner pop-up once per RootShell
/// instance, right after Home first loads — dismiss it before any further
/// interaction, the same way a real user would, otherwise the modal
/// barrier intercepts the next tap. A fresh sign-in creates a fresh
/// RootShell (and thus a fresh HomeScreen `initState`), so this needs
/// calling again after every new login, not just the first.
Future<void> _dismissWelcomeBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close_rounded);
  if (closeButton.evaluate().isNotEmpty) {
    // warnIfMissed: false — Icon widgets are painted leaves, not hit-test
    // targets themselves (the enclosing IconButton is), so tapping one
    // reliably prints a benign "would not hit test on the specified
    // widget" warning even though the tap correctly reaches the button.
    await tester.tap(closeButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('Guest -> drawer "Sign In" -> Ronaldo Bautista reaches Home, not stuck on LoginScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Continue as Guest'));
    await _dismissWelcomeBanner(tester);
    expect(find.textContaining('Welcome, Guest'), findsOneWidget);

    // Open the hamburger drawer and tap "Sign In" — this is the exact
    // path that used to orphan _AuthGate. The Guest home hero has its
    // own "Sign In" button too, so target the drawer's ListTile
    // specifically rather than find.text('Sign In'), which would match
    // both simultaneously.
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.widgetWithText(ListTile, 'Sign In'));

    // Must land back on the real LoginScreen (still under _AuthGate),
    // not a dead end.
    expect(find.text('Welcome back'), findsOneWidget);

    await _tapVisible(tester, find.text('Ronaldo Bautista'));

    // The critical assertion: login() must have actually navigated us
    // into the app. Before the fix, this button press had no visible
    // effect because _AuthGate was no longer in the tree to react to it.
    expect(find.text('Welcome back'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guest -> Dokyu restricted notice -> "Sign In" -> Marites Ferrer reaches Home with full access', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Continue as Guest'));
    await _dismissWelcomeBanner(tester);
    await _tapVisible(tester, find.text('Dokyu'));
    expect(find.text('Create Account'), findsOneWidget);

    await _tapVisible(tester, find.text('Sign In'));
    expect(find.text('Welcome back'), findsOneWidget);

    await _tapVisible(tester, find.text('Marites Ferrer'));
    await _dismissWelcomeBanner(tester);
    expect(find.text('Welcome back'), findsNothing);
    expect(tester.takeException(), isNull);

    // Now that we're actually in as Marites, verified-only content must
    // be reachable — proves this isn't just "some screen changed" but
    // the real authenticated app.
    await _tapVisible(tester, find.text('Dokyu'));
    expect(find.text('This feature is available to registered Esperanza users. Create an account or sign in to continue.'), findsNothing);
  });

  testWidgets('RegisterScreen "Continue to App" -> Sign Out still returns cleanly to a working LoginScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    // Sign in as Ronaldo (already has an account), then open
    // RegisterScreen — since an account already exists it jumps straight
    // to the read-only "Verification Status" step, whose "Continue to
    // App" button is exactly the path that used to push a *second*
    // RootShell.withKey() (colliding with the one _AuthGate had already
    // built reactively) or orphan _AuthGate outright.
    await _tapVisible(tester, find.text('Ronaldo Bautista'));
    await _dismissWelcomeBanner(tester);
    await _tapVisible(tester, find.text('Dokyu')); // verification-gated -> RestrictedFeatureNotice
    await _tapVisible(tester, find.text('Continue Verification'));
    expect(find.text('Verification Status'), findsOneWidget); // RegisterScreen's AppBar title for this path

    await _tapVisible(tester, find.text('Continue to App'));
    expect(tester.takeException(), isNull);
    expect(find.text('Verification Status'), findsNothing); // back in the real app, not stuck on the wizard

    // Popping back to root lands us on whatever tab RootShell was already
    // on (Dokyu, still showing the restricted notice — its Scaffold has
    // no drawer). Switch to Home, which does, before opening it.
    await _tapVisible(tester, find.text('Home'));

    // The real proof _AuthGate is still alive and reactive: sign out from
    // here and confirm we land on an actual, working LoginScreen — not a
    // dead screen, and no crash from a duplicated/collided RootShell.
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.widgetWithText(ListTile, 'Sign Out'));
    await _tapVisible(tester, find.widgetWithText(AppButton, 'Sign Out')); // confirm-dialog button
    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
