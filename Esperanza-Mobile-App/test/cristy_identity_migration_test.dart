// Coverage for the Marites-Ferrer-to-Cristy-Bonghanoy demo identity
// correction — specifically the parts a static source-code read can't
// prove: that a browser which already persisted the OLD stale identity to
// SharedPreferences (session snapshot, seeded demo requests, and an
// already-generated receipt) gets migrated to the correct Cristy Bonghanoy
// identity on next load, without the user manually clearing storage.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/access_level.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/receipt.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

/// The exact CitizenAccount snapshot a browser would have persisted before
/// this correction — same shape login() would have jsonEncode'd.
final _staleVerifiedAccountJson = jsonEncode(
  CitizenAccount(
    id: 'ESP-RES-2024-1203',
    firstName: 'Marites',
    lastName: 'Ferrer',
    email: 'marites.ferrer@email.com',
    mobile: '0919 502 7734',
    barangay: 'Baras',
    purok: 'Purok 2',
    address: 'Purok 2, Barangay Baras, Esperanza, Masbate',
    birthdate: 'November 29, 1988',
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
    firstName: 'Marites',
    lastName: 'Ferrer',
    email: 'marites.ferrer.dup@email.com',
    mobile: '0919 502 7734',
    barangay: 'Baras',
    purok: 'Purok 2',
    address: 'Purok 2, Barangay Baras, Esperanza, Masbate',
    birthdate: 'November 29, 1988',
    sex: 'Female',
    civilStatus: 'Married',
    occupation: 'Market Vendor',
    profileCompleteness: 35,
    status: 'Pending Review',
  ).toJson(),
);

Future<RequestsService> _loadedRequests(WidgetTester tester) async {
  final requests = RequestsService(seedDemoData: true);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

void main() {
  group('CitizenSessionService migrates a stale persisted account', () {
    testWidgets('a browser signed in as the old verified snapshot now sees Cristy Bonghanoy', (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_citizen_session': _staleVerifiedAccountJson});
      final session = CitizenSessionService();
      var attempts = 0;
      while (session.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }

      expect(session.account!.id, 'ESP-RES-2024-1044');
      expect(session.account!.fullName, 'Cristy Bonghanoy');
      expect(session.account!.email, 'cristy.bonghanoy@email.com');

      // The migration also re-persists the corrected snapshot — a later
      // restore (without this migration running again) must still be
      // correct, proving it wasn't just corrected in memory.
      final prefs = await SharedPreferences.getInstance();
      final resaved = jsonDecode(prefs.getString('esperanza_citizen_session')!) as Map<String, dynamic>;
      expect(resaved['id'], 'ESP-RES-2024-1044');
      expect(resaved['firstName'], 'Cristy');
    });

    testWidgets('a browser signed in as the old duplicate snapshot now sees the duplicate Cristy account', (
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

      expect(session.account!.id, MockCatalog.duplicateCristyAccount.id);
      expect(session.account!.fullName, 'Cristy Bonghanoy');
      expect(session.account!.status, 'Pending Review');
    });

    testWidgets('an account unrelated to the demo identity is left untouched', (tester) async {
      final unrelated = CitizenAccount(
        id: 'ESP-RES-2026-2101',
        firstName: 'Teodoro',
        lastName: 'Villaflor',
        email: 'teodoro.villaflor@email.com',
        mobile: '0918 442 1190',
        barangay: 'Libertad',
        purok: 'Purok 3',
        address: 'Purok 3, Barangay Libertad, Esperanza, Masbate',
        birthdate: 'May 14, 1992',
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

      expect(session.account!.id, 'ESP-RES-2026-2101');
      expect(session.account!.fullName, 'Teodoro Villaflor');
    });
  });

  group('RequestsService migrates stale seeded-demo-request identity', () {
    testWidgets(
      'a persisted demo request (and its already-generated receipt) created under the old identity is corrected',
      (tester) async {
        final staleRequest = ServiceRequest(
          id: 'demo-dokyu-barangay-clearance',
          referenceNumber: 'DR-2026-DEMO01',
          applicantId: 'ESP-RES-2024-1203',
          applicantName: 'Marites Ferrer',
          typeName: 'Barangay Clearance',
          category: ServiceCategory.dokyu,
          office: 'Barangay Hall',
          purpose: 'Proof of Residency',
          submittedAt: DateTime(2026, 1, 1),
          status: 'Paid',
          statusHistory: [
            StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 1, 1), actor: 'Citizen'),
            StatusHistoryEntry(status: 'Approved', at: DateTime(2026, 1, 2), actor: 'Barangay Staff'),
          ],
          attachments: const [],
          expectedDays: '1-2 working days',
          requiresPayment: true,
          fee: '₱50.00',
          paymentMethod: 'GCash',
          receipt: Receipt(
            type: ReceiptType.gcash,
            amount: '₱50.00',
            referenceNumber: 'GC-1112223334',
            dateTime: DateTime(2026, 1, 2),
            residentName: 'Marites Ferrer',
            serviceName: 'Barangay Clearance',
            requestReferenceNumber: 'DR-2026-DEMO01',
          ),
        );
        SharedPreferences.setMockInitialValues({
          'esperanza_service_requests': jsonEncode([staleRequest.toJson()]),
        });

        final requests = await _loadedRequests(tester);
        final migrated = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance');

        expect(migrated.applicantId, 'ESP-RES-2024-1044');
        expect(migrated.applicantName, 'Cristy Bonghanoy');
        expect(migrated.receipt!.residentName, 'Cristy Bonghanoy');
        // Everything else about the already-paid request is preserved — its
        // old 'Paid' status is itself an obsolete tracking label, separately
        // remapped to 'Approved' by _migrateObsoleteTrackingLabels (see the
        // Mobile-only final request-flow correction pass), which runs
        // alongside this identity migration, not instead of it.
        expect(migrated.status, 'Approved');
        expect(migrated.receipt!.referenceNumber, 'GC-1112223334');
        expect(migrated.receipt!.amount, '₱50.00');

        // Re-persisted, not just corrected in memory.
        final prefs = await SharedPreferences.getInstance();
        final resaved = jsonDecode(prefs.getString('esperanza_service_requests')!) as List;
        final resavedRequest = resaved.first as Map<String, dynamic>;
        expect(resavedRequest['applicantId'], 'ESP-RES-2024-1044');
        expect((resavedRequest['receipt'] as Map<String, dynamic>)['residentName'], 'Cristy Bonghanoy');
      },
    );

    testWidgets('a citizen-submitted (non-demo-seed) request under the old id is never touched by the migration', (
      tester,
    ) async {
      final genuineRequest = ServiceRequest(
        id: 'req-9999999999',
        referenceNumber: 'DR-2026-0099',
        applicantId: 'ESP-RES-2024-1203', // coincidentally reused id, but NOT one of the demo-seed ids
        applicantName: 'Marites Ferrer',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Employment',
        submittedAt: DateTime(2026, 1, 1),
        status: 'Submitted',
        statusHistory: [StatusHistoryEntry(status: 'Submitted', at: DateTime(2026, 1, 1), actor: 'Citizen')],
        attachments: const [],
        expectedDays: '1-2 working days',
      );
      SharedPreferences.setMockInitialValues({
        'esperanza_service_requests': jsonEncode([genuineRequest.toJson()]),
      });

      final requests = await _loadedRequests(tester);
      final untouched = requests.all.firstWhere((r) => r.id == 'req-9999999999');
      expect(untouched.applicantId, 'ESP-RES-2024-1203');
      expect(untouched.applicantName, 'Marites Ferrer');
    });
  });

  group('Digital ID', () {
    testWidgets('Verified Cristy sees her Digital ID wallet, not the registration ID document', (tester) async {
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
      expect(find.text('Cristy Bonghanoy'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      // The registration-uploaded ID document is a different concept, shown
      // only at Profile > Personal Information (see
      // submitted_government_id_test.dart) — never on this screen anymore.
      expect(find.text('My Government IDs'), findsNothing);
      expect(find.text('Postal ID (PHLPost)'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Duplicate Cristy (still Pending Review) does not get a second verified Digital ID', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = CitizenSessionService();
      var attempts = 0;
      while (session.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await session.login(MockCatalog.duplicateCristyAccount);

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
