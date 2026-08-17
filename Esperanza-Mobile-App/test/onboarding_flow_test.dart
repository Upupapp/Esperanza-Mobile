// Functional verification of the every-launch SplashScreen and the
// one-time first-run OnboardingScreen flow, driven through the real app
// entry point (EsperanzaMobileApp) with real taps — not just code review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/screens/onboarding/onboarding_screen.dart';

/// The default test viewport (800x600) is shorter than a real phone and
/// cuts off the login screen's demo-account cards below the fold. Use a
/// realistic phone size instead — same helper as the other functional
/// suites.
void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('First launch: opening animation leads into all three welcome screens, then Sign In', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);

    await tester.pumpWidget(const EsperanzaMobileApp());
    // One un-settled pump first: confirms the opening animation frame
    // itself (blue background, seal, wordmark) actually renders before it
    // gets fast-forwarded away by pumpAndSettle below.
    await tester.pump();
    expect(find.text('Esperanza Mobile'), findsOneWidget);

    await tester.pumpAndSettle();

    // Screen 1.
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Esperanza, Closer to You'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Screen 2.
    expect(find.text('Services Made Simpler'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Screen 3 — Skip is faded out and non-interactive (Opacity 0 +
    // IgnorePointer, per OnboardingScreen's build method), not removed from
    // the tree outright, so verify it that way rather than with
    // find.text(...findsNothing) — the Text widget itself stays mounted.
    expect(find.text('Stay Connected. Stay Ready.'), findsOneWidget);
    final skipOpacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Skip'), matching: find.byType(Opacity)),
    );
    expect(skipOpacity.opacity, 0, reason: 'Skip should be invisible on the final screen');
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Lands on the existing Sign In screen with its existing options
    // intact — not a new/alternate auth screen.
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    // Onboarding completion was actually persisted, not just navigated
    // past.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('esperanza_onboarding_complete'), isTrue);
  });

  testWidgets('First launch: Skip on screen 1 also completes onboarding and reaches Sign In', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setPhoneViewport(tester);

    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    expect(find.text('Esperanza, Closer to You'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('esperanza_onboarding_complete'), isTrue);
  });

  testWidgets('Returning user: opening animation still plays, but welcome screens never reappear', (tester) async {
    SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
    _setPhoneViewport(tester);

    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pump();
    // The opening animation still runs every launch, regardless of
    // onboarding state.
    expect(find.text('Esperanza Mobile'), findsOneWidget);

    await tester.pumpAndSettle();

    // Straight to the normal entry point — no welcome screens.
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Esperanza, Closer to You'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
}
