import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/main.dart';

/// Opens the app as a citizen does with no one signed in — the opening
/// animation, then the welcome pages, which open the app whenever no one is
/// signed in (owner, 2026-10-12) — and taps Skip, landing on Sign In.
Future<void> pumpAppToSignIn(WidgetTester tester) async {
  await tester.pumpWidget(const EsperanzaMobileApp());
  await tester.pumpAndSettle();
  final skip = find.byKey(const Key('onboarding_skip'));
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    await tester.pumpAndSettle();
  }
}
