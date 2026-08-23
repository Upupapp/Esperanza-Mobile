// Verifies the new Certified Copy of Marriage Certificate Dokyu service: it
// appears in the catalog under Office of the Municipal Civil Registrar right next to the
// pre-existing Application for Marriage License item, opens the
// data-driven wizard with the right (lean, lookup-only) step count, and a
// full fill-through run reaches the same request-submission gate every
// other Dokyu service uses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/service_catalog_screen.dart';
import 'package:esperanza_mobile/screens/shared/service_request_wizard_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';

Future<void> _pumpDokyuAsCristy(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last); // Cristy — verified
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

  await tester.tap(find.text('LGU / Municipality'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Office of the Municipal Civil Registrar'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Office of the Municipal Civil Registrar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('appears in Dokyu, positioned next to Application for Marriage License', (tester) async {
    await _pumpDokyuAsCristy(tester);

    // Both marriage-related Civil Registrar items are on screen together in the same
    // item list, confirming they sit side by side rather than in separate
    // sections.
    expect(find.text('Application for Marriage License'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Certified Copy of Marriage Certificate'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Certified Copy of Marriage Certificate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens a lean, lookup-only wizard — not the full certificate as a form', (tester) async {
    await _pumpDokyuAsCristy(tester);

    await tester.scrollUntilVisible(
      find.text('Certified Copy of Marriage Certificate'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Certified Copy of Marriage Certificate'));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceRequestWizardScreen), findsOneWidget);
    // Applicant Info -> Marriage Record Information -> Requirements ->
    // Review & Submit = 4 steps, not a giant multi-step replica of the
    // certificate's full Husband/Wife/parents/witnesses/registrar layout.
    expect(find.text('Step 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 4'), findsOneWidget);
    expect(find.text('Marriage Record Information'), findsWidgets);
    expect(find.text("Husband's Full Name"), findsOneWidget);
    expect(find.text("Wife's Full Name"), findsOneWidget);
    expect(find.text('Date of Marriage'), findsOneWidget);
    expect(find.text('Place of Marriage'), findsOneWidget);
    expect(find.text('Registry Number'), findsOneWidget);
    expect(find.text('Number of Copies'), findsOneWidget);
    // None of the certificate's own admin/official fields ever appear.
    expect(find.textContaining('Solemnizing'), findsNothing);
    expect(find.textContaining('Civil Registrar'), findsNothing);
    expect(find.textContaining('Witness'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('required-field validation, date picker, and full fill-through to the attachment gate', (tester) async {
    await _pumpDokyuAsCristy(tester);
    await tester.scrollUntilVisible(
      find.text('Certified Copy of Marriage Certificate'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Certified Copy of Marriage Certificate'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue')); // Applicant Info (prefilled) -> Marriage Record Information
    await tester.pumpAndSettle();

    // Blocked — nothing filled yet.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Please complete'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Juan Dela Cruz');
    await tester.enterText(fields.at(1), 'Maria Santos');
    // Date of Marriage — real date picker, switched to keyboard-entry for
    // a deterministic result.
    await tester.tap(find.text('Select date'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '06/12/2010');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Jun 12, 2010'), findsOneWidget);

    // find.byType(TextField) also matches AppDateField's internal
    // TextFormField, so the order here is: husbandFullName(0),
    // wifeFullName(1), dateOfMarriage's internal field(2),
    // placeOfMarriage(3). Registry Number/Number of Copies stay optional
    // and are left blank.
    final fieldsAfterDate = find.byType(TextField);
    await tester.enterText(fieldsAfterDate.at(3), 'Poblacion, Esperanza, Masbate');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Requirements & Attachments — fill Purpose, leave attachments empty,
    // confirm the standard gate still applies.
    expect(find.textContaining('Requirements'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextField, '').first, 'Requesting a copy for PSA registration.');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('attach at least one'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
