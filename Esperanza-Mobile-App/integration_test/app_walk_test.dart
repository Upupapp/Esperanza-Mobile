// FE 03 — walks the real app on a real device/simulator.
//
// Why this exists rather than a manual walk: OS-level synthetic taps need an
// Accessibility grant that is per-machine and not portable, and a walk nobody
// can repeat is not evidence. `integration_test` drives the app from inside its
// own process, so it taps *widgets* rather than screen coordinates — it works
// on any machine, on a simulator or real hardware, and it can live in the repo
// as a gate.
//
// What this catches that `flutter test` cannot: the widget suite renders at an
// 800x600 surface with aspect 1.33. A phone is ~0.46. Layout that overflows on
// a real device is invisible at the test surface — see the onboarding
// letterbox finding in docs/FE03_DEVICE_VERIFICATION.md, which no widget test
// could have seen.
//
// Run:
//   flutter test integration_test/app_walk_test.dart -d <simulator-udid>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart' as app;

/// Screens actually reached, so the report states a measured number rather than
/// an intended one.
final visited = <String>[];

/// Layout overflows and other framework errors seen during the walk, keyed by
/// the screen that was on-screen at the time.
final problems = <String>[];

Future<void> _settle(WidgetTester tester, {int seconds = 3}) async {
  // Not pumpAndSettle: this app runs looping/parallax animations on several
  // screens, and pumpAndSettle would time out waiting for a frame budget that
  // never empties.
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Taps [finder] if it is there, records the screen, and reports rather than
/// throwing when it is not — a walk that dies on the first missing widget
/// tells you about one screen instead of forty.
/// Every `Text` currently on screen — the only reliable way to find out why a
/// finder missed, rather than guessing at the widget tree from source.
List<String> _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((t) => t.trim().isNotEmpty)
    .toList();

Future<bool> _tapIfPresent(WidgetTester tester, Finder finder, String label) async {
  if (finder.evaluate().isEmpty) {
    problems.add('NOT REACHED: $label — on screen instead: ${_visibleText(tester).take(18).join(" | ")}');
    return false;
  }
  // Scroll it into view first. A target below the fold is hit-tested at a
  // location nothing occupies, so the tap silently does nothing — which is how
  // the first version of this walk "signed in" without leaving the sign-in
  // screen. `warnIfMissed` stays ON for the same reason: it is the only thing
  // that reports that failure.
  try {
    await tester.ensureVisible(finder.first);
    await _settle(tester, seconds: 1);
  } catch (_) {
    // Not inside a scrollable — tap it where it is.
  }
  try {
    await tester.tap(finder.first);
  } catch (error) {
    problems.add('TAP MISSED: $label — ${error.toString().split("\n").first}');
    return false;
  }
  await _settle(tester);
  visited.add(label);
  return true;
}

/// Confirms a screen by something only that screen shows, so the walk records
/// what it actually reached rather than what it attempted.
bool _confirm(WidgetTester tester, String screen, Finder marker) {
  if (marker.evaluate().isEmpty) {
    problems.add('NOT CONFIRMED: $screen — on screen instead: ${_visibleText(tester).take(12).join(" | ")}');
    return false;
  }
  visited.add(screen);
  return true;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Start from a first-run state so the walk always covers onboarding.
    SharedPreferences.setMockInitialValues({});
  });

  /// The walk itself, so it can be replayed under different conditions.
  Future<void> walk(WidgetTester tester) async {
    // Capture layout overflows instead of letting them fail the run outright:
    // the point of a first device walk is to enumerate them, not stop at one.
    final priorOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      problems.add('RENDER ERROR after ${visited.isEmpty ? "launch" : visited.last}: '
          '${details.exceptionAsString().split("\n").first}');
    };
    addTearDown(() => FlutterError.onError = priorOnError);

    app.main();
    await _settle(tester, seconds: 5);
    visited.add('Splash → Onboarding');

    // ── Onboarding ───────────────────────────────────────────────────────
    await _tapIfPresent(tester, find.text('Skip'), 'Onboarding: Skip');

    // ── Sign in as the verified demo citizen ─────────────────────────────
    // Perlita Quiambao is the verified synthetic identity introduced by FE 02.
    _confirm(tester, 'Sign in', find.text('Welcome back'));
    // textContaining('Perlita') also matches "Demo: Duplicate Perlita Account";
    // the exact full name is the verified account's own card.
    final verified = find.text('Perlita Quiambao');
    if (!await _tapIfPresent(tester, verified, 'Sign in: tap verified demo account')) {
      await _tapIfPresent(tester, find.text('Continue as Guest'), 'Sign in: Continue as Guest');
    }
    await _settle(tester, seconds: 5);
    // Home is confirmed by the nav bar, not assumed from the tap succeeding.
    _confirm(tester, 'Home', find.text('Balita'));

    // ── The four bottom-nav destinations ─────────────────────────────────
    for (final tab in ['Balita', 'Events', 'Emergency', 'Home']) {
      await _tapIfPresent(tester, find.text(tab), 'Tab: $tab');
    }

    // ── Drawer destinations ──────────────────────────────────────────────
    // home_screen.dart taps Icons.menu_rounded to call Scaffold.of().openDrawer()
    final drawerButton = find.byIcon(Icons.menu_rounded);
    if (drawerButton.evaluate().isNotEmpty) {
      await _tapIfPresent(tester, drawerButton, 'Drawer: open');
      await _tapIfPresent(tester, find.text('Government Directory'), 'Government Directory');
      await tester.pageBack();
      await _settle(tester);

      await _tapIfPresent(tester, drawerButton, 'Drawer: reopen');
      await _tapIfPresent(tester, find.text('Help & Support'), 'Help & Support');
      await tester.pageBack();
      await _settle(tester);
    } else {
      problems.add('NOT REACHED: drawer — no Icons.menu_rounded on screen');
    }

    // ── Report ───────────────────────────────────────────────────────────
    // Printed rather than asserted: the first walk's job is to produce an
    // inventory. Turning any of it into a hard assertion is a later step, once
    // the baseline is known and agreed.
    debugPrint('=== WALK: ${visited.length} screens reached ===');
    for (final v in visited) {
      debugPrint('  visited: $v');
    }
    debugPrint('=== WALK: ${problems.length} problems ===');
    for (final p in problems) {
      debugPrint('  problem: $p');
    }

    // The one hard contract: the app must still be running and rendering.
    expect(find.byType(MaterialApp), findsOneWidget, reason: 'the app died during the walk');
    binding.reportData = <String, dynamic>{'visited': visited, 'problems': problems};
  }

  testWidgets('walk the citizen app end to end on a device', (tester) async {
    await walk(tester);
  });

  // ATTEMPTED AND NOT WORKING — a second pass at 200% text scale, which is
  // where this app's layout is most likely to break (597 fixed-size SizedBox
  // constructions, 433 hardcoded fontSize values) and which neither the widget
  // suite nor a default-scale device walk can see.
  //
  // It is not here because a second `testWidgets` in this file has to call
  // `app.main()` again, and a second `runApp` in the same process hangs the
  // run rather than restarting the app. Both attempts were killed at the
  // 10-minute mark with no output.
  //
  // The fix is a separate entry point that pumps the widget tree under a
  // MediaQuery with the scale applied, rather than re-running main(). Left as
  // the next step for FE 05 rather than shipped as a skipped test — a skipped
  // test reads as a passing one in the summary line.
}
