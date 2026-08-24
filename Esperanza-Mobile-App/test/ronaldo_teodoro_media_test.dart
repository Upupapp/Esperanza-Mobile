// Coverage for Ronaldo Bautista's and Teodoro Villaflor's profile photo +
// submitted government ID — the same single-source-of-truth architecture
// already used for Cristy (see utils/demo_resident_photo.dart and
// utils/government_id.dart), just extended to two more seeded residents.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/access_level.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/utils/demo_resident_photo.dart';
import 'package:esperanza_mobile/utils/government_id.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

Future<CitizenSessionService> _signedInAs(WidgetTester tester, CitizenAccount account) async {
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

Future<void> _pumpDigitalId(WidgetTester tester, CitizenSessionService session) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<CitizenSessionService>.value(value: session, child: const MaterialApp(home: DigitalIdScreen())),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Asset lookups (no widgets — proves the single source of truth resolves correctly)', () {
    test('Ronaldo has his own profile photo and government ID, distinct from Cristy and Teodoro', () {
      final ronaldo = MockCatalog.demoAccounts.first;
      expect(ronaldo.firstName, 'Ronaldo');
      final photo = demoProfileImageFor(ronaldo) as AssetImage?;
      expect(photo?.assetName, ronaldoProfilePhotoAsset);
      expect(ronaldoProfilePhotoAsset, 'assets/images/Ronaldo Bautista.png');

      final id = governmentIdFor(ronaldo);
      expect(id, isNotNull);
      expect(id!.assetPath, 'assets/images/RONALDO ID DEMO.png');
      expect(id.accountId, ronaldo.id);
    });

    test('Both Teodoro duplicate accounts share the same photo and the same government ID record', () {
      final a = MockCatalog.unverifiedDuplicateAccountA;
      final b = MockCatalog.unverifiedDuplicateAccountB;
      expect(a.id, isNot(b.id)); // distinct accounts internally

      final photoA = demoProfileImageFor(a) as AssetImage?;
      final photoB = demoProfileImageFor(b) as AssetImage?;
      expect(photoA?.assetName, theodoroProfilePhotoAsset);
      expect(photoB?.assetName, theodoroProfilePhotoAsset);
      expect(theodoroProfilePhotoAsset, 'assets/images/Theodoro Milaflor.png');

      final idA = governmentIdFor(a);
      final idB = governmentIdFor(b);
      expect(idA, isNotNull);
      expect(idA!.assetPath, 'assets/images/THEODORO ID DEMO.png');
      expect(idA, same(idB)); // literally the same record, not two copies
    });

    test('an unrelated account (Cristy) never resolves to Ronaldo or Teodoro assets', () {
      final cristy = MockCatalog.demoAccounts.last;
      final photo = demoProfileImageFor(cristy) as AssetImage?;
      expect(photo?.assetName, isNot(ronaldoProfilePhotoAsset));
      expect(photo?.assetName, isNot(theodoroProfilePhotoAsset));
      expect(governmentIdFor(cristy)!.assetPath, isNot('assets/images/RONALDO ID DEMO.png'));
    });
  });

  group('Digital ID screen', () {
    // The registration-uploaded ID document is a different concept from the
    // Esperanza Digital ID and is never shown on this screen — see Profile >
    // Personal Information's own coverage in submitted_government_id_test.dart.
    testWidgets('Ronaldo (Unverified): no Esperanza Digital ID, and no registration ID document either', (tester) async {
      final session = await _signedInAs(tester, MockCatalog.demoAccounts.first);
      expect(session.account!.firstName, 'Ronaldo');
      expect(session.accessLevel, AccessLevel.unverified);
      expect(session.account!.status, 'Pending Review');

      await _pumpDigitalId(tester, session);

      expect(find.text('Esperanza Digital ID'), findsNothing);
      expect(find.text('Digital ID not yet available'), findsOneWidget);
      expect(find.text('Submitted ID Document'), findsNothing);
      expect(find.text('Esperanza Resident ID'), findsNothing);
      expect(find.byType(AppButton), findsNothing);

      // Ronaldo remains Unverified — an uploaded/submitted ID never
      // implies verification on its own.
      expect(session.account!.status, 'Pending Review');
      expect(session.accessLevel, AccessLevel.unverified);
    });

    testWidgets('Teodoro Account A (Unverified duplicate): no registration ID document, no verified Digital ID', (
      tester,
    ) async {
      final session = await _signedInAs(tester, MockCatalog.unverifiedDuplicateAccountA);
      await _pumpDigitalId(tester, session);

      expect(find.text('Esperanza Digital ID'), findsNothing);
      expect(find.text('Submitted ID Document'), findsNothing);
      expect(find.text('Esperanza Resident ID'), findsNothing);
      expect(session.account!.status, 'Pending Review');
    });

    testWidgets('Teodoro Account B (Unverified duplicate): no registration ID document, no verified Digital ID', (
      tester,
    ) async {
      final session = await _signedInAs(tester, MockCatalog.unverifiedDuplicateAccountB);
      await _pumpDigitalId(tester, session);

      expect(find.text('Esperanza Digital ID'), findsNothing);
      expect(find.text('Submitted ID Document'), findsNothing);
      expect(find.text('Esperanza Resident ID'), findsNothing);
      expect(session.account!.status, 'Pending Review');
    });
  });
}
