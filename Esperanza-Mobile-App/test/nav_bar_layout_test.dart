// The bottom bar's tabs sit inside the pill, with as much space above them as
// below (2026-10-09). Before, each tab hugged the pill's bottom edge, leaving
// a wide gap over the icons, and the active gold ball floated 12pt above the
// bar; under Emergency it hung past the pill's rounded end, and the bold
// "Emergency" label ran into that end. Seen on a phone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esperanza_mobile/widgets/esperanza_curved_navbar.dart';
import 'package:esperanza_mobile/widgets/esperanza_curved_nav_painter.dart';
import 'package:esperanza_mobile/widgets/esperanza_nav_item.dart';
import 'package:esperanza_mobile/widgets/nav_item_data.dart';

const _items = [
  NavItemData(outlineIcon: Icons.home_outlined, filledIcon: Icons.home_rounded, label: 'Home'),
  NavItemData(outlineIcon: Icons.campaign_outlined, filledIcon: Icons.campaign_rounded, label: 'Balita'),
  NavItemData(outlineIcon: Icons.event_outlined, filledIcon: Icons.event_rounded, label: 'Events'),
  NavItemData(outlineIcon: Icons.shield_outlined, filledIcon: Icons.shield_rounded, label: 'Emergency'),
];

Future<void> _pumpBar(WidgetTester tester, {required int active, required double width, required double bottomInset}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
  tester.view.padding = FakeViewPadding(bottom: bottomInset);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: EsperanzaCurvedNavBar(
          items: _items,
          activeIndex: active,
          activeLauncherTarget: null,
          onTabSelected: (_) {},
          onCenterPressed: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The pill as painted, in screen coordinates.
RRect _pill(WidgetTester tester, double bottomInset) {
  final shape = find.byKey(const ValueKey('nav-bar-shape'));
  final origin = tester.getTopLeft(shape);
  final bounds = EsperanzaCurvedNavPainter.pillPath(tester.getSize(shape), bottomInset: bottomInset).getBounds();
  return RRect.fromRectAndRadius(bounds.shift(origin), const Radius.circular(EsperanzaCurvedNavPainter.pillRadius));
}

/// Inside the rounded pill, not just its bounding box: a corner of a label
/// under the pill's rounded end is outside even when the box says otherwise.
void _expectInside(RRect pill, Rect r, String what) {
  for (final p in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
    expect(pill.contains(p), isTrue, reason: '$what reaches outside the bar at $p (bar $pill)');
  }
}

void main() {
  for (final width in [280.0, 360.0, 412.0]) {
    for (final inset in [0.0, 24.0]) {
      for (var active = 0; active < _items.length; active++) {
        final name = _items[active].label;
        testWidgets('$name active, ${width.toInt()}pt wide, bottom inset ${inset.toInt()}: '
            'the tabs sit inside the bar, as much space above as below', (tester) async {
          await _pumpBar(tester, active: active, width: width, bottomInset: inset);
          final pill = _pill(tester, inset);

          // The gold capsule: inside, with its round ends kept off the pill's.
          final capsule = tester.getRect(find.byType(EsperanzaActiveBubble));
          _expectInside(pill, capsule.deflate(capsule.height / 2 * 0.3), 'the $name capsule');
          expect(capsule.top, greaterThanOrEqualTo(pill.top), reason: 'the capsule rises above the bar');

          // Every label, the bold active one included.
          for (final item in _items) {
            _expectInside(pill, tester.getRect(find.text(item.label)), 'the "${item.label}" label');
          }

          // Balanced: the capsule's gap to the top equals the label's gap
          // to the bottom.
          final label = tester.getRect(find.text(name));
          final above = capsule.top - pill.top;
          final below = pill.bottom - label.bottom;
          expect(above, closeTo(below, 1.5), reason: 'above $above vs below $below');
        });
      }
    }
  }

  testWidgets('an idle tab is centred too: its icon and label sit mid-bar', (tester) async {
    await _pumpBar(tester, active: 0, width: 412, bottomInset: 24);
    final pill = _pill(tester, 24);
    final icon = tester.getRect(find.byIcon(Icons.event_outlined));
    final label = tester.getRect(find.text('Events'));
    final middle = (icon.top - 4 + label.bottom) / 2; // the icon row starts 4pt above the icon
    expect(middle, closeTo(pill.center.dy, 1.5));
  });
}
