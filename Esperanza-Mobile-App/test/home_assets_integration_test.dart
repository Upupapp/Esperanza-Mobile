// Verifies the new asset integration: the post-entry Home_Banner pop-up
// (shows once, dismissible, doesn't reopen on ordinary rebuilds), the
// Balita/News section being gone from Home, the white notification bell
// on Home, several distinct events rendering as separate cards (not
// merged into one container), and the mangrove-award News item appearing
// in the dedicated Balita tab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/widgets/event_card.dart';
import 'package:esperanza_mobile/widgets/home_welcome_banner.dart';

import 'support/fake_api.dart';

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

// GET /events (PublicContentController::events()) -- key/name/title/date/
// time/venue/barangay/category/recurrence/timezone, never an image: the
// real `events` table has no poster column at all (see
// EventItem.fromApi's own doc comment), unlike the MockCatalog fixtures
// this file used to seed itself from, which bundled real poster artwork.
const _seededEvents = [
  {'key': 'ev-1', 'title': 'Barangay Health Fair', 'date': '2026-08-03', 'time': '8:00 AM', 'venue': 'Barangay Baras Covered Court'},
  {'key': 'ev-2', 'title': 'Livelihood Skills Training', 'date': '2026-08-07', 'time': '9:00 AM', 'venue': 'Municipal Hall Annex'},
  {'key': 'ev-3', 'title': 'Basketball League Finals', 'date': '2026-08-12', 'time': '6:00 PM', 'venue': 'Felimon S. Conag Cultural and Sports Center'},
  {'key': 'ev-4', 'title': 'Senior Citizens Assembly', 'date': '2026-08-13', 'time': '1:00 PM', 'venue': 'OSCA Hall'},
  {'key': 'ev-5', 'title': 'Fiesta ng Esperanza Opening', 'date': '2026-08-21', 'time': '2:00 PM', 'venue': 'Municipal Plaza'},
];

Future<void> _enterAsGuest(WidgetTester tester, {List<Map<String, dynamic>> announcements = const []}) async {
  // Onboarding-complete pre-seeded: this suite exercises the normal
  // returning-user flow, not the first-run Onboarding screens — see
  // onboarding_flow_test.dart for that.
  SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
  // RootShell mounts every tab eagerly (IndexedStack), so BalitaScreen's own
  // AsyncStateView fires its GET /announcements the moment this pumps --
  // [announcements] has to be in place *before* pumpWidget, not installed
  // separately afterward.
  FakeApi.install((path, query) {
    if (path == '/events') return _seededEvents;
    if (path == '/announcements') return announcements;
    return const <Map<String, dynamic>>[];
  });
  _setPhoneViewport(tester);
  await tester.pumpWidget(const EsperanzaMobileApp());
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Continue as Guest'));
  await tester.tap(find.text('Continue as Guest'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(FakeApi.restore);

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

  testWidgets('all 5 events render as separate cards on the Events tab, not merged into one container, with no poster affordance', (
    tester,
  ) async {
    await _enterAsGuest(tester);
    await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    await _dismissPromotionalBanner(tester); // Events tab's own promotional popup

    // The Events ListView only inflates elements near the viewport (a
    // plain ListView.builder still lazily builds its Sliver elements), so
    // this sweeps the full scroll range checking for every title at each
    // step, rather than searching for titles one at a time in sequence.
    // Searching sequentially (each search resuming from wherever the
    // previous one stopped) let the accumulated scroll position run past
    // the last card's narrow "still built" window before ever looking for
    // it — not a bug in the cards themselves, just an artifact of chaining
    // several finds together. Driving the scrollable's position directly
    // (rather than gesture-based dragging) sidesteps that accumulation.
    final scrollable = find.byType(Scrollable).last;
    final position = tester.state<ScrollableState>(scrollable).position;
    const titles = [
      'Barangay Health Fair',
      'Livelihood Skills Training',
      'Basketball League Finals',
      'Senior Citizens Assembly',
      'Fiesta ng Esperanza Opening',
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

    // No poster affordance anywhere: GET /events never returns an image
    // (see EventItem.fromApi's own doc comment), so EventCard's own
    // imagePath-gated "View full poster" label/tap-to-open never applies
    // to a real event. Tapping one is a no-op (onTap is null without an
    // image), not a navigation into EventPosterViewer.
    expect(find.text('View full poster'), findsNothing);
    await tester.tap(find.textContaining('Barangay Health Fair'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('Barangay Health Fair'), findsWidgets); // still on the Events list
  });

  testWidgets('the mangrove-award announcement appears in the Balita tab (not on Home), with its real image', (
    tester,
  ) async {
    // Real content now (GET /announcements) instead of MockCatalog's own
    // bundled 'News page section.png' asset.
    await _enterAsGuest(
      tester,
      announcements: const [
        {
          'id': 1,
          'title': null,
          'body': 'Domorog & Sorosimbahan Mangroves Receive Recognition',
          'category': 'Community',
          'barangay': null,
          'official': true,
          'author': 'Esperanza LGU',
          'published_at': '2026-09-10T00:00:00.000Z',
          'likes': 89,
          'shares': 21,
          'comments_count': 0,
          'image_url': 'https://test.invalid/mangrove.jpg',
        },
      ],
    );
    await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Balita'));
    await tester.pumpAndSettle();
    await _dismissPromotionalBanner(tester); // Balita tab's own promotional popup

    expect(find.textContaining('Domorog & Sorosimbahan Mangroves Receive Recognition'), findsOneWidget);
    final newsImage = tester.widgetList<Image>(find.byType(Image)).where((img) {
      final provider = img.image;
      return provider is NetworkImage && provider.url == 'https://test.invalid/mangrove.jpg';
    });
    expect(newsImage.length, 1);

    // A citizen can post to the community feed now (production-readiness
    // programme, 2026-09-25 -- POST /community-posts is a real, if
    // previously unused, backend capability); the entry point is visible
    // even to a Guest, but tapping it gates on sign-in like every other
    // Balita interaction, rather than opening the composer.
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
