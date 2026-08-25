// Coverage for the expanded demoDefaults/demoPurpose sweep — closing the
// gap the earlier priority-list-only pass left: every Dokyu/Tulong service
// where Cristy's own demo persona genuinely fits (not third-party/sensitive,
// not gender- or age-mismatched) now prefills its form fields too, on top
// of the already-covered Requirements-step upload behavior (never
// pre-attached — see new_application_never_preattaches_test.dart). Also
// exercises the two new demoDefaults mechanisms this sweep introduced:
// ISO-string date parsing (DateTime has no const constructor, so dates
// can't live directly in a const CatalogItem) and Set<String>-based
// multiselect prefill.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/catalog_item.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/service_request_wizard_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

const _cristyId = 'ESP-RES-2024-1044';

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
    required CatalogItem item,
    required ServiceCategory category,
    MasterFileService? masterFile,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final session = CitizenSessionService();
    var attempts = 0;
    while (session.loading) {
      attempts++;
      if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
      await tester.pump(const Duration(milliseconds: 1));
    }
    await session.login(MockCatalog.demoAccounts.last); // Cristy — verified

    final requests = RequestsService(seedDemoData: false);
    attempts = 0;
    while (!requests.loaded) {
      attempts++;
      if (attempts > 100) throw StateError('RequestsService never finished loading.');
      await tester.pump(const Duration(milliseconds: 1));
    }
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

  group('Expanded prefill sweep — visible before typing anything', () {
    testWidgets('Certified Copy of Marriage Certificate: text + date fields prefilled', (tester) async {
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_marriage_certificate_copy');
      await pumpWizard(tester, item: item, category: ServiceCategory.dokyu);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Marriage Record Information
      await tester.pumpAndSettle();

      expect(find.text('Jerome Villaruel'), findsOneWidget);
      expect(find.text('Cristy Pareja Bonghanoy'), findsOneWidget);
      expect(find.text('Esperanza, Masbate'), findsOneWidget);
      // ISO string '2022-06-18' from demoDefaults, parsed via DateTime.parse
      // by the wizard and formatted by AppDateField as "MMM d, y".
      expect(find.text('Jun 18, 2022'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pet Registration: fields prefilled across all 3 steps', (tester) async {
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_pet_registration');
      await pumpWizard(tester, item: item, category: ServiceCategory.dokyu);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Pet Information
      await tester.pumpAndSettle();
      expect(find.text('Bantay'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Health Information
      await tester.pumpAndSettle();
      expect(find.text('No'), findsOneWidget); // spayedNeutered

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Owner & Emergency Contact
      await tester.pumpAndSettle();
      expect(find.text('Purok 2, Barangay Baras, Esperanza, Masbate'), findsOneWidget);
      expect(find.text('Corazon Cristy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Locational Clearance: text/select fields and the Set-based multiselect prefill', (tester) async {
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_locational_clearance');
      await pumpWizard(tester, item: item, category: ServiceCategory.dokyu);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Applicant & Representative
      await tester.pumpAndSettle();
      expect(find.text('Individual'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Project Details
      await tester.pumpAndSettle();
      expect(find.text('Improvement / Renovation'), findsOneWidget);
      expect(find.text('Home Renovation - Bonghanoy Residence'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Lot Information
      await tester.pumpAndSettle();
      expect(find.text('OCT-2019-00456'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      // zoningClassification multiselect — demoDefaults stores a
      // Set<String>, same as a citizen's own manual selection would.
      expect(find.text('Residential'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TESDA Skills Training Registration: fields prefilled including the multiselect', (tester) async {
      final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_tesda_registration');
      await pumpWizard(tester, item: item, category: ServiceCategory.tulong);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Personal Information
      await tester.pumpAndSettle();
      expect(find.text('Filipino'), findsOneWidget);
      expect(find.text('Unemployed'), findsOneWidget);
      expect(find.text('College'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Learner Classification
      await tester.pumpAndSettle();
      expect(find.text('Student'), findsWidgets);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Training Preference
      await tester.pumpAndSettle();
      expect(find.text('Bookkeeping NC III'), findsOneWidget);
      expect(find.text('TWSP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TUPAD Emergency Employment: fields prefilled across all 3 steps', (tester) async {
      final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_tupad');
      await pumpWizard(tester, item: item, category: ServiceCategory.tulong);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Worker Classification
      await tester.pumpAndSettle();
      expect(find.text('Underemployed'), findsOneWidget);
      expect(find.text('Vendor / Self-Employed'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Personal & Household Information
      await tester.pumpAndSettle();
      expect(find.text('Jerome Villaruel'), findsOneWidget); // reused spouse name, same as the marriage cert copy
      expect(find.text('9718'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('First Time Job Seeker Certificate: date already prefilled from profile, checkbox prefilled', (
      tester,
    ) async {
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_first_time_jobseeker');
      await pumpWizard(tester, item: item, category: ServiceCategory.dokyu);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Applicant Details
      await tester.pumpAndSettle();

      expect(find.text('Jan 13, 2001'), findsOneWidget);
      // The checkbox itself is asserted end-to-end (via submitted
      // formFields) in the group below — Checkbox has no distinguishing
      // visible text for a "checked" state to assert against directly.
      expect(tester.takeException(), isNull);
    });
  });

  group('Expanded prefill sweep — survives all the way to submission', () {
    testWidgets('First Time Job Seeker: prefilled checkbox reaches formFields as true without being tapped', (
      tester,
    ) async {
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _cristyId,
        documentType: 'valid_government_id',
        label: 'One (1) valid government-issued ID or Birth Certificate',
        attachment: _fakeAttachment('id_or_birth_cert.pdf'),
        origin: 'Test',
      );
      await mf.saveOrUpdate(
        accountId: _cristyId,
        documentType: 'proof_of_residency',
        label: 'Proof of Barangay residency',
        attachment: _fakeAttachment('residency_proof.pdf'),
        origin: 'Test',
      );
      final item = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_first_time_jobseeker');
      final requests = await pumpWizard(tester, item: item, category: ServiceCategory.dokyu, masterFile: mf);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Applicant Details
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Requirements & Attachments
      await tester.pumpAndSettle();

      while (find.text('Use Existing Document').evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text('Use Existing Document').first);
        await tester.tap(find.text('Use Existing Document').first);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Review & Submit
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Submit Request'));
      await tester.pumpAndSettle();

      final submitted = requests.all.last;
      expect(submitted.formFields['confirmFirstTime'], true);
      expect(tester.takeException(), isNull);
    });
  });
}
