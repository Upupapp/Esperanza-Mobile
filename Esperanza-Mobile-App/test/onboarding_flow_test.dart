// Functional verification of the every-launch SplashScreen and the one-time
// first-run OnboardingScreen flow, driven through the real app entry point
// (EsperanzaMobileApp) with real taps and real drags — not just code review.
//
// **What changed here, and why.** Until 2026-08-30 each assertion in this file
// named a PNG: the three welcome pages were flattened composites, so the only
// thing a test could check was "the right image is on screen". That is a test
// of the asset pipeline, not of onboarding — it would have passed just as
// happily while the artwork advertised "Business Permit — Approved", an
// outcome this app cannot produce.
//
// The pages are native, built to the owner's design (2026-10-12: a photograph
// over the top of the screen, the copy and its cards below, pages changing by
// cross-fade), so these assert what a citizen actually gets: the approved
// headline, the controls, where each control leads, and that completion is
// persisted. `onboarding_redesign_test.dart` covers the parts that are about
// *how* it is presented — motion, reduced motion, responsive sizes, semantics
// and copy accuracy.
//
// All three pages' copy stays laid out in one place (so the headline does not
// jump between pages), with only the current one visible and touchable — so
// "this page is showing" is asked of what can be touched (`hitTestable`), not
// of what exists in the tree.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/screens/home/root_shell.dart';
import 'package:esperanza_mobile/widgets/seal_badge.dart';
import 'package:provider/provider.dart';
import 'package:esperanza_mobile/screens/onboarding/onboarding_page_data.dart';
import 'package:esperanza_mobile/screens/onboarding/onboarding_screen.dart';

/// The default test viewport (800x600) is shorter than a real phone and cuts
/// off the login screen's demo-account cards below the fold. Use a realistic
/// phone size instead — same helper as the other functional suites.
void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Swipes across the photograph, in steps, and settles. A swipe turns the
/// page on release, as in the design: more than 48px across, and clearly more
/// across than down.
Future<void> _swipe(WidgetTester tester, {required double by}) async {
  final photo = tester.getTopLeft(find.byKey(const Key('onboarding_photo')));
  final gesture = await tester.startGesture(
    Offset(photo.dx + 195, photo.dy + 200),
  );
  const steps = 8;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(by / steps, 0));
    await tester.pump();
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Finder get _skip => find.byKey(const Key('onboarding_skip'));
Finder get _next => find.byKey(const Key('onboarding_next'));
Finder get _getStarted => find.byKey(const Key('onboarding_get_started'));

/// Asserts the given page is the one on screen, by its approved headline and
/// the brand line every page carries.
void _expectPage(int index) {
  for (var i = 0; i < onboardingScenes.length; i++) {
    expect(
      find.text(onboardingScenes[i].headline).hitTestable(),
      i == index ? findsOneWidget : findsNothing,
      reason: 'page ${i + 1} ${i == index ? 'is not' : 'is still'} the one showing',
    );
  }
  expect(find.text(onboardingBrandLines), findsOneWidget);
}

void main() {
  testWidgets(
    'First launch: opening animation leads into all three welcome screens, then Sign In',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setPhoneViewport(tester);

      await tester.pumpWidget(const EsperanzaMobileApp());
      // One un-settled pump first: confirms the opening animation frame itself
      // (the seal on navy, the loading line) actually renders before it gets
      // fast-forwarded away by pumpAndSettle below.
      await tester.pump();
      expect(find.text('Loading Esperanza...'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Image && w.semanticLabel == 'Official seal of the Municipality of Esperanza'),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      // Page 1 — brand, headline, Skip, Next.
      expect(find.byType(OnboardingScreen), findsOneWidget);
      _expectPage(0);
      expect(_skip, findsOneWidget);
      expect(_next, findsOneWidget);
      expect(_getStarted, findsNothing);

      await tester.tap(_next);
      await tester.pumpAndSettle();

      // Page 2.
      _expectPage(1);
      expect(_skip, findsOneWidget);
      expect(_next, findsOneWidget);

      await tester.tap(_next);
      await tester.pumpAndSettle();

      // Page 3 — Skip is GONE, not merely invisible. The old screen faded it to
      // opacity 0 behind an IgnorePointer, which leaves a control that a screen
      // reader still announces and a keyboard can still focus.
      _expectPage(2);
      expect(_skip, findsNothing);
      expect(find.text('Skip'), findsNothing);
      expect(_getStarted, findsOneWidget);
      expect(_next, findsNothing);

      await tester.tap(_getStarted);
      await tester.pumpAndSettle();

      // Lands on the existing Sign In screen with its existing options intact —
      // not a new or alternate auth screen.
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    },
  );

  testWidgets(
    "Into the welcome pages, the opening screen's seal flies into the header's",
    (tester) async {
      // Owner, 2026-10-12: "the logo remains and morphs to the logo on the
      // upper left of the 1st onboarding screen".
      SharedPreferences.setMockInitialValues({});
      _setPhoneViewport(tester);
      await tester.pumpWidget(const EsperanzaMobileApp());

      // The seals on screen, by size, frame by frame through the hand-off.
      final sizes = <double>[];
      final centres = <Offset>[];
      for (var t = 0; t < 4500; t += 50) {
        await tester.pump(const Duration(milliseconds: 50));
        // A seal in flight ignores touches, and the two it flies between are
        // held offstage meanwhile, so this finds the one actually drawn.
        final shown = find.byType(SealBadge);
        if (find.byType(OnboardingScreen).evaluate().isNotEmpty && shown.evaluate().length == 1) {
          sizes.add(tester.getSize(shown).width);
          centres.add(tester.getCenter(shown));
        }
      }
      await tester.pumpAndSettle();

      // In flight: one seal, between the two sizes, moving up and left.
      final between = sizes.where((s) => s > 50 && s < 190).toList();
      expect(between, isNotEmpty, reason: 'no frame showed the seal between its two sizes: $sizes');
      expect(centres.first.dy, greaterThan(centres.last.dy));
      expect(centres.first.dx, greaterThan(centres.last.dx));

      // Landed: the header's seal, 46 across, at the upper left.
      final landed = tester.getRect(find.byType(SealBadge));
      expect(landed.width, 46);
      expect(landed.left, lessThan(60));
      expect(landed.top, lessThan(100));
    },
  );

  testWidgets(
    'First launch: Skip on screen 1 also reaches Sign In',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setPhoneViewport(tester);

      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();

      _expectPage(0);
      await tester.tap(_skip);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Welcome back'), findsOneWidget);
    },
  );

  testWidgets(
    'No one signed in: the welcome pages open the app every time, even after Skip',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setPhoneViewport(tester);

      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();
      await tester.tap(_skip);
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);

      // The app opened again, still with no one signed in.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      _expectPage(0);
    },
  );

  testWidgets(
    'Someone signed in: the opening animation still plays, then straight past the welcome pages',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'esperanza_citizen_session': jsonEncode(MockCatalog.demoAccounts.first.toJson()),
      });
      _setPhoneViewport(tester);

      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pump();
      // The opening animation runs every launch.
      expect(find.text('Loading Esperanza...'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text(onboardingBrandLines), findsNothing);
      expect(find.byType(RootShell), findsOneWidget);
    },
  );

  testWidgets(
    'Signed out: the next launch opens on the welcome pages again',
    (tester) async {
      // Owner, 2026-10-12: "I signed out and reopened the app but it went
      // straight to sign in." They used to show once per phone, ever.
      SharedPreferences.setMockInitialValues({
        'esperanza_citizen_session': jsonEncode(MockCatalog.demoAccounts.first.toJson()),
      });
      _setPhoneViewport(tester);
      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();
      expect(find.byType(RootShell), findsOneWidget);

      await Provider.of<CitizenSessionService>(tester.element(find.byType(RootShell)), listen: false).logout();
      await tester.pumpAndSettle();

      // The app opened again.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      _expectPage(0);
    },
  );

  testWidgets(
    'A guest is not signed in either: the welcome pages open the app, then Home as before',
    (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_guest_mode': true});
      _setPhoneViewport(tester);
      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.tap(_skip);
      await tester.pumpAndSettle();
      expect(find.byType(RootShell), findsOneWidget);
    },
  );

  testWidgets(
    'Swiping navigates both ways, and a half-finished drag throws nothing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setPhoneViewport(tester);

      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();
      _expectPage(0);

      // Forward.
      await _swipe(tester, by: -320);
      _expectPage(1);

      // Back.
      await _swipe(tester, by: 320);
      _expectPage(0);

      // A drag released mid-way must settle somewhere valid rather than throw.
      final photo = tester.getTopLeft(find.byKey(const Key('onboarding_photo')));
      final gesture = await tester.startGesture(
        Offset(photo.dx + 195, photo.dy + 200),
      );
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(-22, 0));
        await tester.pump();
      }
      expect(tester.takeException(), isNull, reason: 'a partial drag threw');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'settling after a partial drag threw',
      );

      // Whichever page it settled on, onboarding is still usable — the point is
      // that a released half-swipe never strands the citizen.
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text(onboardingBrandLines), findsOneWidget);
    },
  );

  testWidgets(
    'Skip is not offered once the citizen is already on the last page',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      _setPhoneViewport(tester);

      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();

      await _swipe(tester, by: -320);
      expect(_skip, findsOneWidget, reason: 'Skip belongs on page 2');

      await _swipe(tester, by: -320);
      // Reached by swipe rather than by the Next button — the rule is about
      // which page you are on, not how you got there.
      expect(_skip, findsNothing);
    },
  );
}
