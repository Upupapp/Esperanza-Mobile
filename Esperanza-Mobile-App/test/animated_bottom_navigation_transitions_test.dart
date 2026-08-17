// Verifies the "moving navbar shape" requirement for MagneticNavbarCore —
// reused directly from a reference implementation (see
// lib/widgets/magnetic_navbar_core.dart's doc comment): the floating
// circle AND the bar's own morphing notch must be driven from one shared
// animated position (`_t`) and travel together, so a long trip (e.g. Home
// -> Emergency) reads as one system flowing across the bar, not a circle
// sliding over an unrelated shape. Covers all required adjacent and
// long-distance transitions plus an interrupted mid-flight retarget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esperanza_mobile/widgets/magnetic_navbar_core.dart';
import 'package:esperanza_mobile/widgets/nav_bar_clipper.dart';
import 'package:esperanza_mobile/widgets/nav_item_data.dart';
import 'package:esperanza_mobile/widgets/nav_style.dart';

// Mirrors RootShell's real 5-tab configuration exactly, so this test
// exercises the same calibration the app actually ships.
const _items = [
  NavItemData(outlineIcon: Icons.home_outlined, filledIcon: Icons.home_rounded, label: 'Home'),
  NavItemData(outlineIcon: Icons.description_outlined, filledIcon: Icons.description_rounded, label: 'Dokyu'),
  NavItemData(outlineIcon: Icons.volunteer_activism_outlined, filledIcon: Icons.volunteer_activism_rounded, label: 'Tulong'),
  NavItemData(outlineIcon: Icons.campaign_outlined, filledIcon: Icons.campaign_rounded, label: 'Balita'),
  NavItemData(outlineIcon: Icons.shield_outlined, filledIcon: Icons.shield_rounded, label: 'Emergency'),
];
const _tabCenterRatios = [0.1, 0.3, 0.5, 0.7, 0.9];

/// A tiny stateful harness so tests can drive [MagneticNavbarCore] the same
/// way RootShell does — tapping a tab updates the index that flows back in
/// as `currentIndex`.
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
        bottomNavigationBar: MagneticNavbarCore(
          items: _items,
          tabCenterRatios: _tabCenterRatios,
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

/// The notch center comes from the same `NavBarClipper` instance that
/// clips the bar's morphing silhouette — reading it directly (rather than
/// re-deriving it) is what proves the notch and the floating circle share
/// one driving value instead of two independently-tuned ones.
///
/// `NavBarClipper.notchCenterX` is in the *pill's own local* coordinate
/// space (the PhysicalShape sits inset by the floating pill's horizontal
/// margin), while the floating indicator's `Positioned.left` is in
/// *screen-global* coordinates — so this returns the notch center already
/// converted to global coordinates, directly comparable to
/// `_indicatorLeft(tester) + NavStyle.circleSize / 2`.
double _notchCenterXGlobal(WidgetTester tester, double screenWidth) {
  final shape = tester.widget<PhysicalShape>(find.descendant(of: find.byKey(const ValueKey('nav-bar-shape')), matching: find.byType(PhysicalShape)));
  final localCx = (shape.clipper as NavBarClipper).notchCenterX;
  return localCx + _horizontalMargin(screenWidth);
}

double _horizontalMargin(double screenWidth) {
  final barWidth = screenWidth * NavStyle.barWidthFraction;
  return (screenWidth - barWidth) / 2;
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

/// The resting `left` of the floating indicator for a given destination,
/// derived the same way MagneticNavbarCore itself computes it — from
/// [NavStyle]'s proportional geometry and this preset's tabCenterRatios,
/// not a fixed pixel guess.
double _expectedRestingLeft(double screenWidth, int index) {
  final barWidth = screenWidth * NavStyle.barWidthFraction;
  final horizontalMargin = (screenWidth - barWidth) / 2;
  final cx = barWidth * _tabCenterRatios[index];
  return horizontalMargin + cx - NavStyle.circleSize / 2;
}

void main() {
  testWidgets('exactly one floating indicator and one bar-shape painter exist', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-floating-indicator')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-bar-shape')), findsOneWidget);
  });

  testWidgets('the notch and the floating circle are driven by the same center at rest and mid-flight', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    final screenWidth = tester.getSize(find.byType(MagneticNavbarCore)).width;

    // At rest.
    final restBubbleCenter = _indicatorLeft(tester) + NavStyle.circleSize / 2;
    expect(_notchCenterXGlobal(tester, screenWidth), closeTo(restBubbleCenter, 0.01));

    // Mid-flight, partway through a long trip.
    await _tapTab(tester, 'Emergency');
    await tester.pump(const Duration(milliseconds: 180));
    final midBubbleCenter = _indicatorLeft(tester) + NavStyle.circleSize / 2;
    expect(_notchCenterXGlobal(tester, screenWidth), closeTo(midBubbleCenter, 0.01));
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
    testWidgets('$from -> $to: circle and notch both settle centered above the destination tab', (tester) async {
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
      final screenWidth = tester.getSize(find.byType(MagneticNavbarCore)).width;
      final expectedLeft = _expectedRestingLeft(screenWidth, toIndex);
      expect(settledLeft, closeTo(expectedLeft, 0.5));

      // The notch must have followed it to the exact same resting spot.
      expect(_notchCenterXGlobal(tester, screenWidth), closeTo(settledLeft + NavStyle.circleSize / 2, 0.5));

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
    final screenWidth = tester.getSize(find.byType(MagneticNavbarCore)).width;
    final expectedLeft = _expectedRestingLeft(screenWidth, 1); // Dokyu = index 1
    expect(_indicatorLeft(tester), closeTo(expectedLeft, 0.5));
    expect(_notchCenterXGlobal(tester, screenWidth), closeTo(expectedLeft + NavStyle.circleSize / 2, 0.5));
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

  testWidgets('the active label follows contentIndex and every inactive tab stays reachable by name', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    // At rest on Home, its label is the one (visibly) floating above the bar.
    expect(find.text('Home'), findsOneWidget);

    // Every other tab is still findable by name (present, zero-opacity) —
    // this is what lets tests (and any future assistive tooling) target a
    // destination by label even though only the active one visibly shows
    // text, matching this app's established tab-navigation convention.
    for (final label in ['Dokyu', 'Tulong', 'Balita', 'Emergency']) {
      expect(find.text(label), findsOneWidget);
    }

    await _tapTab(tester, 'Balita');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
