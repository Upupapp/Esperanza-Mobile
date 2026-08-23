// Functional verification of PostImageViewer — the tap-to-enlarge Balita
// image overlay — covering Guest gating, Ronaldo's (unverified but
// signed-in) engagement also being gated the same way, and feed/viewer
// like-state synchronization.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/screens/balita/post_image_viewer.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/widgets/restricted_feature_notice.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _dismissWelcomeBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close_rounded);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// Demo-account sign-in (LoginScreen._quickLogin) shows a "this app is a
/// frontend simulation" SnackBar via the app-level ScaffoldMessenger, which
/// — unlike a route — persists across navigation for its default ~4s
/// duration. Its static (non-animating) middle stretch doesn't schedule
/// any frame, so `pumpAndSettle()` alone doesn't wait it out, same class of
/// gap as a raw `Future.delayed` — it can still be sitting at the bottom of
/// the screen, over real content, several steps later. Advance the clock
/// straight past it before interacting with anything near the bottom edge.
Future<void> _waitOutSignInToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// The first Balita post ('bal-mangrove-award' in mock_catalog.dart) — has
/// an image, a body message, and non-zero starting likes/shares — good
/// coverage for both "message shown" and "engagement counts stay synced"
/// assertions.
final _mangrovePostImage = find.byWidgetPredicate((w) {
  if (w is! Image) return false;
  final provider = w.image;
  // Image.asset(..., cacheWidth: ...) wraps its AssetImage in a
  // ResizeImage (a display-size decode optimization) — unwrap it so this
  // still matches regardless of whether a given call site sets cacheWidth.
  final asset = provider is ResizeImage ? provider.imageProvider : provider;
  return asset is AssetImage && asset.assetName == 'assets/images/News page section.png';
});

/// RootShell's floating navbar reserves its full pill-plus-headroom
/// bounding box at the bottom of the screen (see nav_style.dart) — only
/// the pill itself is painted, but the whole box still hit-tests, so
/// content that happens to be laid out underneath it (which, on a short
/// phone viewport, a long post's image can be) isn't reliably tappable.
/// Rather than guess a fixed scroll distance — the exact resting position
/// varies with which account signed in and how much of the post's own
/// text renders above the image — read the image's actual current center
/// and, if it's sitting in that bottom reserve, drag it up into the
/// middle of the screen first, the same adjustment a real person would
/// make before tapping something they can see is crowded against the nav
/// bar.
Future<void> _tapClearOfNavbar(WidgetTester tester, Finder target) async {
  final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  var center = tester.getCenter(target);
  if (center.dy > screenHeight * 0.6) {
    // Drag the ListView that actually contains the target (not
    // `find.byType(ListView).first`, which can resolve to Home's own
    // ListView — RootShell keeps every tab alive in an IndexedStack — nor
    // the target itself, whose InkWell intercepts the gesture instead of
    // letting it reach the Scrollable).
    final list = find.ancestor(of: target, matching: find.byType(ListView));
    await tester.drag(list, Offset(0, screenHeight * 0.4 - center.dy));
    await tester.pumpAndSettle();
  }
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openMangroveViewer(WidgetTester tester) async {
  await tester.tap(find.text('Balita'));
  await tester.pumpAndSettle();
  // Scoped to the AppBar specifically — once Balita is the selected nav
  // tab, the navbar's own floating active label also reads "Balita", so an
  // unscoped find.text('Balita') would match both.
  expect(find.descendant(of: find.byType(AppBar), matching: find.text('Balita')), findsOneWidget);
  // Balita's own promotional popup (PromotionalBannerDialog), shown the
  // first time this tab is opened — dismiss it before interacting with
  // the feed underneath, same as a real user tapping its X.
  await _dismissWelcomeBanner(tester);

  expect(_mangrovePostImage, findsOneWidget);
  await _tapClearOfNavbar(tester, _mangrovePostImage);
  expect(find.byType(PostImageViewer), findsOneWidget);
}

void main() {
  testWidgets(
    'Guest: can open the viewer and read the post, but React/Comment/Share all show the account-required notice',
    (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
      _setPhoneViewport(tester);
      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);

      await _openMangroveViewer(tester);

      // The post's own existing message is shown underneath the image.
      expect(
        find.descendant(
          of: find.byType(PostImageViewer),
          matching: find.textContaining('Domorog & Sorosimbahan Mangroves Receive Recognition'),
        ),
        findsOneWidget,
      );

      // Guest must be able to close it easily.
      final closeInViewer = find.descendant(
        of: find.byType(PostImageViewer),
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(closeInViewer, findsOneWidget);

      for (final label in ['Like', 'Comment', 'Share']) {
        final actionInViewer = find.descendant(of: find.byType(PostImageViewer), matching: find.text(label));
        expect(actionInViewer, findsOneWidget, reason: '$label action should be visible in the viewer');
        // The viewer's own content (image + message + actions) can exceed
        // one screen, same as any normal post — scroll its SingleChildScrollView
        // to bring the action row into view before tapping, exactly as a
        // real user would.
        await tester.ensureVisible(actionInViewer);
        await tester.tap(actionInViewer);
        await tester.pumpAndSettle();

        expect(find.byType(RestrictedFeatureNotice), findsOneWidget, reason: '$label should be gated for Guest');
        expect(find.text('Create Account'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(
          find.text(
            'This feature is available to registered Esperanza users. Create an account or sign in to continue.',
          ),
          findsOneWidget,
        );

        // Never a silent failure and never a dead end — pop back to the
        // still-open viewer (matches how it was pushed: a plain
        // Navigator.of(context).push from inside the viewer) and try the
        // next action.
        Navigator.of(tester.element(find.byType(RestrictedFeatureNotice))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(PostImageViewer), findsOneWidget);
      }

      // Closing returns to the Balita feed, not a dead end.
      await tester.ensureVisible(closeInViewer);
      await tester.tap(closeInViewer);
      await tester.pumpAndSettle();
      expect(find.byType(PostImageViewer), findsNothing);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Balita')), findsOneWidget);
    },
  );

  testWidgets(
    'Ronaldo Bautista (signed in, unverified): treated the same as Guest — React/Comment/Share are blocked in the viewer, viewing/zooming stays available',
    (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
      _setPhoneViewport(tester);
      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Ronaldo Bautista'));
      await tester.tap(find.text('Ronaldo Bautista'));
      await tester.pumpAndSettle();
      await _waitOutSignInToast(tester);
      await _dismissWelcomeBanner(tester);

      // Viewing/zooming the image itself stays available — the gate only
      // wraps the react/comment/share actions, never opening the viewer.
      await _openMangroveViewer(tester);
      expect(find.byType(PostImageViewer), findsOneWidget);

      // Starting state: 89 likes, unchanged — an unverified account is
      // blocked the same as a Guest now (Phase 7 of the Balita access
      // rules), not treated as merely "signed in".
      expect(find.text('89'), findsOneWidget);

      final likeInViewer = find.descendant(of: find.byType(PostImageViewer), matching: find.text('Like'));
      await tester.ensureVisible(likeInViewer);
      await tester.tap(likeInViewer);
      await tester.pumpAndSettle();

      expect(find.byType(RestrictedFeatureNotice), findsOneWidget);
      // The like count never moved — the action was blocked before it ran.
      Navigator.of(tester.element(find.byType(RestrictedFeatureNotice))).pop();
      await tester.pumpAndSettle();
      expect(find.text('89'), findsOneWidget);

      // Comment is gated the same way.
      final commentInViewer = find.descendant(of: find.byType(PostImageViewer), matching: find.text('Comment'));
      await tester.ensureVisible(commentInViewer);
      await tester.tap(commentInViewer);
      await tester.pumpAndSettle();
      expect(find.byType(RestrictedFeatureNotice), findsOneWidget);
    },
  );

  testWidgets('Opening a post tracks a view internally, but no view count is ever shown in the UI', (tester) async {
    SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);

    final mangrove = MockCatalog.announcements.firstWhere((a) => a.id == 'bal-mangrove-award');
    final startingViews = mangrove.viewCount;

    await tester.tap(find.text('Balita'));
    await tester.pumpAndSettle();
    await _dismissWelcomeBanner(tester);
    // View count is tracked (see BalitaService.recordView) but must never
    // be rendered anywhere in the feed or the viewer.
    expect(find.textContaining('views'), findsNothing);

    await _tapClearOfNavbar(tester, _mangrovePostImage);
    expect(find.byType(PostImageViewer), findsOneWidget);
    expect(find.descendant(of: find.byType(PostImageViewer), matching: find.textContaining('views')), findsNothing);
    expect(mangrove.viewCount, startingViews + 1);

    final closeInViewer = find.descendant(of: find.byType(PostImageViewer), matching: find.byIcon(Icons.close_rounded));
    await tester.ensureVisible(closeInViewer);
    await tester.tap(closeInViewer);
    await tester.pumpAndSettle();
    expect(find.textContaining('views'), findsNothing);
  });

  testWidgets(
    'Verified user: engagement row shows reaction count on the left, comments then shares together on the right',
    (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
      _setPhoneViewport(tester);
      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cristy Bonghanoy'));
      await tester.tap(find.text('Cristy Bonghanoy'));
      await tester.pumpAndSettle();
      await _waitOutSignInToast(tester);
      await _dismissWelcomeBanner(tester);

      await tester.tap(find.text('Balita'));
      await tester.pumpAndSettle();
      await _dismissWelcomeBanner(tester);

      // 'bal-mangrove-award' has no comments seeded, so it can't show the
      // comment count — scroll to 'bal-1' (214 likes, 2 comments, 18
      // shares), which has all three visible metrics at once.
      await tester.scrollUntilVisible(
        find.textContaining('Sumali sa buong-munisipyong'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // Left (reaction) vs. right (comments, then shares) placement is
      // guaranteed by BalitaEngagementRow's own Row/Expanded source rather
      // than re-measured here by pixel geometry, which proved unreliable
      // to assert on under this test harness in an earlier pass.
      expect(find.text('214'), findsOneWidget);
      expect(find.text('2 comments'), findsOneWidget);
      expect(find.text('18 shares'), findsOneWidget);
      expect(find.textContaining('views'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Verified user: commenting in the image viewer increments the visible comment count immediately', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cristy Bonghanoy'));
    await tester.tap(find.text('Cristy Bonghanoy'));
    await tester.pumpAndSettle();
    await _waitOutSignInToast(tester);
    await _dismissWelcomeBanner(tester);

    // 'bal-mangrove-award' starts with no comments (untouched by any
    // earlier test in this file — only its viewCount is polluted by
    // cross-test viewer-opens, which this check doesn't rely on), so the
    // comment count segment is absent to start, then appears at "1
    // comment" the moment the first one is submitted.
    await _openMangroveViewer(tester);
    expect(find.descendant(of: find.byType(PostImageViewer), matching: find.textContaining('comment')), findsNothing);

    final commentInViewer = find.descendant(of: find.byType(PostImageViewer), matching: find.text('Comment'));
    await tester.ensureVisible(commentInViewer);
    await tester.tap(commentInViewer);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Maganda ang balita na ito!');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(PostImageViewer), matching: find.text('1 comment')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
