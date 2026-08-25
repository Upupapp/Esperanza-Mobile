// Coverage for the Cristy Master Profile + Educational Assistance alignment
// pass: her resident-fact data now matches the Web Admin's own Educational
// Assistance record (corrected DOB, place of birth, school, family
// background, income), a calculated Age field on Personal Information,
// seeded Ramon/Corazon family members, per-requirement Educational
// Assistance uploads that start empty, and a migration that safely corrects
// a device that already persisted the old placeholder profile.
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/resident_profile.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/family_information_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/personal_information_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_submitted_screen.dart';
import 'package:esperanza_mobile/screens/shared/service_request_wizard_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/utils/age_calculator.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

const _cristyId = 'ESP-RES-2024-1044';
final _cristyDob = DateTime(2001, 1, 13);

Attachment _fakeAttachment(String fileName, {AttachmentCategory category = AttachmentCategory.pdf}) {
  return Attachment(
    id: 'att-$fileName',
    fileName: fileName,
    category: category,
    sizeBytes: 12345,
    bytes: Uint8List(0),
    addedAt: DateTime(2026, 1, 1),
    documentTypeLabel: fileName,
  );
}

Future<CitizenSessionService> _signedInAsCristy(WidgetTester tester) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last); // Cristy — verified
  return session;
}

Future<ResidentProfileService> _readyProfiles(WidgetTester tester) async {
  final service = ResidentProfileService();
  var attempts = 0;
  while (!service.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('ResidentProfileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return service;
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
  group('Resident Master Profile — fresh seed', () {
    testWidgets("Cristy's freshly-seeded profile matches the Web Admin Educational Assistance record", (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsCristy(tester);
      final profiles = await _readyProfiles(tester);
      final profile = profiles.profileFor(session.account!);
      final personal = profile.personal;

      expect(personal.birthdate, _cristyDob);
      expect(personal.civilStatus, 'Married');
      expect(personal.placeOfBirth, 'Milagros, Masbate');
      expect(personal.schoolName, 'Masbate National Comprehensive High School');
      expect(personal.yearOrGradeLevel, '2nd Year College');
      expect(personal.degreeProgramOrCourse, 'BS Education');
      expect(personal.lastSchoolAverageGrade, '90');
      expect(personal.communityInvolvement, 'Member of the church youth ministry.');
      expect(personal.postGraduationPlans, 'Plans to apply for government service after graduation.');
      expect(profile.household.monthlyIncome, '₱9,718');

      final father = profile.familyMembers.firstWhere((m) => m.relationshipToHead == 'Father');
      expect(father.fullName, 'Ramon Cristy');
      expect(father.occupation, 'Construction Worker');

      final mother = profile.familyMembers.firstWhere((m) => m.relationshipToHead == 'Mother');
      expect(mother.fullName, 'Corazon Cristy');
      expect(mother.occupation, 'Sari-Sari Store Vendor');

      // Head of Family is untouched — still Cristy herself.
      expect(profile.headIndividualId, _cristyId);
    });

    testWidgets("Ronaldo's profile is completely unaffected by Cristy's alignment", (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = CitizenSessionService();
      var attempts = 0;
      while (session.loading) {
        attempts++;
        if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await session.login(MockCatalog.demoAccounts.first); // Ronaldo
      final profiles = await _readyProfiles(tester);
      final profile = profiles.profileFor(session.account!);

      expect(profile.personal.birthdate, isNot(_cristyDob));
      expect(profile.personal.placeOfBirth, isEmpty);
      expect(profile.familyMembers, isEmpty);
      expect(profile.household.monthlyIncome, isEmpty);
    });
  });

  group('Resident Master Profile — migration for an already-persisted stale device', () {
    testWidgets('an old placeholder Cristy profile (Nov 29 1988, no family) is corrected on load, unrelated data preserved', (
      tester,
    ) async {
      final staleProfile = ResidentProfile(
        citizenAccountId: _cristyId,
        personal: Individual(
          individualId: _cristyId,
          firstName: 'Cristy',
          lastName: 'Bonghanoy',
          sex: 'Female',
          birthdate: DateTime(1988, 11, 29),
          civilStatus: 'Married',
          mobile: '0919 502 7734',
          barangay: 'Baras',
          sitioPurok: 'Purok 2',
          completeAddress: 'Purok 2, Barangay Baras, Esperanza, Masbate',
          occupation: 'Market Vendor',
          householdId: 'HH-2026-104',
        ),
        familyName: 'Bonghanoy Family',
        headIndividualId: _cristyId,
        familyId: 'FAM-2026-104',
        householdId: 'HH-2026-104',
        household: Household(householdId: 'HH-2026-104', barangay: 'Baras'),
        personalSaved: true,
        familySaved: true,
      );
      SharedPreferences.setMockInitialValues({
        'esperanza_resident_profiles': jsonEncode({_cristyId: staleProfile.toJson()}),
      });

      final profiles = await _readyProfiles(tester);
      final session = await _signedInAsCristy(tester);
      final migrated = profiles.profileFor(session.account!);

      expect(migrated.personal.birthdate, _cristyDob);
      expect(migrated.personal.placeOfBirth, 'Milagros, Masbate');
      expect(migrated.household.monthlyIncome, '₱9,718');
      expect(migrated.familyMembers.any((m) => m.relationshipToHead == 'Father'), isTrue);
      expect(migrated.familyMembers.any((m) => m.relationshipToHead == 'Mother'), isTrue);

      // Genuinely pre-existing data is preserved exactly, not reset.
      expect(migrated.personal.occupation, 'Market Vendor');
      expect(migrated.personalSaved, isTrue);
      expect(migrated.familySaved, isTrue);

      // Re-persisted, not just corrected in memory.
      final prefs = await SharedPreferences.getInstance();
      final resaved = jsonDecode(prefs.getString('esperanza_resident_profiles')!) as Map<String, dynamic>;
      final resavedPersonal = resaved[_cristyId]['personal'] as Map<String, dynamic>;
      expect(resavedPersonal['birthdate'], _cristyDob.toIso8601String());
      final resavedMembers = resaved[_cristyId]['familyMembers'] as List;
      expect(resavedMembers.length, 2);
    });

    testWidgets('a device that never ran the old code and has no persisted Cristy profile still seeds correctly', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final profiles = await _readyProfiles(tester);
      final session = await _signedInAsCristy(tester);
      final profile = profiles.profileFor(session.account!);

      expect(profile.personal.birthdate, _cristyDob);
      expect(profile.familyMembers.length, 2);
    });
  });

  group('Personal Information — Age', () {
    testWidgets('shows Age calculated live from the corrected Jan 13, 2001 birthdate, and Civil Status Married', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsCristy(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ],
          child: const MaterialApp(home: PersonalInformationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jan 13, 2001'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      final expectedAge = calculateAge(_cristyDob);
      expect(find.text('$expectedAge years old'), findsOneWidget);
      expect(find.text('Married'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Family Information', () {
    testWidgets('shows Ramon Cristy (Father) and Corazon Cristy (Mother); the empty-state message is gone', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsCristy(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ],
          child: const MaterialApp(home: FamilyInformationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No family members added yet'), findsNothing);
      expect(find.text('Ramon Cristy'), findsOneWidget);
      expect(find.text('Corazon Cristy'), findsOneWidget);
      // _MemberTile's own subtitle line shows relationship + age + account
      // status only (not occupation — see that widget's subtitleParts) —
      // occupation itself is verified against the underlying data directly
      // in the "fresh seed" group above.
      expect(find.textContaining('Father'), findsWidgets);
      expect(find.textContaining('Mother'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('editing Ramon Cristy opens the sheet without crashing (Father/Mother are valid dropdown options)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsCristy(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ],
          child: const MaterialApp(home: FamilyInformationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ramon Cristy'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Family Member'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Educational Assistance wizard — field alignment', () {
    final item = MockCatalog.assistanceTypes.firstWhere((i) => i.key == 'tulong_educational');

    Future<RequestsService> pumpWizard(WidgetTester tester, {required MasterFileService masterFile}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = await _signedInAsCristy(tester);
      final requests = RequestsService(seedDemoData: false);
      var attempts = 0;
      while (!requests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
            ChangeNotifierProvider<MasterFileService>.value(value: masterFile),
            ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: MaterialApp(
            home: ServiceRequestWizardScreen(category: ServiceCategory.tulong, item: item, accent: AppColors.purple700),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return requests;
    }

    testWidgets('Student Information and Family Background steps prefill to match the Web Admin record', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await pumpWizard(tester, masterFile: mf);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // Applicant Info -> Student Information
      await tester.pumpAndSettle();

      expect(find.text('Jan 13, 2001'), findsOneWidget);
      final expectedAge = calculateAge(_cristyDob);
      expect(find.textContaining('$expectedAge years old'), findsOneWidget);
      expect(find.text('Milagros, Masbate'), findsOneWidget);
      expect(find.text('Married'), findsWidgets);
      expect(find.text('Masbate National Comprehensive High School'), findsOneWidget);
      expect(find.text('2nd Year College'), findsOneWidget);
      expect(find.text('BS Education'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Family Background
      await tester.pumpAndSettle();

      expect(find.text('Ramon Cristy'), findsOneWidget);
      expect(find.text('Construction Worker'), findsOneWidget);
      expect(find.text('Corazon Cristy'), findsOneWidget);
      expect(find.text('Sari-Sari Store Vendor'), findsOneWidget);
      expect(find.text('9718'), findsOneWidget); // plain digits, not "₱9,718"
      expect(tester.takeException(), isNull);
    });

    testWidgets('Requirements & Attachments shows exactly 3 separate uploaders, all starting empty', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await pumpWizard(tester, masterFile: mf);

      // Applicant Info -> Student Info -> Family Background -> Additional
      // Information -> Requirements: 4 Continue taps from step 0.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Certificate of Enrollment'), findsOneWidget);
      expect(find.text('Valid Government-Issued ID'), findsOneWidget);
      expect(find.text('Barangay Certificate of Indigency'), findsOneWidget);
      // Exactly 3 empty upload prompts, each with its own requirement-
      // specific button label — nothing pre-attached, nothing marked
      // submitted, no "Existing document found" (Cristy's own signup/
      // registration ID is a different, unrelated system — see
      // utils/government_id.dart — and is never auto-offered here).
      expect(find.text('Upload Certificate of Enrollment'), findsOneWidget);
      expect(find.text('Upload Valid Government-Issued ID'), findsOneWidget);
      expect(find.text('Upload Barangay Certificate of Indigency'), findsOneWidget);
      expect(find.text('Existing document found'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('using an existing Master File document for one requirement leaves the other two still empty', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _cristyId,
        documentType: 'certificate_of_enrollment',
        label: 'Certificate of Enrollment',
        attachment: _fakeAttachment('enrollment_cert.pdf'),
        origin: 'Some Other Service',
      );
      await pumpWizard(tester, masterFile: mf);

      // Applicant Info -> Student Info -> Family Background -> Additional
      // Information -> Requirements: 4 Continue taps from step 0.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Existing document found'), findsOneWidget);
      expect(find.text('enrollment_cert.pdf'), findsOneWidget);
      expect(find.text('Upload Valid Government-Issued ID'), findsOneWidget);
      expect(find.text('Upload Barangay Certificate of Indigency'), findsOneWidget);

      await tester.ensureVisible(find.text('Use Existing Document'));
      await tester.tap(find.text('Use Existing Document'));
      await tester.pumpAndSettle();

      expect(find.text('enrollment_cert.pdf'), findsOneWidget); // now the attached tile
      // The other two are untouched.
      expect(find.text('Upload Valid Government-Issued ID'), findsOneWidget);
      expect(find.text('Upload Barangay Certificate of Indigency'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'attaching all 3 requirements and submitting succeeds with a reference number; Track This Request opens the exact new request',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final mf = await _readyMasterFile(tester);
        await mf.saveOrUpdate(
          accountId: _cristyId,
          documentType: 'certificate_of_enrollment',
          label: 'Certificate of Enrollment',
          attachment: _fakeAttachment('enrollment.pdf'),
          origin: 'Test',
        );
        await mf.saveOrUpdate(
          accountId: _cristyId,
          documentType: 'valid_government_id',
          label: 'Valid Government-Issued ID',
          // Category left at the _fakeAttachment default (pdf), not image —
          // an image-categorized attachment triggers a real image-decode
          // attempt on this fixture's empty byte array (see _AttachedTile's
          // thumbnail preview), same reason no existing test in this suite
          // uses AttachmentCategory.image for a fake attachment either.
          attachment: _fakeAttachment('gov_id.jpg'),
          origin: 'Test',
        );
        await mf.saveOrUpdate(
          accountId: _cristyId,
          documentType: 'barangay_certificate_of_indigency',
          label: 'Barangay Certificate of Indigency',
          attachment: _fakeAttachment('indigency.pdf'),
          origin: 'Test',
        );
        final requests = await pumpWizard(tester, masterFile: mf);
        final before = requests.all.length;

        // Applicant Info -> Student Info -> Family Background -> Additional
        // Information -> Requirements: 4 Continue taps from step 0.
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.widgetWithText(AppButton, 'Continue'));
          await tester.pumpAndSettle();
        }

        // Attach all 3 via "Use Existing Document", one at a time — each
        // tap removes one from the remaining set.
        while (find.text('Use Existing Document').evaluate().isNotEmpty) {
          await tester.ensureVisible(find.text('Use Existing Document').first);
          await tester.tap(find.text('Use Existing Document').first);
          await tester.pumpAndSettle();
        }
        expect(find.text('Upload Document'), findsNothing);

        // This service has no formSpec 'purpose' field, so the Requirements
        // step's own free-text box is labeled "Purpose" and is required.
        await tester.enterText(find.byType(TextField).first, 'Educational assistance to support continuing studies');
        await tester.tap(find.widgetWithText(AppButton, 'Continue')); // -> Review & Submit
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Submit Request'));
        await tester.pumpAndSettle();

        expect(requests.all.length, before + 1);
        final submitted = requests.all.last;
        expect(submitted.typeName, 'Educational Assistance');
        expect(submitted.attachments.length, 3);
        expect(find.byType(RequestSubmittedScreen), findsOneWidget);
        expect(find.text(submitted.referenceNumber), findsOneWidget);
        expect(find.text('Track This Request'), findsOneWidget);

        await tester.tap(find.text('Track This Request'));
        await tester.pumpAndSettle();

        expect(find.byType(RequestDetailScreen), findsOneWidget);
        expect(find.text('Educational Assistance'), findsWidgets);
        expect(find.text(submitted.referenceNumber), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
