// How the onboarding presents itself: the owner's design (2026-10-12),
// motion preferences, screen sizes, semantics, and whether the words are true.
//
// `onboarding_flow_test.dart` covers where the controls lead and what gets
// persisted. This file covers the parts that used to be untestable, because
// until 2026-08-30 each page was a single flattened PNG — a screen reader saw
// nothing, text scaling did nothing, and the copy could not be checked at all.
// The artwork advertised "Business Permit — Approved", an outcome this app
// cannot produce, and no test could have noticed.
//
// All three pages' copy is laid out in one place, as in the design, with only
// the current one visible, touchable and announced; "showing" is therefore
// asked with `hitTestable`.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/onboarding/onboarding_page_data.dart';
import 'package:esperanza_mobile/screens/onboarding/onboarding_screen.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/utils/ambient_motion.dart';
import 'package:esperanza_mobile/utils/esperanza_seal.dart';

/// Pumps onboarding on its own, at a chosen viewport / text scale / motion
/// preference.
///
/// The `MaterialApp.builder` override is deliberate: `WidgetsApp` installs its
/// own `MediaQuery` from the view, so wrapping the app in one has no effect —
/// the override has to sit *inside*, between the app and its content.
Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool reduceMotion = false,
  bool settle = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: const OnboardingScreen(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// A horizontal drag across the photograph, in steps.
Future<void> _swipe(WidgetTester tester, {double by = -200, double dy = 0}) async {
  final photo = tester.getTopLeft(find.byKey(const Key('onboarding_photo')));
  final gesture = await tester.startGesture(Offset(photo.dx + 195, photo.dy + 200));
  const steps = 6;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(by / steps, dy / steps));
    await tester.pump();
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

/// The page currently showing: the one whose headline can be touched.
int _showing(WidgetTester tester) {
  final shown = [
    for (var i = 0; i < onboardingScenes.length; i++)
      if (find.text(onboardingScenes[i].headline).hitTestable().evaluate().isNotEmpty) i,
  ];
  expect(shown, hasLength(1), reason: 'exactly one page should be showing, saw $shown');
  return shown.single;
}

/// How opaque page [i]'s photograph is meant to be.
double _photoOpacity(WidgetTester tester, int i) =>
    tester.widget<AnimatedOpacity>(find.byKey(Key('onboarding_background_$i'))).opacity;

/// Every string the tree is currently rendering.
List<String> _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((s) => s.isNotEmpty)
    .toList();

void main() {
  // ---------------------------------------------------------------------
  // Turning the page
  // ---------------------------------------------------------------------

  testWidgets('a swipe across the photograph turns the page, both ways', (tester) async {
    await _pump(tester);
    expect(_showing(tester), 0);

    await _swipe(tester);
    expect(_showing(tester), 1);

    await _swipe(tester, by: 200);
    expect(_showing(tester), 0);
  });

  testWidgets('a short or mostly-vertical drag does not turn the page', (tester) async {
    await _pump(tester);
    // Under the design's 48px threshold.
    await _swipe(tester, by: -40);
    expect(_showing(tester), 0);
    // More down than across: someone scrolling, not swiping.
    await _swipe(tester, by: -80, dy: 160);
    expect(_showing(tester), 0);
  });

  testWidgets('the dots go straight to a page', (tester) async {
    await _pump(tester);
    await tester.tap(find.bySemanticsLabel('Go to page 3 of 3'));
    await tester.pumpAndSettle();
    expect(_showing(tester), 2);
    expect(find.byKey(const Key('onboarding_get_started')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Go to page 1 of 3'));
    await tester.pumpAndSettle();
    expect(_showing(tester), 0);
  });

  testWidgets('each page has its own photograph, and only the current one shows', (tester) async {
    await _pump(tester);
    for (var page = 0; page < onboardingScenes.length; page++) {
      if (page > 0) {
        await tester.tap(find.byKey(const Key('onboarding_next')));
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < onboardingScenes.length; i++) {
        expect(_photoOpacity(tester, i), i == page ? 1 : 0, reason: 'on page ${page + 1}, photograph ${i + 1}');
      }
    }
  });

  // ---------------------------------------------------------------------
  // Motion
  // ---------------------------------------------------------------------

  testWidgets('the photograph zooms slowly while motion is allowed, and is still otherwise', (tester) async {
    double zoom() {
      final transform = tester.widget<Transform>(
        find.descendant(of: find.byKey(const Key('onboarding_background_0')), matching: find.byType(Transform)).first,
      );
      return transform.transform.getMaxScaleOnAxis();
    }

    // Off (as for the rest of the suite): at rest.
    await _pump(tester);
    expect(zoom(), 1);
    await tester.pump(const Duration(seconds: 5));
    expect(zoom(), 1);

    // On: after a few seconds the photograph has moved in. A fresh screen,
    // since motion is decided as it opens.
    await tester.pumpWidget(const SizedBox());
    AmbientMotion.enabled = true;
    addTearDown(() => AmbientMotion.enabled = false);
    await _pump(tester, settle: false);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 16));
    expect(zoom(), greaterThan(1.005));
    // Replaced, so its endless ticker stops before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("the shield's pulsing ring takes no room: page three's rows stay one height", (tester) async {
    AmbientMotion.enabled = true;
    addTearDown(() => AmbientMotion.enabled = false);
    await _pump(tester, settle: false);
    await tester.tap(find.bySemanticsLabel('Go to page 3 of 3'));
    // Mid-pulse.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    double rowHeight(String label) =>
        tester.getSize(find.ancestor(of: find.text(label), matching: find.byType(Container)).first).height;
    expect(rowHeight('Emergency Help'), rowHeight('Official Balita'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion: nothing decorative moves, and the page is fully usable', (tester) async {
    AmbientMotion.enabled = true;
    addTearDown(() => AmbientMotion.enabled = false);
    // Settles, which it could not if anything were still looping.
    await _pump(tester, reduceMotion: true);

    // The content is all there, at full strength — reduced motion removes
    // movement, not hierarchy or information.
    expect(_showing(tester), 0);
    expect(find.text(onboardingScenes[0].subtext), findsOneWidget);
    for (final f in onboardingScenes[0].features) {
      expect(find.text(f.label), findsOneWidget);
    }
  });

  testWidgets('reduced motion: Next still advances, without waiting out an animation', (tester) async {
    await _pump(tester, reduceMotion: true);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    // A single pump, NOT pumpAndSettle: the next page is the one that can be
    // touched at once. If this ever needs settling again, a wait has come back
    // that reduced-motion users were promised they would not sit through.
    await tester.pump();

    expect(_showing(tester), 1);
  });

  // ---------------------------------------------------------------------
  // Responsiveness
  // ---------------------------------------------------------------------

  const viewports = <String, Size>{
    'compact 320x568': Size(320, 568),
    'small 360x800': Size(360, 800),
    'reference 390x844': Size(390, 844),
    'large 412x915': Size(412, 915),
    'tablet 834x1112': Size(834, 1112),
    'landscape 844x390': Size(844, 390),
  };

  for (final entry in viewports.entries) {
    for (final scale in <double>[1.0, 2.0]) {
      testWidgets('${entry.key} at text scale $scale lays out without overflow', (tester) async {
        await _pump(tester, size: entry.value, textScale: scale);

        expect(tester.takeException(), isNull, reason: 'onboarding overflowed or threw at ${entry.key}, text scale $scale');

        // Rendered something real, so a blank screen cannot pass as "no
        // overflow", and every control is still reachable.
        expect(find.text(onboardingScenes[0].headline), findsOneWidget);
        expect(find.byKey(const Key('onboarding_skip')), findsOneWidget);
        expect(find.byKey(const Key('onboarding_next')), findsOneWidget);
        expect(find.byKey(const Key('onboarding_progress')), findsOneWidget);

        // The supporting line must survive a small screen — hiding it to make
        // things fit is not a responsive layout, it is a shorter app for people
        // with smaller phones.
        expect(find.text(onboardingScenes[0].subtext), findsOneWidget);
      });
    }
  }

  testWidgets('the last page fits the smallest screen at the largest text', (tester) async {
    await _pump(tester, size: const Size(320, 568), textScale: 2.0);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
    }
    expect(_showing(tester), 2);
    expect(find.byKey(const Key('onboarding_get_started')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // Semantics
  // ---------------------------------------------------------------------

  testWidgets('the page position, Skip and the primary action are all announced', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Skip'), findsOneWidget);
    expect(find.bySemanticsLabel(onboardingBrandName), findsOneWidget);

    final next = tester.getSemantics(find.byKey(const Key('onboarding_next')));
    expect(next.flagsCollection.isButton, isTrue);
    expect(next.label, contains('Next'));

    await _swipe(tester);
    expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);

    await _swipe(tester);
    expect(find.bySemanticsLabel('Page 3 of 3'), findsOneWidget);
    // Not merely invisible — gone from the semantics tree, so it cannot be
    // focused or announced on a page where it has nothing to do.
    expect(find.bySemanticsLabel('Skip'), findsNothing);

    final start = tester.getSemantics(find.byKey(const Key('onboarding_get_started')));
    expect(start.flagsCollection.isButton, isTrue);
    expect(start.label, contains('Get Started'));

    handle.dispose();
  });

  testWidgets('only the page showing is announced, and its photograph is described once', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(find.bySemanticsLabel(onboardingScenes[0].semanticDescription), findsOneWidget);
    expect(find.bySemanticsLabel(onboardingScenes[1].semanticDescription), findsNothing);
    // The other pages' copy is laid out but not announced.
    expect(find.bySemanticsLabel(RegExp('Mag-request')), findsNothing);

    // Each capability appears exactly once as text.
    for (final f in onboardingScenes[0].features) {
      expect(find.text(f.label), findsOneWidget, reason: '"${f.label}" is rendered more than once');
    }

    handle.dispose();
  });

  // ---------------------------------------------------------------------
  // The design
  // ---------------------------------------------------------------------

  testWidgets("each headline's second line is gold, as the design sets it", (tester) async {
    await _pump(tester);
    for (final scene in onboardingScenes) {
      final text = tester.widget<Text>(find.text(scene.headline));
      final accent = (text.textSpan! as TextSpan).children!.single as TextSpan;
      expect(accent.text, scene.headlineAccent);
      expect(accent.style!.color, AppColors.gold400);
    }
  });

  testWidgets('page one shows its capabilities as tiles, pages two and three as rows', (tester) async {
    await _pump(tester);
    final tile = tester.getSize(find.ancestor(of: find.text('Resident Profile'), matching: find.byType(Container)).first);
    final row = tester.getSize(find.ancestor(of: find.text('Track Status'), matching: find.byType(Container)).first);
    expect(tile.width, lessThan(row.width / 2), reason: 'page one has three tiles across');
    expect(row.width, greaterThan(300), reason: 'pages two and three have full-width rows');
  });

  // ---------------------------------------------------------------------
  // Copy accuracy
  // ---------------------------------------------------------------------

  testWidgets('each page shows its copy, and claims nothing the app cannot do', (tester) async {
    await _pump(tester);

    final seen = <String>[];
    for (var i = 0; i < onboardingScenes.length; i++) {
      if (i > 0) await _swipe(tester);
      final scene = onboardingScenes[i];
      expect(find.text(scene.headline).hitTestable(), findsOneWidget);
      expect(find.text(scene.subtext).hitTestable(), findsOneWidget);
      seen.addAll(_visibleText(tester));
    }

    final all = seen.join(' | ');

    // The retired artwork's claim. Business permits are a real Dokyu service;
    // an onboarding screen implying one has been APPROVED is the part that was
    // never true.
    expect(all, isNot(contains('Business Permit')), reason: 'onboarding must not advertise business permits');

    // Nothing here processes, approves, or guarantees anything.
    for (final claim in ['Approved', 'instant', 'Instant', 'real-time', 'Real-time', 'guaranteed', 'Guaranteed']) {
      expect(all, isNot(contains(claim)), reason: 'onboarding claims "$claim", which no part of this app delivers');
    }

    // Events are listed, not booked.
    for (final claim in ['Register', 'Registration', 'Reserve', 'Ticket', 'RSVP']) {
      expect(all, isNot(contains(claim)), reason: 'onboarding implies event $claim, which the app does not support');
    }
  });

  test('every headline is two authored lines, and no scene is wordy', () {
    // Two short lines and one sentence. A headline that grows a third line,
    // or a paragraph of supporting copy, stops being a welcome screen and
    // becomes a page nobody reads.
    for (final scene in onboardingScenes) {
      final lines = scene.headline.split('\n');
      expect(lines, hasLength(2), reason: '${scene.id}: the headline should be exactly two authored lines');
      for (final line in lines) {
        expect(line.length, lessThanOrEqualTo(30), reason: '${scene.id}: "$line" is too long for a hero line');
      }
      expect(scene.subtext.length, lessThanOrEqualTo(130), reason: '${scene.id}: the supporting line is a paragraph');
      expect(scene.features, hasLength(3), reason: '${scene.id}: the design has three capabilities per page');
    }
  });

  // ---------------------------------------------------------------------
  // Assets
  // ---------------------------------------------------------------------

  testWidgets('every asset onboarding references is declared and loadable', (tester) async {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final scene in onboardingScenes) {
      expect(pubspec, contains(scene.backgroundAsset), reason: '${scene.backgroundAsset} is used by onboarding but not declared in pubspec.yaml');
    }
    expect(pubspec, contains(esperanzaSealAsset));

    for (final asset in [...onboardingScenes.map((s) => s.backgroundAsset), esperanzaSealAsset]) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(0), reason: '$asset is declared but empty or missing');
    }
  });

  test('the retired composite welcome artwork is gone from the runtime', () {
    // Removed from pubspec (so it no longer ships) and referenced by no source
    // file. The PNG files themselves are deliberately still on disk as design
    // references — deleting them is an owner call, and this asserts the part
    // that actually affects the app.
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('assets/images/Welcome Screen')),
      reason: 'the flattened composites are being bundled again — about 4.5 MB in every binary',
    );

    for (final dir in ['lib', 'test']) {
      for (final file in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        // This file names the retired asset in order to forbid it.
        if (file.path.endsWith('onboarding_redesign_test.dart')) continue;
        expect(file.readAsStringSync(), isNot(contains('Welcome Screen 1.png')), reason: '${file.path} still loads the retired composite artwork');
      }
    }
  });

  testWidgets('the municipal hall photo of a different province is not used here', (tester) async {
    // rectangle_cityhall.jpg is a genuine municipal hall, but the seal on its
    // facade reads "Esperanza, Agusan del Sur" — a different municipality from
    // the Esperanza, Masbate this app serves.
    await _pump(tester);
    final images = tester.widgetList<Image>(find.byType(Image)).map((i) {
      final provider = i.image;
      final asset = provider is ResizeImage ? provider.imageProvider : provider;
      return asset is AssetImage ? asset.assetName : '';
    });
    expect(images, isNot(contains(onboardingExcludedAsset)));
  });
}
