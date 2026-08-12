// Verifies the "moving navbar shape" requirement: the floating circle AND
// the bar's own raised bump must be driven from one shared animated
// position and travel together — not a circle sliding over an otherwise
// static rectangle. Covers all required adjacent and long-distance
// transitions plus an interrupted mid-flight retarget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esperanza_mobile/widgets/animated_bottom_navigation.dart';

const _items = [
  AnimatedBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
  AnimatedBottomNavItem(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Dokyu'),
  AnimatedBottomNavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism_rounded, label: 'Tulong'),
  AnimatedBottomNavItem(icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, label: 'Balita'),
  AnimatedBottomNavItem(icon: Icons.shield_outlined, activeIcon: Icons.shield_rounded, label: 'Emergency'),
];

/// A tiny stateful harness so tests can drive [AnimatedBottomNavigation]
/// the same way RootShell does — tapping a tab updates the index that
/// flows back in as `currentIndex`.
class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: AnimatedBottomNavigation(
          items: _items,
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
        ),
      ),
    );
  }
}

double _indicatorLeft(WidgetTester tester) {
  final positioned = tester.widget<Positioned>(find.byKey(const ValueKey('nav-floating-indicator')));
  return positioned.left!;
}

/// `_NavBarPainter` is library-private (its name can't be imported), but
/// `centerX` itself is a public field name, so it's still reachable via a
/// dynamic reference to the painter instance obtained through the public
/// `CustomPaint.painter` API — this is what lets the test confirm the bar
/// shape and the circle share the same driving value without exposing
/// painter internals as a public API just for testing.
double _bumpCenterX(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(find.byKey(const ValueKey('nav-bar-shape')));
  final dynamic painter = customPaint.painter;
  return painter.centerX as double;
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  testWidgets('exactly one floating indicator and one bar-shape painter exist', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-floating-indicator')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-bar-shape')), findsOneWidget);
  });

  testWidgets('the bar bump and the floating circle are driven by the same centerX at rest and mid-flight', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    // At rest.
    final restBubbleCenter = _indicatorLeft(tester) + 30; // + bubbleSize/2
    expect(_bumpCenterX(tester), closeTo(restBubbleCenter, 0.01));

    // Mid-flight, partway through a long trip.
    await _tapTab(tester, 'Emergency');
    await tester.pump(const Duration(milliseconds: 120));
    final midBubbleCenter = _indicatorLeft(tester) + 30;
    expect(_bumpCenterX(tester), closeTo(midBubbleCenter, 0.01));
    // And it should have actually moved from the resting position by now.
    expect(midBubbleCenter, isNot(closeTo(restBubbleCenter, 1.0)));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  final transitions = <List<String>>[
    ['Home', 'Dokyu'],
    ['Dokyu', 'Tulong'],
    ['Tulong', 'Balita'],
    ['Balita', 'Emergency'],
    ['Emergency', 'Home'],
    ['Home', 'Balita'], // non-adjacent
    ['Home', 'Emergency'], // full-width trip
    ['Emergency', 'Dokyu'], // full-width trip back, different destination
  ];

  for (final t in transitions) {
    final from = t[0];
    final to = t[1];
    testWidgets('$from -> $to: circle and bar bump both settle centered above the destination tab', (tester) async {
      await tester.pumpWidget(const _Harness());
      await tester.pumpAndSettle();

      final fromIndex = _items.indexWhere((i) => i.label == from);
      final toIndex = _items.indexWhere((i) => i.label == to);

      if (fromIndex != 0) {
        await _tapTab(tester, from);
        await tester.pumpAndSettle();
      }
      final startLeft = _indicatorLeft(tester);

      await _tapTab(tester, to);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final settledLeft = _indicatorLeft(tester);
      final barWidth = tester.getSize(find.byType(AnimatedBottomNavigation)).width;
      final segmentWidth = barWidth / _items.length;
      const bubbleSize = 60.0;
      final expectedLeft = segmentWidth * toIndex + (segmentWidth - bubbleSize) / 2;
      expect(settledLeft, closeTo(expectedLeft, 0.5));

      // The bump must have followed it to the exact same resting spot.
      expect(_bumpCenterX(tester), closeTo(settledLeft + bubbleSize / 2, 0.5));

      if (fromIndex != toIndex) {
        expect(settledLeft, isNot(closeTo(startLeft, 0.5)));
      }
    });
  }

  testWidgets('interrupted mid-flight tap (Home -> Emergency -> Dokyu) redirects smoothly and settles correctly', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    await _tapTab(tester, 'Emergency');
    await tester.pump(const Duration(milliseconds: 80)); // interrupt mid-flight
    await _tapTab(tester, 'Dokyu');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final barWidth = tester.getSize(find.byType(AnimatedBottomNavigation)).width;
    final segmentWidth = barWidth / _items.length;
    const bubbleSize = 60.0;
    final expectedLeft = segmentWidth * 1 + (segmentWidth - bubbleSize) / 2; // Dokyu = index 1
    expect(_indicatorLeft(tester), closeTo(expectedLeft, 0.5));
    expect(_bumpCenterX(tester), closeTo(expectedLeft + bubbleSize / 2, 0.5));
  });

  testWidgets('indicator height and vertical (top) position never change across tabs', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    double topOf(WidgetTester t) => t.widget<Positioned>(find.byKey(const ValueKey('nav-floating-indicator'))).top!;
    double heightOf(WidgetTester t) => t.widget<Positioned>(find.byKey(const ValueKey('nav-floating-indicator'))).height!;

    final initialTop = topOf(tester);
    final initialHeight = heightOf(tester);

    for (final label in ['Dokyu', 'Tulong', 'Balita', 'Emergency', 'Home']) {
      await _tapTab(tester, label);
      await tester.pumpAndSettle();
      expect(topOf(tester), initialTop);
      expect(heightOf(tester), initialHeight);
    }
  });
}
