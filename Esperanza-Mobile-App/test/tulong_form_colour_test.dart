// Tulong is purple everywhere in the app (its tab, cards, request list and
// confirmation), but its request form drew the step bar, the Continue /
// Submit button, the prefill note and the edit links in Dokyu's blue. The
// form now takes Tulong's purple; Dokyu keeps exactly the blues it had.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:esperanza_mobile/widgets/onboarding_step_indicator.dart';

Future<void> _pumpWizard(WidgetTester tester, ServiceCategory category) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await tester.runAsync(() => session.login(MockCatalog.demoAccounts.last));
  // The first service in each module that has a form (the wizard's input).
  final item = (category == ServiceCategory.tulong ? MockCatalog.assistanceTypes : MockCatalog.documentTypes)
      .firstWhere((i) => i.formSpec != null);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(
        home: ServiceRequestWizardScreen(
          category: category,
          item: item,
          accent: category == ServiceCategory.tulong ? AppColors.purple700 : AppColors.brand600,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppButton _continue(WidgetTester tester) => tester.widget<AppButton>(find.widgetWithText(AppButton, 'Continue'));

void main() {
  testWidgets('the Tulong form is Tulong purple', (tester) async {
    await _pumpWizard(tester, ServiceCategory.tulong);
    expect(tester.widget<OnboardingStepIndicator>(find.byType(OnboardingStepIndicator)).accent, AppColors.purple700);
    expect(_continue(tester).accent, AppColors.purple700);
  });

  testWidgets('the Dokyu form keeps its blues', (tester) async {
    await _pumpWizard(tester, ServiceCategory.dokyu);
    expect(tester.widget<OnboardingStepIndicator>(find.byType(OnboardingStepIndicator)).accent, isNull);
    expect(_continue(tester).accent, isNull);
  });
}
