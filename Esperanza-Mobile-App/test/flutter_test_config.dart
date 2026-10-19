// Flutter auto-discovers this file and runs testExecutable() around every
// test in this directory tree, before any test's own setUp(). Installing
// the safe default ApiClient fake here, once, means no widget test in this
// suite can ever reach the real network even if it forgets to set up its
// own fake response -- see test/support/fake_api.dart for why that matters.
import 'dart:async';

import 'package:esperanza_mobile/utils/birthday.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/utils/ambient_motion.dart';

import 'support/fake_api.dart';

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
  // The Balita birthday greeting follows the calendar; the demo accounts'
  // birthdays (June 8, February 4, October 27) would otherwise add a card
  // to the feed on those days only. A test that wants it picks the day.
  Birthday.today = () => DateTime(2026, 7, 15);
  await testMain();
}
