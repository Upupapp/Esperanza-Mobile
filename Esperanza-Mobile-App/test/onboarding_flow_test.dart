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

/// Confirms the given welcome screen's real final artwork is actually the
/// one loaded on screen (not a placeholder), plus the branding overlay
/// that sits on top of every page.
void _expectPageImageAndBrand(WidgetTester tester, String fileName) {
  final imageFinder = find.byWidgetPredicate((w) {
    if (w is! Image) return false;
    final provider = w.image;
    // Image.asset(..., cacheWidth: ...) wraps its AssetImage in a
    // ResizeImage (a display-size decode optimization) — unwrap it so
    // this still matches regardless of whether cacheWidth is set.
    final asset = provider is ResizeImage ? provider.imageProvider : provider;
    return asset is AssetImage && asset.assetName == 'assets/images/$fileName';
  });
  expect(imageFinder, findsOneWidget, reason: '$fileName should be loaded as this page\'s background');
  expect(find.text('Municipalidad ng Esperanza'), findsOneWidget);
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

    // Screen 1 — the real "Welcome Screen 1" artwork, seal + municipality
    // name overlaid upper-middle, Skip upper-right, Next lower-middle.
    expect(find.byType(OnboardingScreen), findsOneWidget);
    _expectPageImageAndBrand(tester, 'Welcome Screen 1.png');
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Screen 2.
    _expectPageImageAndBrand(tester, 'Welcome Screen 2.png');
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Screen 3 — Skip is faded out and non-interactive (Opacity 0 +
    // IgnorePointer, per OnboardingScreen's build method), not removed from
    // the tree outright, so verify it that way rather than with
    // find.text(...findsNothing) — the Text widget itself stays mounted.
    _expectPageImageAndBrand(tester, 'Welcome Screen 3.png');
    final skipOpacity = tester.widget<Opacity>(find.ancestor(of: find.text('Skip'), matching: find.byType(Opacity)));
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

    _expectPageImageAndBrand(tester, 'Welcome Screen 1.png');
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
    expect(find.text('Municipalidad ng Esperanza'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
}
