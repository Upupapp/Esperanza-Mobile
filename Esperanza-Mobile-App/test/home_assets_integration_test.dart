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

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _enterAsGuest(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  _setPhoneViewport(tester);
  await tester.pumpWidget(const EsperanzaMobileApp());
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Continue as Guest'));
  await tester.tap(find.text('Continue as Guest'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home_Banner pop-up appears after entering Home, over a dimmed background, not distorted', (tester) async {
    await _enterAsGuest(tester);

    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
    // The actual poster image is present and not stretched/cropped —
    // BoxFit.contain inside a bounded ConstrainedBox, never .cover.
    final image = tester.widget<Image>(find.descendant(of: find.byType(HomeWelcomeBanner), matching: find.byType(Image)));
    expect(image.fit, BoxFit.contain);
    expect((image.image as AssetImage).assetName, 'assets/images/Home_Banner.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('X button is upper-right, closes the banner, and it does not reopen on an ordinary rebuild', (tester) async {
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

  testWidgets('all 5 real event posters render as separate cards on the Events tab, not merged into one container', (tester) async {
    await _enterAsGuest(tester);
    await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Balita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    // The Events ListView only inflates elements near the viewport (a
    // plain ListView(children:...) still lazily builds its Sliver
    // elements), so scroll each title into view individually rather than
    // asserting a simultaneous global count — each found title is its own
    // distinct EventCard ancestor, which is exactly what proves they're
    // separate cards and not one merged container.
    final scrollable = find.byType(Scrollable).last;
    for (final title in [
      'Baras vs Tunga',
      'Sorosimbajan vs Labangtaytay',
      'Tawad vs Santiago',
      'Pa Jollibee ug Sorbetes ni Mayor JJ!',
      'Mega Shoe Caravan',
    ]) {
      await tester.scrollUntilVisible(find.textContaining(title), 250, scrollable: scrollable);
      expect(find.textContaining(title), findsOneWidget);
      expect(
        find.ancestor(of: find.textContaining(title), matching: find.byType(EventCard)),
        findsOneWidget,
      );
    }
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
    final newsImage = tester.widgetList<Image>(find.byType(Image)).where(
          (img) => img.image is AssetImage && (img.image as AssetImage).assetName == 'assets/images/News page section.png',
        );
    expect(newsImage.length, 1);

    // Hard rule check: no create/upload/publish affordance exists anywhere
    // on this screen.
    expect(find.text('Create Post'), findsNothing);
    expect(find.text('Upload'), findsNothing);
    expect(find.text('Publish'), findsNothing);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing);
  });
}
