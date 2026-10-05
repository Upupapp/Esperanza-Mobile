// A fee assessed on a declared amount (Business Permit's capital, Cedula's
// income, ...) needs that amount at filing: the catalogue names it in
// `fee.required_inputs`, and POST /citizen/requests refuses a request
// without it. The app never asked, so filing a Business Permit answered
// "Server Error" (backend finding B-053, found on staging 2026-10-05).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/catalog_item.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/new_request_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/utils/fee_inputs.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _businessPermitJson() => {
  'key': 'dokyu_business_new',
  'type': 'dokyu',
  'name': 'Business Permit (New Application)',
  'office': 'BPLO',
  'fee': {
    'display': '₱500.00 and up (based on capital)',
    'kind': 'schedule',
    'required_inputs': ['declared_capital'],
  },
  'requirements': ['DTI or SEC Registration'],
  'process': ['Submit Requirements', 'Release'],
};

Map<String, dynamic> _filed(String key) => {
  'ref': 'DR-2026-00099',
  'type': 'dokyu',
  'service_key': key,
  'service': 'Business Permit (New Application)',
  'status': 'Submitted',
  'submitted': '2026-10-05T10:20:00+00:00',
};

void main() {
  tearDown(FakeApi.restore);

  group('FeeInputs', () {
    test('reads an amount the way a resident types it', () {
      expect(FeeInputs.parse('50000'), 50000);
      expect(FeeInputs.parse('50,000'), 50000);
      expect(FeeInputs.parse('₱ 12,500.50'), 12500.5);
      expect(FeeInputs.parse(''), isNull);
      expect(FeeInputs.parse('a lot'), isNull);
      expect(FeeInputs.parse('-1'), isNull);
    });

    test('names each amount and says what is missing', () {
      expect(FeeInputs.label('declared_capital'), 'Declared capital (₱)');
      expect(FeeInputs.label('income'), 'Annual income (₱)');
      expect(FeeInputs.label('floor_area'), 'Floor area (₱)');

      final controllers = {'declared_capital': TextEditingController()};
      addTearDown(controllers['declared_capital']!.dispose);
      expect(FeeInputs.validate(['declared_capital'], controllers), contains('declared capital'));
      controllers['declared_capital']!.text = 'abc';
      expect(FeeInputs.validate(['declared_capital'], controllers), contains('as an amount'));
      controllers['declared_capital']!.text = '50,000';
      expect(FeeInputs.validate(['declared_capital'], controllers), isNull);
      expect(FeeInputs.collect(['declared_capital'], controllers), {'declared_capital': 50000});
    });
  });

  test('the catalogue entry carries the amounts its fee needs', () {
    expect(CatalogItem.fromApi(_businessPermitJson()).feeInputs, ['declared_capital']);
    expect(CatalogItem.fromApi({'key': 'brgy_clearance', 'fee': {'display': '₱50.00', 'kind': 'flat'}}).feeInputs, isEmpty);
    expect(CatalogItem.fromApi({'key': 'x', 'fee': '₱50.00'}).feeInputs, isEmpty);
  });

  group('RequestsService.submit', () {
    test('sends fee_inputs when there are any, and leaves them out otherwise', () async {
      final bodies = <Map<String, dynamic>?>[];
      FakeApi.installFull((r) {
        bodies.add(r.body);
        return _filed(r.body?['service_key'] as String);
      });
      final service = RequestsService();
      addTearDown(service.dispose);

      await service.submit(
        serviceKey: 'dokyu_business_new',
        formData: {'purpose': 'New Business Permit'},
        feeInputs: {'declared_capital': 50000},
      );
      await service.submit(serviceKey: 'brgy_clearance', formData: {'purpose': 'Employment'});

      expect(bodies[0]!['fee_inputs'], {'declared_capital': 50000});
      expect(bodies[1]!.containsKey('fee_inputs'), isFalse);
    });
  });

  testWidgets('the Business Permit form asks for the capital and files with it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic>? submitted;
    FakeApi.installFull((r) {
      if (r.method == 'POST' && r.path == '/citizen/requests') {
        submitted = r.body;
        return _filed('dokyu_business_new');
      }
      throw const FakeApiError(messageEn: 'not configured');
    });

    final session = CitizenSessionService();
    var attempts = 0;
    while (session.loading) {
      if (++attempts > 100) throw StateError('CitizenSessionService never finished loading.');
      await tester.pump(const Duration(milliseconds: 1));
    }
    final requests = RequestsService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider<RequestsService>.value(value: requests),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
        ],
        child: MaterialApp(
          home: NewRequestScreen(
            category: ServiceCategory.dokyu,
            item: CatalogItem.fromApi(_businessPermitJson()),
            accent: AppColors.blue700,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Declared capital (₱)'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'New Business Permit');

    final submit = find.widgetWithText(AppButton, 'Submit Request');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(submitted, isNull, reason: 'nothing is filed without the capital');
    expect(find.textContaining('declared capital'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '50,000');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submitted?['fee_inputs'], {'declared_capital': 50000});
    expect(tester.takeException(), isNull);
  });
}
