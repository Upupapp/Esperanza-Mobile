// Verifies the "moving navbar shape" requirement for EsperanzaCurvedNavBar —
// a direct port of the Servana Client App's curved main navigation (see
// lib/widgets/esperanza_curved_navbar.dart's doc comment): the travelling
// bubble AND the bar surface's own cradle dip must be driven from one
// shared interpolated x, so a long trip (e.g. Home -> Emergency) reads as
// one system flowing across the bar, not a circle sliding over an
// unrelated shape. Covers all required tab-to-tab transitions plus
// entering/leaving the center launcher's active state (Dokyu/Tulong).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esperanza_mobile/widgets/esperanza_center_action.dart';
import 'package:esperanza_mobile/widgets/esperanza_curved_navbar.dart';
import 'package:esperanza_mobile/widgets/esperanza_curved_nav_painter.dart';
import 'package:esperanza_mobile/widgets/esperanza_nav_item.dart';
import 'package:esperanza_mobile/widgets/esperanza_nav_motion.dart';
import 'package:esperanza_mobile/widgets/nav_item_data.dart';
import 'package:esperanza_mobile/widgets/service_launcher_menu.dart';

// Mirrors RootShell's real 4-tab configuration exactly, so this test
// exercises the same calibration the app actually ships.
const _items = [
  NavItemData(outlineIcon: Icons.home_outlined, filledIcon: Icons.home_rounded, label: 'Home'),
  NavItemData(outlineIcon: Icons.campaign_outlined, filledIcon: Icons.campaign_rounded, label: 'Balita'),
  NavItemData(outlineIcon: Icons.event_outlined, filledIcon: Icons.event_rounded, label: 'Events'),
  NavItemData(outlineIcon: Icons.shield_outlined, filledIcon: Icons.shield_rounded, label: 'Emergency'),
];

/// A tiny stateful harness so tests can drive [EsperanzaCurvedNavBar] the
/// same way RootShell does — tapping a tab updates the active index that
/// flows back in, and tapping "+" enters the launcher-active state.
class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int? index = 0;
  ServiceLauncherTarget? activeTarget;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: EsperanzaCurvedNavBar(
          items: _items,
          activeIndex: index,
          activeLauncherTarget: activeTarget,
          onTabSelected: (i) => setState(() {
            index = i;
            activeTarget = null;
          }),
          onCenterPressed: () => setState(() {
            index = null;
            activeTarget = ServiceLauncherTarget.dokyu;
          }),
        ),
      ),
    );
  }
}

/// The bubble's actual on-screen x at this instant. `AnimatedPositioned` is
/// an implicit animation — its `left` field always holds the *target*, not
/// the live interpolated value, so reading the widget directly would give
/// the destination even mid-flight. `getTopLeft` reads the real rendered
/// geometry instead, which reflects wherever Flutter's implicit-animation
/// machinery has actually interpolated to at this frame.
double _indicatorLeft(WidgetTester tester) {
  return tester.getTopLeft(find.byType(EsperanzaActiveBubble)).dx;
}

double _cradleCentreX(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(find.byKey(const ValueKey('nav-bar-shape')));
  return (paint.painter as EsperanzaCurvedNavPainter).cradleCentreX;
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

Future<void> _tapCenter(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('nav-center-action')));
  await tester.pump();
}

/// The resting `left` of the floating indicator for a given tab index,
/// derived the same way EsperanzaCurvedNavBar itself computes it — five
/// equal slots, skipping the reserved center one.
double _expectedRestingLeft(double screenWidth, int itemIndex) {
  const slotCount = 5;
  final slotWidth = screenWidth / slotCount;
  final slot = itemIndex < 2 ? itemIndex : itemIndex + 1;
  final minCentre = EsperanzaNavMotion.bubbleDiameter / 2 + EsperanzaNavMotion.surfaceRadius * 0.5;
  final rawCentreX = (slot + 0.5) * slotWidth;
  final centreX = rawCentreX.clamp(minCentre, screenWidth - minCentre);
  return centreX - EsperanzaNavMotion.bubbleDiameter / 2;
}

void main() {
  testWidgets('exactly one floating indicator and one bar-shape painter exist', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-floating-indicator')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-bar-shape')), findsOneWidget);
  });

  testWidgets('the cradle and the floating bubble are driven by the same center at rest and mid-flight', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    // At rest.
    final restBubbleCenter = _indicatorLeft(tester) + EsperanzaNavMotion.bubbleDiameter / 2;
    expect(_cradleCentreX(tester), closeTo(restBubbleCenter, 0.01));

    // Mid-flight, partway through a long trip.
    await _tapTab(tester, 'Emergency');
    await tester.pump(const Duration(milliseconds: 180));
    final midBubbleCenter = _indicatorLeft(tester) + EsperanzaNavMotion.bubbleDiameter / 2;
    expect(_cradleCentreX(tester), closeTo(midBubbleCenter, 0.01));
    // And it should have actually moved from the resting position by now.
    expect(midBubbleCenter, isNot(closeTo(restBubbleCenter, 1.0)));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  final transitions = <List<String>>[
    ['Home', 'Balita'],
    ['Balita', 'Events'],
    ['Events', 'Emergency'],
    ['Emergency', 'Home'],
    ['Home', 'Events'], // non-adjacent
    ['Home', 'Emergency'], // full-width trip
    ['Emergency', 'Balita'], // full-width trip back, different destination
  ];

  for (final t in transitions) {
    final from = t[0];
    final to = t[1];
    testWidgets('$from -> $to: bubble and cradle both settle centered above the destination tab', (tester) async {
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
      final screenWidth = tester.getSize(find.byType(EsperanzaCurvedNavBar)).width;
      final expectedLeft = _expectedRestingLeft(screenWidth, toIndex);
      expect(settledLeft, closeTo(expectedLeft, 0.5));

      // The cradle must have followed it to the exact same resting spot.
      expect(_cradleCentreX(tester), closeTo(settledLeft + EsperanzaNavMotion.bubbleDiameter / 2, 0.5));

      if (fromIndex != toIndex) {
        expect(settledLeft, isNot(closeTo(startLeft, 0.5)));
      }
    });
  }

  testWidgets('interrupted mid-flight tap (Home -> Emergency -> Balita) redirects smoothly and settles correctly', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    await _tapTab(tester, 'Emergency');
    await tester.pump(const Duration(milliseconds: 80)); // interrupt mid-flight
    await _tapTab(tester, 'Balita');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final screenWidth = tester.getSize(find.byType(EsperanzaCurvedNavBar)).width;
    final expectedLeft = _expectedRestingLeft(screenWidth, 1); // Balita = index 1
    expect(_indicatorLeft(tester), closeTo(expectedLeft, 0.5));
    expect(_cradleCentreX(tester), closeTo(expectedLeft + EsperanzaNavMotion.bubbleDiameter / 2, 0.5));
  });

  testWidgets('opening the center launcher hides the tab bubble and pulls the cradle to the center slot', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    await _tapCenter(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // No real tab is active, so the travelling bubble is not rendered at all.
    expect(find.byKey(const ValueKey('nav-floating-indicator')), findsNothing);

    final screenWidth = tester.getSize(find.byType(EsperanzaCurvedNavBar)).width;
    final centerSlotX = screenWidth / 2; // slot 2 of 5, i.e. dead-center
    expect(_cradleCentreX(tester), closeTo(centerSlotX, 0.5));

    final center = tester.widget<EsperanzaCenterAction>(find.byType(EsperanzaCenterAction));
    expect(center.activeIcon, ServiceLauncherTarget.dokyu.icon);
    expect(center.activeAccent, ServiceLauncherTarget.dokyu.accent);

    // Returning to a real tab restores the bubble and releases the "+"'s
    // active treatment.
    await _tapTab(tester, 'Home');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-floating-indicator')), findsOneWidget);
    final restedCenter = tester.widget<EsperanzaCenterAction>(find.byType(EsperanzaCenterAction));
    expect(restedCenter.activeIcon, isNull);
    expect(restedCenter.activeAccent, isNull);
  });

  testWidgets('indicator height and vertical (top) position never change across tabs', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    double topOf(WidgetTester t) => t.widget<AnimatedPositioned>(find.byKey(const ValueKey('nav-floating-indicator'))).top!;

    final initialTop = topOf(tester);

    for (final label in ['Balita', 'Events', 'Emergency', 'Home']) {
      await _tapTab(tester, label);
      await tester.pumpAndSettle();
      expect(topOf(tester), initialTop);
    }
  });

  testWidgets('every tab label stays visible regardless of which tab is active', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.pumpAndSettle();

    // At rest on Home — every label is visible, not only the active one
    // (this differs deliberately from the old floating-pill navbar's
    // active-only label, matching the Servana source exactly).
    for (final label in ['Home', 'Balita', 'Events', 'Emergency']) {
      expect(find.text(label), findsOneWidget);
    }

    await _tapTab(tester, 'Balita');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in ['Home', 'Balita', 'Events', 'Emergency']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
