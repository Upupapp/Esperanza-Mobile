// Flutter auto-discovers this file and runs testExecutable() around every
// test in this directory tree, before any test's own setUp(). Installing
// the safe default ApiClient fake here, once, means no widget test in this
// suite can ever reach the real network even if it forgets to set up its
// own fake response -- see test/support/fake_api.dart for why that matters.
import 'dart:async';

import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/device_location.dart';
import 'package:esperanza_mobile/widgets/sakuna_map.dart';
import 'package:esperanza_mobile/utils/ambient_motion.dart';

import 'support/fake_api.dart';
import 'package:esperanza_mobile/widgets/popup_gate.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FakeApi.installDefault();
  // Endless decorative motion (the welcome photo's slow zoom, a shine) never
  // settles, and pumpAndSettle waits for everything to settle. A test that
  // wants it turns it back on.
  AmbientMotion.enabled = false;
  // The phone's Keystore/Keychain is a platform plugin with no test
  // double: under a widget test's fake clock a call to it never returns.
  // Tests keep the token in the (mocked) plain store; the secure store's
  // own tests install a fake one (citizen_app_scope_test.dart).
  ApiClient.secureStore = null;
  // Sakuna's map (2026-10-26): no tiles from the network, and no GPS. A test
  // that taps "Use my location" sets DeviceLocation.locate itself; one that
  // forgets gets "could not find its location", never a real position.
  MapTiles.enabled = false;
  DeviceLocation.locate = () async => const LocationResult.failed(LocationProblem.unavailable);
  // One pop-up at a time is a flag shared across the app: a test that ends
  // with a pop-up open must not hold back the next test's.
  setUp(() => PopupGate.open.value = false);
  await testMain();
}
