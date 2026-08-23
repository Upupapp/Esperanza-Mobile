// Verifies the new asset integration: the post-entry Home_Banner pop-up
// (shows once, dismissible, doesn't reopen on ordinary rebuilds), the
// Balita/News section being gone from Home, the white notification bell
// on Home, the five real event posters rendering as separate cards (not
// merged into one container), and the mangrove-award News item appearing
// in the dedicated Balita tab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/screens/shared/event_poster_viewer.dart';
import 'package:esperanza_mobile/widgets/event_card.dart';
import 'package:esperanza_mobile/widgets/home_welcome_banner.dart';

/// Unwraps the `ResizeImage` that `Image.asset(..., cacheWidth: ...)` now
/// wraps its `AssetImage` in (a performance optimization — decode at
/// display size instead of full source resolution) so tests can still
/// assert on the underlying asset path regardless of whether a given call
/// site specifies cacheWidth or not.
AssetImage _unwrapAssetImage(ImageProvider provider) {
  return provider is ResizeImage ? provider.imageProvider as AssetImage : provider as AssetImage;
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Dokyu/Tulong/Balita/Events/Emergency each offer their own promotional
/// popup (PromotionalBannerDialog) the first time RootShell switches to
/// that tab — dismiss it the same way a real user would (tap its X) before
/// interacting with the screen underneath, otherwise the modal barrier
/// intercepts every subsequent tap/scroll meant for that screen.
Future<void> _dismissPromotionalBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close_rounded);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton.last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

Future<void> _enterAsGuest(WidgetTester tester) async {
  // Onboarding-complete pre-seeded: this suite exercises the normal
  // returning-user flow, not the first-run Onboarding screens — see
  // onboarding_flow_test.dart for that.
  SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
  _setPhoneViewport(tester);
  await tester.pumpWidget(const EsperanzaMobileApp());
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Continue as Guest'));
  await tester.tap(find.text('Continue as Guest'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home_Banner pop-up appears after entering Home, over a dimmed background, not distorted', (
    tester,
  ) async {
    await _enterAsGuest(tester);

    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
    // The actual poster image is present and not stretched/cropped —
    // BoxFit.contain inside a bounded ConstrainedBox, never .cover.
    final image = tester.widget<Image>(
      find.descendant(of: find.byType(HomeWelcomeBanner), matching: find.byType(Image)),
    );
    expect(image.fit, BoxFit.contain);
    expect(_unwrapAssetImage(image.image).assetName, 'assets/images/Home_Banner.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('X button is upper-right, closes the banner, and it does not reopen on an ordinary rebuild', (
    tester,
  ) async {
    await _enterAsGuest(tester);
    expect(find.byType(HomeWelcomeBanner), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(HomeWelcomeBanner), findsNothing);

    // Trigger an ordinary Home rebuild (pull-to-refresh's RefreshIndicator
    // completing causes a rebuild) and confirm the banner does not
    // reappear just because HomeScreen rebuilt.
    await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(HomeWelcomeBanner), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home no longer shows a Balita/News section, and the notification bell is white', (tester) async {
    await _enterAsGuest(tester);
    await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Balita — Latest News'), findsNothing);
    expect(find.text('Upcoming Events'), findsOneWidget); // Events preview still present

    final bellIcon = tester.widget<Icon>(find.byIcon(Icons.notifications_outlined));
    expect(bellIcon.color, Colors.white);

    // Tap behavior is unchanged — still opens Notifications.
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('all 5 real event posters render as separate cards on the Events tab, not merged into one container', (
    tester,
  ) async {
    await _enterAsGuest(tester);
    await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    await _dismissPromotionalBanner(tester); // Events tab's own promotional popup

    // The Events ListView only inflates elements near the viewport (a
    // plain ListView(children:...) still lazily builds its Sliver
    // elements), so this sweeps the full scroll range checking for every
    // title at each step, rather than searching for titles one at a time
    // in sequence. Searching sequentially (each search resuming from
    // wherever the previous one stopped) let the accumulated scroll
    // position run past the last card's narrow "still built" window
    // before ever looking for it — not a bug in the cards themselves, just
    // an artifact of chaining several finds together. Driving the
    // scrollable's position directly (rather than gesture-based dragging)
    // sidesteps both that accumulation and Flutter's touch-slop, which
    // makes any single drag smaller than ~18px liable to be interpreted as
    // a tap instead of a scroll — on an EventCard, that tap opens the full
    // poster viewer, an unrelated screen with no Scrollable at all.
    final scrollable = find.byType(Scrollable).last;
    final position = tester.state<ScrollableState>(scrollable).position;
    const titles = [
      'Baras vs Tunga',
      'Sorosimbajan vs Labangtaytay',
      'Tawad vs Santiago',
      'Pa Jollibee ug Sorbetes ni Mayor JJ!',
      'Mega Shoe Caravan',
    ];
    final seen = <String>{};
    for (double p = 0; p <= position.maxScrollExtent; p += 20) {
      position.jumpTo(p);
      await tester.pumpAndSettle();
      for (final title in titles) {
        if (seen.contains(title)) continue;
        if (find.textContaining(title).evaluate().isEmpty) continue;
        seen.add(title);
        // Each found title is its own distinct EventCard ancestor, which
        // is exactly what proves they're separate cards and not one
        // merged container.
        expect(find.ancestor(of: find.textContaining(title), matching: find.byType(EventCard)), findsOneWidget);
      }
    }
    expect(seen, titles.toSet());
    expect(tester.takeException(), isNull);

    // Tapping one opens the full poster viewer for that specific event —
    // scroll back to the top first (the first card is comfortably clear
    // of the AppBar, unlike the last one after scrolling to the bottom)
    // and tap the first event.
    await tester.drag(scrollable, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Baras vs Tunga'));
    await tester.pumpAndSettle();
    expect(find.byType(EventPosterViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('the mangrove-award News item appears in the Balita tab (not on Home), with its image', (tester) async {
    await _enterAsGuest(tester);
    await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Balita'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Domorog & Sorosimbahan Mangroves Receive Recognition'), findsOneWidget);
    final newsImage = tester.widgetList<Image>(find.byType(Image)).where((img) {
      final provider = img.image;
      if (provider is! AssetImage && provider is! ResizeImage) return false;
      return _unwrapAssetImage(provider).assetName == 'assets/images/News page section.png';
    });
    expect(newsImage.length, 1);

    // Hard rule check: no create/upload/publish affordance exists anywhere
    // on this screen.
    expect(find.text('Create Post'), findsNothing);
    expect(find.text('Upload'), findsNothing);
    expect(find.text('Publish'), findsNothing);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing);
  });
}
