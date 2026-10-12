// Flutter auto-discovers this file and runs testExecutable() around every
// test in this directory tree, before any test's own setUp(). Installing
// the safe default ApiClient fake here, once, means no widget test in this
// suite can ever reach the real network even if it forgets to set up its
// own fake response -- see test/support/fake_api.dart for why that matters.
import 'dart:async';

import 'package:esperanza_mobile/utils/ambient_motion.dart';

import 'support/fake_api.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FakeApi.installDefault();
  // Endless decorative motion (the welcome photo's slow zoom, a shine) never
  // settles, and pumpAndSettle waits for everything to settle. A test that
  // wants it turns it back on.
  AmbientMotion.enabled = false;
  await testMain();
}
