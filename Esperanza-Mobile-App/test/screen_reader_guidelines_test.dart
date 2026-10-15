// Screen-reader and touch-target checks on the screens added in the citizen
// app's scope round (2026-10-15): every control has a label TalkBack or
// VoiceOver can read, and every tap target is at least 44x44 - the design
// standard's minimum (docs/DESIGN_GUIDELINES.md, AppSizes.minTouchTarget).
// This does not replace listening to the screens on a phone, but it fails
// the build on an unlabelled or too-small button. Synthetic data.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/request_release.dart';
import 'package:esperanza_mobile/screens/appointments/appointments_screen.dart';
import 'package:esperanza_mobile/screens/sakuna/report_incident_screen.dart';
import 'package:esperanza_mobile/screens/support/report_problem_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/theme/app_spacing.dart';
import 'package:esperanza_mobile/widgets/offline_copy_note.dart';
import 'package:esperanza_mobile/widgets/request_release_cards.dart';

import 'support/fake_api.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => RequestsService()),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

Future<void> _meetsGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(
    tester,
    meetsGuideline(
      const MinimumTapTargetGuideline(
        size: Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
        link: 'docs/DESIGN_GUIDELINES.md',
      ),
    ),
  );
  handle.dispose();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  testWidgets('Report an incident, with its photo buttons', (tester) async {
    FakeApi.installFull((_) => <dynamic>[]);
    await _pump(tester, ReportIncidentScreen(item: MockCatalog.incidentTypes.first, accent: AppColors.rose600));
    await _meetsGuidelines(tester);
  });

  testWidgets('Report a Problem, with the camera button', (tester) async {
    FakeApi.installFull((_) => <dynamic>[]);
    await _pump(tester, const ReportProblemScreen());
    await _meetsGuidelines(tester);
  });

  testWidgets('My appointments', (tester) async {
    FakeApi.installFull((_) => <dynamic>[]);
    await _pump(tester, const AppointmentsScreen());
    await _meetsGuidelines(tester);
  });

  testWidgets('Ready to claim, the issued document, and the offline note', (tester) async {
    await _pump(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              OfflineCopyNote(savedAt: DateTime.utc(2026, 10, 15, 2)),
              PickupCard(
                pickup: RequestPickup.fromApi({
                  'office': 'Office of the Punong Barangay',
                  'office_contact': '0917 000 0000',
                  'office_hours': 'Mon-Fri, 8:00 AM - 5:00 PM',
                  'bring': ['valid_id', 'reference_number'],
                })!,
                reference: 'DOK-2026-000123',
                accent: AppColors.brand700,
              ),
              IssuedDocumentsCard(
                documents: [
                  IssuedDocumentInfo.fromApi({
                    'control_number': 'BC-2026-000042',
                    'verify_url': 'https://example.invalid/verify/?code=abcdefgh',
                    'issued_on': '2026-10-14',
                    'has_scan': true,
                    'scan_url': 'https://example.invalid/files/scan.pdf?signature=x',
                  })!,
                ],
                accent: AppColors.brand700,
              ),
            ],
          ),
        ),
      ),
    );
    await _meetsGuidelines(tester);
  });
}
