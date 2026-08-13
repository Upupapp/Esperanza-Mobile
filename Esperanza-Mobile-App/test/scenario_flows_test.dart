// Functional (not just static) verification of the three scenarios from
// the nav/access-control spec, driven through the real app entry point
// (EsperanzaMobileApp) with real taps — not just code review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';

/// The default test viewport (800x600) is shorter than a real phone and
/// cuts off the login screen's demo-account cards below the fold, making
/// them untappable without scrolling. Use a realistic phone size instead.
void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Home shows the promotional HomeWelcomeBanner pop-up once per session,
/// right after it first loads — dismiss it (tap its "Close" button) the
/// same way a real user would before continuing to interact with Home,
/// otherwise the modal barrier intercepts every subsequent tap.
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
  testWidgets('Scenario A — Guest: Home -> Balita public -> Dokyu shows restricted notice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    // 1. Open Sign-In.
    expect(find.text('Welcome back'), findsOneWidget);

    // 2. Tap Continue as Guest.
    await tester.ensureVisible(find.text('Continue as Guest'));
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    // 3. Enter Home successfully — Guest branch renders, not a crash on
    // `account!`.
    await _dismissWelcomeBanner(tester);
    expect(find.textContaining('Welcome, Guest'), findsOneWidget);
    expect(find.text('Home'), findsWidgets); // bottom nav label

    // 4. Open public Balita content successfully.
    await tester.tap(find.text('Balita'));
    await tester.pumpAndSettle();
    expect(find.text('Balita & Events'), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets); // real screen, not a notice

    // 5. Try a restricted feature (Dokyu).
    await tester.tap(find.text('Dokyu'));
    await tester.pumpAndSettle();

    // 6. Confirm the registration/sign-in notice appears, not the real
    // Dokyu screen (which would show "Dokyu Requests" content/FAB).
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(
      find.text('This feature is available to registered Esperanza users. Create an account or sign in to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('Scenario B — Ronaldo Bautista: registered but unverified, restricted from Dokyu, allowed into Emergency', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    // 1. Sign in using the Ronaldo Bautista demo account.
    expect(find.text('Ronaldo Bautista'), findsOneWidget);
    expect(find.text('Unverified User'), findsOneWidget); // demo card label, before even signing in
    await tester.ensureVisible(find.text('Ronaldo Bautista'));
    await tester.tap(find.text('Ronaldo Bautista'));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);

    // 2 & 3. Confirm registered-but-unverified is recognized, and status
    // is clearly visible — via Profile (hamburger drawer -> Profile).
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Account Verification'), findsOneWidget); // VerificationStatusPanel header
    expect(find.text('Pending Review'), findsOneWidget); // StatusChip — not "Approved"

    // Back to the tab bar.
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 4. Attempt to use a verification-restricted feature (Dokyu).
    await tester.tap(find.text('Dokyu'));
    await tester.pumpAndSettle();

    // 5. Confirm prompted to complete verification, NOT treated as a
    // Guest (different message/action than Scenario A).
    expect(find.text('Continue Verification'), findsOneWidget);
    expect(find.text('Complete your account verification to access this service.'), findsOneWidget);
    expect(find.text('Create Account'), findsNothing); // guest-only copy must not appear
    expect(find.text('Sign In'), findsNothing);

    // Emergency only requires being signed in (not verified) — Ronaldo
    // must reach the real screen, not another notice.
    await tester.tap(find.text('Emergency'));
    await tester.pumpAndSettle();
    expect(find.text('Risk Reduction & Emergency'), findsOneWidget);
    expect(find.text('Report an Incident'), findsOneWidget); // real Sakuna content
  });

  testWidgets('Scenario C — Marites Ferrer: fully verified, full access, no guest/verification warnings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    // 1. Sign in using the Marites Ferrer demo account.
    expect(find.text('Marites Ferrer'), findsOneWidget);
    expect(find.text('Verified User'), findsOneWidget); // demo card label
    await tester.ensureVisible(find.text('Marites Ferrer'));
    await tester.tap(find.text('Marites Ferrer'));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);

    // 2. Confirm recognized as fully verified.
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Approved'), findsOneWidget); // StatusChip via VerificationStatusPanel
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 3. Confirm verified-user features (Dokyu, Tulong) are available —
    // real screens render, not RestrictedFeatureNotice.
    await tester.tap(find.text('Dokyu'));
    await tester.pumpAndSettle();
    expect(find.text('Dokyu'), findsWidgets); // AppBar title among other things
    expect(find.text('Complete your account verification to access this service.'), findsNothing);
    expect(find.text('This feature is available to registered Esperanza users. Create an account or sign in to continue.'), findsNothing);

    await tester.tap(find.text('Tulong'));
    await tester.pumpAndSettle();
    expect(find.text('Complete your account verification to access this service.'), findsNothing);

    // 4. No unnecessary Guest or verification warnings anywhere on Home.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Welcome, Guest'), findsNothing);
    expect(find.textContaining('Magandang araw, Marites'), findsOneWidget);
  });
}
