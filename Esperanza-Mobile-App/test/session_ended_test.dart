// When the server ends the sign-in (an expired or revoked token, or a removed
// account) while the resident is on a page opened over Home, the app goes
// back to the sign-in screen and says why. It used to leave that page showing
// "Authentication is required" with a Try Again that could never work
// (owner's screenshot, 2026-10-13).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/auth/login_screen.dart';
import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';

import 'support/fake_api.dart';
import 'support/start_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  testWidgets('a page left open when the server ends the session closes onto sign-in, with the reason', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Home loads normally; then the server stops knowing the token, as when
    // the account was removed, and the Digital ID's load comes back 401.
    var ended = false;
    FakeApi.installFull((r) {
      if (ended || r.path == '/citizen/wallet') {
        ended = true;
        throw const FakeApiError(status: 401, code: 'UNAUTHENTICATED', messageEn: 'Authentication is required.');
      }
      return r.path.endsWith('s') ? <dynamic>[] : <String, dynamic>{};
    });

    await pumpAppToSignIn(tester);
    final ctx = tester.element(find.byType(MaterialApp));
    await ctx.read<CitizenSessionService>().login(MockCatalog.demoAccounts.last);
    await tester.pumpAndSettle();

    // Open the Digital ID over Home; its load comes back 401.
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(MaterialPageRoute(builder: (_) => const DigitalIdScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.byType(DigitalIdScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Your session has ended. Please sign in again.'), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
  });
}
