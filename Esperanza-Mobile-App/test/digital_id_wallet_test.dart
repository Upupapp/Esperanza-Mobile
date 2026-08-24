// Coverage for the Digital ID credential wallet (verified Cristy
// Bonghanoy only): seeded Barangay Resident ID / PWD ID order and asset
// pairing, tap-to-flip, vertical swipe navigation (direction, bounds,
// position indicator), the information panel following the active
// credential, View Full Screen preserving the currently-shown side,
// verified/unverified gating, and that the registration-uploaded ID stays
// out of this screen entirely.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/access_level.dart';
import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';

const _stackKey = ValueKey('credential-stack');

Future<CitizenSessionService> _signedInAs(WidgetTester tester, dynamic account) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(account);
  return session;
}

Future<void> _pumpWallet(WidgetTester tester, CitizenSessionService session, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<CitizenSessionService>.value(value: session, child: const MaterialApp(home: DigitalIdScreen())),
  );
  await tester.pumpAndSettle();
}

bool _hasAssetImage(WidgetTester tester, String assetPath) {
  return tester.widgetList<Image>(find.byType(Image)).any((img) {
    final provider = img.image;
    return provider is AssetImage && provider.assetName == assetPath;
  });
}

void main() {
  group('Verified Cristy — Digital ID wallet', () {
    testWidgets('is accessible and shows Barangay Resident ID first, PWD ID second (position indicator)', (
      tester,
    ) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last); // Cristy — verified
      await _pumpWallet(tester, session);

      expect(session.accessLevel, AccessLevel.verified);
      expect(find.text('Digital ID not yet available'), findsNothing);
      expect(find.text('Barangay Resident ID'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      // Exactly the two seeded credentials — nothing else.
      expect(find.text('PWD ID'), findsNothing); // not yet active, only referenced via its own info panel
      expect(tester.takeException(), isNull);
    });

    testWidgets('Barangay front/back assets are correctly paired', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      expect(_hasAssetImage(tester, 'assets/images/BarangayID_Front.png'), isTrue);
      expect(_hasAssetImage(tester, 'assets/images/BarangayID_Back.png'), isFalse);

      await tester.tap(find.byKey(_stackKey));
      await tester.pumpAndSettle();

      expect(_hasAssetImage(tester, 'assets/images/BarangayID_Back.png'), isTrue);
      expect(_hasAssetImage(tester, 'assets/images/BarangayID_Front.png'), isFalse);
    });

    testWidgets('tap flips front -> back, second tap flips back -> front', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      expect(find.textContaining('View Full Screen (Front)'), findsOneWidget);

      await tester.tap(find.byKey(_stackKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('View Full Screen (Back)'), findsOneWidget);

      await tester.tap(find.byKey(_stackKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('View Full Screen (Front)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('swipe up moves to PWD ID; PWD front/back assets are correctly paired; position indicator updates', (
      tester,
    ) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      await tester.drag(find.byKey(_stackKey), const Offset(0, -150));
      await tester.pumpAndSettle();

      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('PWD ID'), findsOneWidget);
      // Swiping to a new credential always resets it to front.
      expect(_hasAssetImage(tester, 'assets/images/PWD_Front.png'), isTrue);
      expect(_hasAssetImage(tester, 'assets/images/PWD_Back.png'), isFalse);

      await tester.tap(find.byKey(_stackKey));
      await tester.pumpAndSettle();
      expect(_hasAssetImage(tester, 'assets/images/PWD_Back.png'), isTrue);
      expect(_hasAssetImage(tester, 'assets/images/PWD_Front.png'), isFalse);
    });

    testWidgets('swipe down from PWD ID returns to Barangay Resident ID', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      await tester.drag(find.byKey(_stackKey), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2'), findsOneWidget);

      await tester.drag(find.byKey(_stackKey), const Offset(0, 150));
      await tester.pumpAndSettle();
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('Barangay Resident ID'), findsOneWidget);
    });

    testWidgets('cannot swipe above the first credential or below the last one', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      // Already on Barangay (1 of 2) — swiping down (toward a nonexistent
      // previous credential) must do nothing.
      await tester.drag(find.byKey(_stackKey), const Offset(0, 150));
      await tester.pumpAndSettle();
      expect(find.text('1 of 2'), findsOneWidget);

      await tester.drag(find.byKey(_stackKey), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2'), findsOneWidget);

      // Already on PWD (2 of 2, the last) — swiping up further must do
      // nothing.
      await tester.drag(find.byKey(_stackKey), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a small drag well under the threshold springs back without changing credential', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      await tester.drag(find.byKey(_stackKey), const Offset(0, -10));
      await tester.pumpAndSettle();
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('Barangay Resident ID'), findsOneWidget);
    });

    testWidgets('the information panel follows the active credential', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      expect(find.text('Barangay Resident ID'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Municipality of Esperanza'), findsOneWidget);

      await tester.drag(find.byKey(_stackKey), const Offset(0, -150));
      await tester.pumpAndSettle();

      expect(find.text('PWD ID'), findsOneWidget);
      expect(find.text('Municipal Social Welfare and Development Office'), findsOneWidget);
      // The same single info-panel widget updated in place — no leftover
      // Barangay-specific issuer text still shown.
      expect(find.text('Municipality of Esperanza'), findsNothing);
    });

    testWidgets('View Full Screen opens exactly the currently displayed side', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      await tester.tap(find.byKey(_stackKey)); // flip to back
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.textContaining('View Full Screen'));
      await tester.tap(find.textContaining('View Full Screen'));
      await tester.pumpAndSettle();

      expect(find.text('Barangay Resident ID — Back'), findsOneWidget);
      expect(_hasAssetImage(tester, 'assets/images/BarangayID_Back.png'), isTrue);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('no RenderFlex overflow on a narrow viewport', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session, size: const Size(320, 640));
      expect(tester.takeException(), isNull);

      await tester.drag(find.byKey(_stackKey), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('exactly the two seeded credentials — the registration ID never appears here', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.last);
      await _pumpWallet(tester, session);

      expect(find.text('1 of 2'), findsOneWidget); // total is exactly 2
      expect(find.text('Submitted Government ID'), findsNothing);
      expect(find.text('Postal ID (PHLPost)'), findsNothing);
      expect(_hasAssetImage(tester, 'assets/images/CRISTY DEMO ID.png'), isFalse);
    });
  });

  group('Unverified accounts — no active credentials', () {
    testWidgets('Ronaldo (unverified) sees the locked state, never the wallet', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.first); // Ronaldo — unverified
      await _pumpWallet(tester, session);

      expect(session.accessLevel, AccessLevel.unverified);
      expect(find.text('Digital ID not yet available'), findsOneWidget);
      expect(find.text('Barangay Resident ID'), findsNothing);
      expect(find.text('PWD ID'), findsNothing);
      expect(find.byKey(_stackKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('duplicate Cristy registration (still Pending Review) also sees the locked state', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.duplicateCristyAccount);
      await _pumpWallet(tester, session);

      expect(session.accessLevel, AccessLevel.unverified);
      expect(find.text('Digital ID not yet available'), findsOneWidget);
      expect(find.text('Barangay Resident ID'), findsNothing);
      expect(find.text('PWD ID'), findsNothing);
    });
  });
}
