// A Tulong form opens whatever the resident has filed before, as on the
// website (2026-10-22, app/web parity): the app used to block a second
// application for the same assistance on the phone, which the website and
// the server never did, so the two let different things through.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/new_request_screen.dart';
import 'package:esperanza_mobile/screens/shared/service_catalog_screen.dart';
import 'package:esperanza_mobile/screens/shared/service_request_wizard_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';

import 'support/dokyu_tulong_fixtures.dart';

Future<void> _pumpTulongCatalog(WidgetTester tester, {required List<Map<String, dynamic>> seededRequests}) async {
  SharedPreferences.setMockInitialValues({});
  // GET /citizen/requests is scoped to the signed-in citizen by the bearer
  // token, so seeding it here (rather than a per-request applicant field) is
  // what "this is Perlita's own request history" now means.
  DokyuTulongFixtures.install(requests: seededRequests);

  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified

  final requests = RequestsService();
  await requests.loadRequests();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: const MaterialApp(
        home: ServiceCatalogScreen(
          category: ServiceCategory.tulong,
          title: 'Tulong',
          catalog: MockCatalog.assistanceTypes,
          accent: AppColors.purple700,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// GET /citizen/requests' own thin summary shape (ref/type/service/status/
// submitted only -- see RequestsService._requestFromSummary), not
// ServiceRequest.toJson()'s full persisted shape, which nothing sends or
// reads anymore.
Map<String, dynamic> _activeMedicalAssistance() => {
      'ref': 'req-active-medical',
      'type': 'tulong',
      'service': 'Medical Assistance (AICS)',
      'status': 'Pending Review',
      'submitted': DateTime(2026, 1, 1).toIso8601String(),
    };

void main() {

  testWidgets('an assistance with an open application still opens its form, as on the website', (tester) async {
    await _pumpTulongCatalog(tester, seededRequests: [_activeMedicalAssistance()]);

    await tester.tap(find.text('Municipal Social Welfare and Development Office'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medical Assistance (AICS)'));
    await tester.pumpAndSettle();

    expect(find.byType(NewRequestScreen), findsOneWidget);
    expect(find.text('Active Application Exists'), findsNothing);
  });

  testWidgets('a different assistance opens normally too', (tester) async {
    await _pumpTulongCatalog(tester, seededRequests: [_activeMedicalAssistance()]);

    // Educational Assistance is sourced/formSpec'd -> opens the wizard.
    await tester.tap(find.text('Office of the Municipal Mayor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Educational Assistance'));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceRequestWizardScreen), findsOneWidget);
    expect(find.text('Active Application Exists'), findsNothing);
    expect(find.text('Assistance Already Received'), findsNothing);
  });

  testWidgets('with no prior requests at all, a Tulong item opens immediately with no dialog', (tester) async {
    await _pumpTulongCatalog(tester, seededRequests: const []);

    await tester.tap(find.text('Municipal Social Welfare and Development Office'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medical Assistance (AICS)'));
    await tester.pumpAndSettle();

    expect(find.byType(NewRequestScreen), findsOneWidget);
    expect(find.text('Active Application Exists'), findsNothing);
  });
}
