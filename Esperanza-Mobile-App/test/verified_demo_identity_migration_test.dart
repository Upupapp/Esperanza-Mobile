// Coverage for the Perlita-Quiambao-to-Perlita-Quiambao demo identity
// correction — specifically the parts a static source-code read can't
// prove: that a browser which already persisted the OLD stale identity to
// SharedPreferences (session snapshot) gets migrated to the correct Perlita
// Quiambao identity on next load, without the user manually clearing
// storage.
//
// This used to also cover RequestsService migrating a persisted seeded-demo
// request (and its already-generated receipt) created under the old
// identity. RequestsService no longer seeds, persists, or migrates anything
// -- the server is the only source of truth for a request's own state now
// (production-readiness programme, 2026-09-25) -- and Receipt was deleted
// along with the rest of the payment/receipt feature, so that group was
// removed rather than kept pointed at a migration that no longer exists.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/access_level.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

/// The exact CitizenAccount snapshot a browser would have persisted before
/// this correction — same shape login() would have jsonEncode'd.
final _staleVerifiedAccountJson = jsonEncode(
  CitizenAccount(
    id: 'ESP-RES-2024-1203',
    firstName: 'Perlita',
    lastName: 'Quiambao',
    email: 'perlita.quiambao@example.com',
    mobile: '0919 000 9002',
    barangay: 'Baras',
    purok: 'Purok 2',
    address: 'Purok 2, Barangay Baras, Esperanza, Masbate',
    birthdate: 'September 3, 1988',
    sex: 'Female',
    civilStatus: 'Married',
    occupation: 'Market Vendor',
    profileCompleteness: 90,
    status: 'Approved',
  ).toJson(),
);

final _staleDuplicateAccountJson = jsonEncode(
  CitizenAccount(
    id: 'ESP-RES-2024-1203-DUP',
    firstName: 'Perlita',
    lastName: 'Quiambao',
    email: 'perlita.quiambao.dup@example.com',
    mobile: '0919 000 9002',
    barangay: 'Baras',
    purok: 'Purok 2',
    address: 'Purok 2, Barangay Baras, Esperanza, Masbate',
    birthdate: 'September 3, 1988',
    sex: 'Female',
    civilStatus: 'Married',
    occupation: 'Market Vendor',
    profileCompleteness: 35,
    status: 'Pending Review',
  ).toJson(),
);

void main() {
  group('CitizenSessionService migrates a stale persisted account', () {
    testWidgets('a browser signed in as the old verified snapshot now sees Perlita Quiambao', (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_citizen_session': _staleVerifiedAccountJson});
      final session = CitizenSessionService();
      var attempts = 0;
      while (session.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }

      expect(session.account!.id, 'ESP-RES-2024-9002');
      expect(session.account!.fullName, 'Perlita Quiambao');
      expect(session.account!.email, 'perlita.quiambao@example.com');

      // The migration also re-persists the corrected snapshot — a later
      // restore (without this migration running again) must still be
      // correct, proving it wasn't just corrected in memory.
      final prefs = await SharedPreferences.getInstance();
      final resaved = jsonDecode(prefs.getString('esperanza_citizen_session')!) as Map<String, dynamic>;
      expect(resaved['id'], 'ESP-RES-2024-9002');
      expect(resaved['firstName'], 'Perlita');
    });

    testWidgets('a browser signed in as the old duplicate snapshot now sees the duplicate Perlita account', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'esperanza_citizen_session': _staleDuplicateAccountJson});
      final session = CitizenSessionService();
      var attempts = 0;
      while (session.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }

      expect(session.account!.id, MockCatalog.duplicateVerifiedDemoAccount.id);
      expect(session.account!.fullName, 'Perlita Quiambao');
      expect(session.account!.status, 'Pending Review');
    });

    testWidgets('an account unrelated to the demo identity is left untouched', (tester) async {
      final unrelated = CitizenAccount(
        id: 'ESP-RES-2026-9003',
        firstName: 'Anacleto',
        lastName: 'Dimaculangan',
        email: 'anacleto.dimaculangan@example.com',
        mobile: '0918 000 9003',
        barangay: 'Libertad',
        purok: 'Purok 3',
        address: 'Purok 3, Barangay Libertad, Esperanza, Masbate',
        birthdate: 'October 27, 1992',
        sex: 'Male',
        civilStatus: 'Single',
        occupation: 'Farmer',
        profileCompleteness: 40,
        status: 'Pending Review',
      );
      SharedPreferences.setMockInitialValues({'esperanza_citizen_session': jsonEncode(unrelated.toJson())});
      final session = CitizenSessionService();
      var attempts = 0;
      while (session.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }

      expect(session.account!.id, 'ESP-RES-2026-9003');
      expect(session.account!.fullName, 'Anacleto Dimaculangan');
    });
  });

  group('Digital ID', () {
    testWidgets('Verified Perlita sees her Digital ID wallet, not the registration ID document', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = CitizenSessionService();
      var attempts = 0;
      while (session.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await session.login(MockCatalog.demoAccounts.last);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<ResidentProfileService>(create: (_) => ResidentProfileService()),
          ],
          child: const MaterialApp(home: DigitalIdScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The seeded wallet — Barangay Resident ID first, PWD ID second.
      expect(find.text('Barangay Resident ID'), findsOneWidget);
      expect(find.text('Perlita Quiambao'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      // The registration-uploaded ID document is a different concept, shown
      // only at Profile > Personal Information (see
      // submitted_government_id_test.dart) — never on this screen anymore.
      expect(find.text('My Government IDs'), findsNothing);
      expect(find.text('Postal ID (PHLPost)'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Duplicate Perlita (still Pending Review) does not get a second verified Digital ID', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = CitizenSessionService();
      var attempts = 0;
      while (session.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await session.login(MockCatalog.duplicateVerifiedDemoAccount);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<ResidentProfileService>(create: (_) => ResidentProfileService()),
          ],
          child: const MaterialApp(home: DigitalIdScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Digital ID not yet available'), findsOneWidget);
      expect(find.text('Esperanza Digital ID'), findsNothing);
      expect(find.byType(AppButton), findsNothing);

      // The registration-uploaded ID document no longer appears on this
      // screen at all, regardless of Pending Review status — it lives at
      // Profile > Personal Information instead (see
      // submitted_government_id_test.dart).
      expect(find.text('Submitted ID Document'), findsNothing);
      expect(find.text('Postal ID (PHLPost)'), findsNothing);
      expect(session.account!.status, 'Pending Review');
      expect(session.accessLevel, AccessLevel.unverified);
    });
  });
}
