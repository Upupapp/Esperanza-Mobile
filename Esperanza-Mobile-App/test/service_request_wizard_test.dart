// Verifies the new "Sir Paul's Required Form Experience" wizard
// (ServiceRequestWizardScreen): step labels/count adapt per the sourced
// service (see docs/DOKYU_TULONG_FORM_AUDIT.md), Applicant Info is
// prefilled from the signed-in account, required service-specific fields
// block Continue until filled, and items without a sourced formSpec keep
// using the older single-step NewRequestScreen instead of being forced
// into the new wizard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/new_request_screen.dart';
import 'package:esperanza_mobile/screens/shared/service_catalog_screen.dart';
import 'package:esperanza_mobile/screens/shared/service_request_wizard_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/widgets/onboarding_step_indicator.dart';

Future<void> _pumpDokyuAsMarites(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last); // Marites — verified
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService(seedDemoData: false)),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: const MaterialApp(
        home: ServiceCatalogScreen(
          category: ServiceCategory.dokyu,
          title: 'Dokyu',
          catalog: MockCatalog.documentTypes,
          accent: AppColors.brand600,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a sourced item (Barangay Clearance) opens the multi-step wizard, prefilled and step-adaptive', (tester) async {
    await _pumpDokyuAsMarites(tester);

    // Barangay-scoped -> single department (Barangay Hall) -> item list.
    await tester.tap(find.text('Barangay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barangay Clearance'));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceRequestWizardScreen), findsOneWidget);
    expect(find.byType(NewRequestScreen), findsNothing);

    // Step count/labels are data-driven from this item's formSpec: Applicant
    // Info -> Clearance Details -> Requirements -> Review & Submit (4
    // steps), not the fixed 6-step Registration template.
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Applicant Info'), findsWidgets);

    // Applicant Info is prefilled from the signed-in account (Marites Ferrer).
    expect(find.widgetWithText(TextField, 'Marites Ferrer'), findsOneWidget);
    expect(find.text('Agoho'), findsOneWidget); // her barangay, prefilled into the select

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: Clearance Details (sourced from BRGY.CLEARANCE NEW.docx) —
    // the global birthdate/age rule means there is no manual numeric Age
    // field here at all: only a Date of Birth picker plus a read-only,
    // auto-computed Age display. Marites' Date of Birth already exists in
    // her Resident Profile, so it's prefilled rather than asking her to
    // re-enter it, and Age is computed from it immediately.
    expect(find.text('Step 2 of 4'), findsOneWidget);
    expect(find.text('Clearance Details'), findsWidgets);
    expect(find.text('Mar 4, 1985'), findsOneWidget); // her prefilled birthdate
    expect(find.textContaining('years old'), findsOneWidget);
    expect(find.text('Select your Date of Birth above first'), findsNothing);

    // Continue is not blocked by Date of Birth (already filled) — only the
    // still-empty Purpose is required, proving Age was never a separately
    // validated field.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Please complete "Purpose".'), findsOneWidget);

    // Changing the Date of Birth through the real date picker (switched to
    // keyboard-entry mode for a deterministic result) immediately
    // recalculates Age — there is no separate "Edit Age" anywhere.
    await tester.tap(find.text('Mar 4, 1985'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '12/20/2000');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Mar 4, 1985'), findsNothing);
    expect(find.text('Dec 20, 2000'), findsOneWidget);
    expect(find.textContaining('years old'), findsOneWidget);

    // Fill Purpose via the select dropdown.
    await tester.tap(find.text('Select Purpose'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proof of Residency').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3: Requirements & Attachments — no attachment yet, so
    // Continue must be blocked with the same rule the old NewRequestScreen
    // enforced.
    expect(find.text('Step 3 of 4'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('attach at least one'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an item with no sourced formSpec (Cedula) still uses the older single-step request screen', (tester) async {
    await _pumpDokyuAsMarites(tester);

    await tester.tap(find.text('LGU / Municipality'));
    await tester.pumpAndSettle();
    // The LGU department list has grown with new sourced services (see
    // docs/DOKYU_TULONG_FORM_AUDIT.md), so "Treasurer's Office" may now be
    // below the fold — scroll it into view rather than assuming it's
    // on-screen already.
    await tester.scrollUntilVisible(find.text("Treasurer's Office"), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text("Treasurer's Office"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cedula (Community Tax Certificate)'));
    await tester.pumpAndSettle();

    expect(find.byType(NewRequestScreen), findsOneWidget);
    expect(find.byType(ServiceRequestWizardScreen), findsNothing);
    expect(find.byType(OnboardingStepIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
