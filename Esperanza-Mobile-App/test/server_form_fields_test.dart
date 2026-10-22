// A request form asks the questions staff publish in the Service Catalog
// (GET /services `fields`), the same the website asks, and files the answers
// under the same keys the website does. The app used to ask its own built-in
// questions, so a form edited by staff never changed on the phone, and the
// office received different keys from the app than from the website.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/catalog_item.dart';
import 'package:esperanza_mobile/models/service_form_spec.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/service_request_wizard_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';

import 'support/fake_api.dart';

List<Map<String, dynamic>> _fields() => [
  {'key': 'requester_name', 'label': 'Full Name', 'type': 'text', 'required': true},
  {'key': 'purok', 'label': 'Purok', 'type': 'text'},
  {
    'key': 'purpose',
    'label': 'Purpose',
    'type': 'checkbox-group',
    'allowOther': true,
    'options': ['Local Employment', 'NBI Clearance', 'Others'],
  },
  {
    'key': 'school',
    'label': 'Name of School',
    'type': 'text',
    'showIf': {'field': 'purpose', 'contains': 'Others'},
  },
  {
    'key': 'dependents',
    'label': 'Dependents',
    'type': 'table',
    'rowLabel': 'Dependent',
    'columns': [
      {'key': 'name', 'label': 'Name'},
      {
        'key': 'relationship',
        'label': 'Relationship',
        'options': ['Child', 'Spouse'],
      },
    ],
  },
];

Map<String, dynamic> _service({Object? fields, Object? version = 1}) => {
  'key': 'brgy_clearance',
  'type': 'dokyu',
  'name': 'Barangay Clearance',
  'office': 'Barangay Hall',
  'fee': {'display': 'Free', 'kind': 'free', 'required_inputs': <String>[]},
  'requirements': <String>[],
  'process': ['Submit', 'Release'],
  'fields': fields ?? _fields(),
  'version': version,
};

void main() {
  tearDown(FakeApi.restore);

  group('ServiceFormSpec.fromServerFields', () {
    test('reads every kind the website draws, in one Application Details step', () {
      final spec = ServiceFormSpec.fromServerFields([
        ..._fields(),
        {'key': 'mobile', 'label': 'Mobile', 'type': 'tel'},
        {'key': 'dob', 'label': 'Date of Birth', 'type': 'date'},
        {'key': 'age', 'label': 'Age', 'type': 'derived_age', 'derived_from': 'dob'},
        {'key': 'notes', 'label': 'Notes', 'type': 'textarea'},
      ])!;
      expect(spec.fromServer, isTrue);
      expect(spec.steps.single.label, 'Application Details');
      final byKey = {for (final f in spec.steps.single.fields) f.key: f};
      expect(byKey['requester_name']!.required, isTrue);
      expect(byKey['purok']!.required, isFalse);
      expect(byKey['purpose']!.type, ServiceFieldType.multiselect);
      expect(byKey['purpose']!.allowOther, isTrue);
      expect(byKey['school']!.visibleWhenKey, 'purpose');
      expect(byKey['school']!.visibleWhenContains, 'Others');
      expect(byKey['dependents']!.type, ServiceFieldType.table);
      expect(byKey['dependents']!.columns!.map((c) => c.key), ['name', 'relationship']);
      expect(byKey['dependents']!.columns![1].options, ['Child', 'Spouse']);
      expect(byKey['mobile']!.type, ServiceFieldType.phone);
      expect(byKey['age']!.derivedFromKey, 'dob');
      expect(byKey['notes']!.type, ServiceFieldType.textarea);
    });

    test('skips a question it cannot read, never the whole form', () {
      final spec = ServiceFormSpec.fromServerFields([
        {'label': 'No key'},
        {'key': 'x', 'label': 'A kind nobody draws', 'type': 'hologram'},
        {'key': 'y', 'label': 'A choice with no options', 'type': 'select'},
        'not a question',
        {'key': 'ok', 'label': 'Kept', 'type': 'text'},
      ])!;
      expect(spec.steps.single.fields.map((f) => f.key), ['ok']);
      expect(ServiceFormSpec.fromServerFields(const []), isNull);
      expect(ServiceFormSpec.fromServerFields(null), isNull);
    });
  });

  group('CatalogItem.fromApi', () {
    test('a published service asks the Service Catalog questions', () {
      final item = CatalogItem.fromApi(
        _service(),
        formSpec: const ServiceFormSpec(steps: []),
        demoPurpose: 'demo',
      );
      expect(item.formSpec!.fromServer, isTrue);
      expect(item.formSpec!.steps.single.fields.first.key, 'requester_name');
      expect(item.demoPurpose, isNull);
    });

    test('a published service with no questions takes a purpose, as on the website', () {
      expect(CatalogItem.fromApi(_service(fields: <Object>[])).formSpec, isNull);
    });

    test('an unpublished service keeps the app\'s own form', () {
      const local = ServiceFormSpec(steps: []);
      expect(CatalogItem.fromApi(_service(version: null), formSpec: local).formSpec, same(local));
    });

    test('Tulong\'s published entitlement is the amount shown', () {
      final item = CatalogItem.fromApi({
        ..._service(),
        'form_spec': {'entitlement': '₱3,000'},
      });
      expect(item.amount, '₱3,000');
    });
  });

  testWidgets('the wizard asks the server\'s questions and files the website\'s keys', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic>? filed;
    FakeApi.installFull((r) {
      if (r.method == 'POST' && r.path == '/citizen/requests') {
        filed = r.body;
        return {
          'ref': 'DR-2026-00123',
          'type': 'dokyu',
          'service_key': 'brgy_clearance',
          'service': 'Barangay Clearance',
          'status': 'Submitted',
          'submitted': '2026-10-22T10:00:00+08:00',
        };
      }
      return <dynamic>[];
    });

    final session = CitizenSessionService();
    await session.login(MockCatalog.demoAccounts.last);
    final account = session.account!;
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
            category: ServiceCategory.dokyu,
            item: CatalogItem.fromApi(_service()),
            accent: AppColors.brand600,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The website's applicant block, from the account.
    expect(find.widgetWithText(TextField, account.firstName), findsOneWidget);
    expect(find.widgetWithText(TextField, account.lastName), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // The Service Catalog's questions; the name already filled from the account.
    expect(find.text('Application Details'), findsWidgets);
    expect(find.widgetWithText(TextField, account.fullName), findsOneWidget);
    expect(find.text('Name of School'), findsNothing, reason: 'asked only after "Others"');

    await tester.tap(find.text('Local Employment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Others'));
    await tester.pumpAndSettle();
    expect(find.text('Name of School'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Others (please specify)'), 'Scholarship');

    await tester.tap(find.text('Add Dependent'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Ana Cruz');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Purpose'), findsNothing, reason: 'no purpose box beside the catalogue\'s questions');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    final formData = filed!['form_data'] as Map<String, dynamic>;
    expect(filed!['service_key'], 'brgy_clearance');
    expect(formData['requester_name'], account.fullName);
    expect(formData['purpose'], ['Local Employment', 'Others: Scholarship']);
    expect(formData['dependents'], [
      {'name': 'Ana Cruz', 'relationship': ''},
    ]);
    expect(formData['school'], '');
    expect(formData['applicant_first_name'], account.firstName);
    expect(formData['applicant_last_name'], account.lastName);
    expect(formData.keys, containsAll(['applicant_address', 'applicant_mobile', 'applicant_email']));
    expect(formData.containsKey('applicantFullName'), isFalse);
    expect(tester.takeException(), isNull);
  });
}
