// Coverage for the Mobile <-> Web Admin final alignment pass's
// CatalogItem.demoDefaults / demoPurpose architecture: realistic
// service-specific demo answers that appear ONLY for the verified primary
// demo resident (Perlita), layer strictly below the existing Master
// Profile prefill (see ServiceRequestWizardScreen's own prefill block and
// perlita_master_profile_alignment_test.dart), and remain ordinary editable
// form values — never hintText, never locked, and editing one never
// touches the Resident Master Profile or any other request.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/catalog_item.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/new_request_screen.dart';
import 'package:esperanza_mobile/screens/shared/service_request_wizard_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

import 'support/dokyu_tulong_fixtures.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';

Attachment _fakeAttachment(String fileName) {
  return Attachment(
    id: 'att-$fileName',
    fileName: fileName,
    category: AttachmentCategory.pdf,
    sizeBytes: 12345,
    bytes: Uint8List(0),
    addedAt: DateTime(2026, 1, 1),
    documentTypeLabel: fileName,
  );
}

Future<CitizenSessionService> _signedInAs(WidgetTester tester, dynamic account) async {
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

/// RequestsService no longer restores/loads anything on construction (the
/// server is the only source of truth for a request's own state now) --
/// there is nothing async to wait for unless a test actually submits, in
/// which case it installs its own DokyuTulongFixtures first.
RequestsService _readyRequests() => RequestsService();

Future<MasterFileService> _readyMasterFile(WidgetTester tester) async {
  final mf = MasterFileService();
  var attempts = 0;
  while (!mf.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('MasterFileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return mf;
}

void main() {
  Future<RequestsService> pumpWizard(
    WidgetTester tester, {
    required dynamic account,
    required CatalogItem item,
    required ServiceCategory category,
    MasterFileService? masterFile,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = await _signedInAs(tester, account);
    final requests = _readyRequests();
    final mf = masterFile ?? await _readyMasterFile(tester);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider<RequestsService>.value(value: requests),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider<MasterFileService>.value(value: mf),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(
          home: ServiceRequestWizardScreen(category: category, item: item, accent: AppColors.blue700),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return requests;
  }

  Future<RequestsService> pumpNewRequestScreen(
    WidgetTester tester, {
    required dynamic account,
    required CatalogItem item,
    required ServiceCategory category,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = await _signedInAs(tester, account);
    final requests = _readyRequests();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider<RequestsService>.value(value: requests),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
        ],
        child: MaterialApp(
          home: NewRequestScreen(category: category, item: item, accent: AppColors.blue700),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return requests;
  }

  group('demoDefaults / demoPurpose — Perlita only, always editable', () {
    testWidgets('Barangay Clearance: purpose defaults to Proof of Residency and is freely editable', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'valid_government_id',
        label: 'One (1) valid government-issued ID',
        attachment: _fakeAttachment('gov_id.pdf'),
        origin: 'Test',
      );
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'proof_of_residency',
        label: 'Proof of residency',
        attachment: _fakeAttachment('residency_proof.pdf'),
        origin: 'Test',
      );
      Map<String, dynamic>? submittedBody;
      DokyuTulongFixtures.install(
        onSubmit: (body) {
          submittedBody = body;
          return {
            'ref': 'DR-2026-TEST-001',
            'type': 'dokyu',
            'service': 'Barangay Clearance',
            'status': 'Submitted',
            'submitted': DateTime.now().toIso8601String(),
          };
        },
      );

      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_clearance');
      await pumpWizard(
        tester,
        account: MockCatalog.demoAccounts.last, // Perlita
        item: item,
        category: ServiceCategory.dokyu,
        masterFile: mf,
      );

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Clearance Details
      await tester.pumpAndSettle();

      // Web Admin's own record for Perlita: Purpose defaults to Proof of
      // Residency, not Local Employment.
      expect(find.text('Proof of Residency'), findsOneWidget);

      // Edit: open the dropdown and pick a different option — this must
      // change ONLY this in-progress request, never any stored profile
      // data (Purpose isn't a Master Profile field at all).
      await tester.tap(find.text('Proof of Residency'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Travel Abroad').last);
      await tester.pumpAndSettle();

      expect(find.text('Proof of Residency'), findsNothing);
      expect(find.text('Travel Abroad'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Requirements & Attachments
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Review & Submit
      await tester.pumpAndSettle();

      // No Payment Method step anymore -- the wizard dropped it along with
      // every local receipt/payment simulation (production-readiness
      // programme, 2026-09-25); Review is the last step, and its own button
      // already reads "Submit Request".
      await tester.tap(find.widgetWithText(AppButton, 'Submit Request'));
      await tester.pumpAndSettle();

      // POST /citizen/requests doesn't echo form_data back, and the client
      // never re-reads it after submitting (RequestSubmittedScreen only
      // needs referenceNumber/typeName/requestId) -- so what actually
      // reached the server is what this asserts on, not a field on the
      // round-tripped response object.
      expect(submittedBody, isNotNull);
      expect(submittedBody!['service_key'], 'dokyu_barangay_clearance');
      final formData = submittedBody!['form_data'] as Map;
      // The select value and the notes field (itself prefilled from
      // demoPurpose for Perlita) are combined by _resolvePurpose -- exact
      // match would be coupled to that combination, so assert on presence/
      // absence the same way the pre-conversion test did.
      expect(formData['purpose'], contains('Travel Abroad'));
      expect(formData['purpose'], isNot(contains('Local Employment')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Barangay Clearance: a non-verified account gets no demo purpose default', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_clearance');
      await pumpWizard(
        tester,
        account: MockCatalog.demoAccounts.first, // Nicanor — not the verified demo resident
        item: item,
        category: ServiceCategory.dokyu,
      );

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Clearance Details
      await tester.pumpAndSettle();

      expect(find.text('Local Employment'), findsNothing);
      expect(find.text('Select Purpose'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Certificate of Residency: residencyType and purpose both prefill for Perlita', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_residency');
      await pumpWizard(
        tester,
        account: MockCatalog.demoAccounts.last,
        item: item,
        category: ServiceCategory.dokyu,
      );

      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Permanent Resident'), findsOneWidget);
      expect(find.text('Bank Requirement'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Barangay Business Clearance: text/number fields prefill and are editable via select-all/retype', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'valid_government_id',
        label: 'One (1) valid government-issued ID',
        attachment: _fakeAttachment('gov_id.pdf'),
        origin: 'Test',
      );
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'proof_of_business_location_lease_contract_or_land_title',
        label: 'Proof of business location (lease contract or land title)',
        attachment: _fakeAttachment('business_location.pdf'),
        origin: 'Test',
      );
      Map<String, dynamic>? submittedBody;
      DokyuTulongFixtures.install(
        onSubmit: (body) {
          submittedBody = body;
          return {
            'ref': 'DR-2026-TEST-002',
            'type': 'dokyu',
            'service': 'Barangay Business Clearance',
            'status': 'Submitted',
            'submitted': DateTime.now().toIso8601String(),
          };
        },
      );

      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_barangay_business_clearance');
      await pumpWizard(
        tester,
        account: MockCatalog.demoAccounts.last,
        item: item,
        category: ServiceCategory.dokyu,
        masterFile: mf,
      );

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Business Details
      await tester.pumpAndSettle();

      expect(find.text("Quiambao's Sari-Sari Store"), findsOneWidget);
      expect(find.text('Retail - Sari-Sari Store'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('15000'), findsOneWidget);

      // Editable: clear and retype the business name field.
      final businessNameField = find.widgetWithText(TextField, "Quiambao's Sari-Sari Store");
      await tester.enterText(businessNameField, 'Perlita Variety Store');
      await tester.pumpAndSettle();
      expect(find.text("Quiambao's Sari-Sari Store"), findsNothing);
      expect(find.text('Perlita Variety Store'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Requirements & Attachments
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Review & Submit
      await tester.pumpAndSettle();

      // No Payment Method step anymore -- see the Barangay Clearance test
      // above for why. Review's own button already reads "Submit Request".
      await tester.tap(find.widgetWithText(AppButton, 'Submit Request'));
      await tester.pumpAndSettle();

      expect(submittedBody, isNotNull);
      final formData = submittedBody!['form_data'] as Map;
      expect(formData['businessName'], 'Perlita Variety Store');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cedula (no formSpec): NewRequestScreen prefills Purpose from demoPurpose and it stays editable', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_cedula');
      await pumpNewRequestScreen(
        tester,
        account: MockCatalog.demoAccounts.last,
        item: item,
        category: ServiceCategory.dokyu,
      );

      expect(find.text('For submission as a government transaction requirement.'), findsOneWidget);

      final purposeField = find.widgetWithText(TextField, 'For submission as a government transaction requirement.');
      await tester.enterText(purposeField, 'Cedula needed for NBI clearance application.');
      await tester.pumpAndSettle();

      expect(find.text('For submission as a government transaction requirement.'), findsNothing);
      expect(find.text('Cedula needed for NBI clearance application.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 'Reject (Demo) on RequestDetailScreen...' removed -- RequestsService.
    // rejectDemo() and RequestDetailScreen's "Reject Request (Demo)" button
    // are both gone (production-readiness programme, 2026-09-25): rejection
    // is a real admin-side decision now, made through the Web Admin against
    // the real backend, not a client-side simulation this app can trigger on
    // itself. Nothing left client-side to test.

    testWidgets('Cedula: a non-verified account sees a blank Purpose field', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_cedula');
      await pumpNewRequestScreen(
        tester,
        account: MockCatalog.demoAccounts.first, // Nicanor
        item: item,
        category: ServiceCategory.dokyu,
      );

      expect(find.text('Community Tax Certificate needed for a bank transaction requirement.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
