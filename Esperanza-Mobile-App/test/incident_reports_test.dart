// Incident reports go to the backend's own incident resource,
// POST/GET /citizen/incidents (esperanza-backend CitizenRequestController::
// reportIncident()/incidents()). They used to go to POST /citizen/requests
// with `service_key: incident_flood`, a key the services table never held,
// so every report failed validation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/sakuna/report_incident_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _row(String ref, {String status = 'Submitted'}) => {
  'ref': ref,
  'title': 'Flooding — Poblacion',
  'type': 'Flooding',
  'severity': 'High',
  'barangay': 'Poblacion',
  'status': status,
  'source': 'Citizen Portal',
  'reported': '2026-09-28T01:00:00+08:00',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  test('reportIncident posts the backend body to /citizen/incidents', () async {
    FakeApiRequest? sent;
    FakeApi.installFull((r) {
      sent = r;
      return _row('INC-2026-00001');
    });
    final service = RequestsService();
    addTearDown(service.dispose);

    final incident = await service.reportIncident(
      type: 'Flooding',
      title: 'Flooding — Poblacion',
      severity: 'High',
      barangay: 'Poblacion',
      sitio: '  ',
      description: 'Knee-deep water',
      clientUuid: 'abc-123',
    );

    expect(sent!.method, 'POST');
    expect(sent!.path, '/citizen/incidents');
    expect(sent!.body, {
      'type': 'Flooding',
      'title': 'Flooding — Poblacion',
      'severity': 'High',
      'barangay': 'Poblacion',
      'description': 'Knee-deep water',
      'client_uuid': 'abc-123',
    });
    expect(incident.referenceNumber, 'INC-2026-00001');
    expect(incident.category, ServiceCategory.sakunaIncident);
    expect(service.byCategory(ServiceCategory.sakunaIncident), hasLength(1));
  });

  test('a replayed report (same client_uuid, 200) does not duplicate the row', () async {
    FakeApi.installFull((_) => _row('INC-2026-00001'));
    final service = RequestsService();
    addTearDown(service.dispose);
    for (var i = 0; i < 2; i++) {
      await service.reportIncident(type: 'Fire', title: 't', severity: 'Critical', barangay: 'Tawad', clientUuid: 'same');
    }
    expect(service.byCategory(ServiceCategory.sakunaIncident), hasLength(1));
  });

  test('loadIncidents reads the citizen\'s reports; detail never calls /citizen/requests', () async {
    final paths = <String>[];
    FakeApi.installFull((r) {
      paths.add(r.path);
      if (r.path == '/citizen/incidents') {
        return [_row('INC-2026-00002', status: 'Processing'), _row('INC-2026-00001', status: 'Completed')];
      }
      throw const FakeApiError();
    });
    final service = RequestsService();
    addTearDown(service.dispose);

    await service.loadIncidents();
    final incidents = service.byCategory(ServiceCategory.sakunaIncident);
    expect(incidents.map((r) => r.status), unorderedEquals(['Processing', 'Completed']));

    final detail = await service.loadDetail('INC-2026-00002');
    expect(detail.status, 'Processing');
    expect(paths, ['/citizen/incidents']);
  });

  test('Dokyu/Tulong reloads do not drop incidents', () async {
    FakeApi.installFull((r) => r.path == '/citizen/incidents' ? [_row('INC-2026-00003')] : <dynamic>[]);
    final service = RequestsService();
    addTearDown(service.dispose);
    await service.loadIncidents();
    await service.loadRequests();
    expect(service.byCategory(ServiceCategory.sakunaIncident), hasLength(1));
  });

  testWidgets('the form requires severity and barangay, then submits once with a stable client_uuid', (tester) async {
    final uuids = <String>[];
    var fail = true;
    FakeApi.installFull((r) {
      if (r.path == '/citizen/incidents' && r.method == 'POST') {
        uuids.add(r.body!['client_uuid'] as String);
        if (fail) {
          fail = false;
          throw const FakeApiError(status: 503, code: 'UNAVAILABLE', messageEn: 'Try again', messageFil: 'Subukan muli');
        }
        return _row('INC-2026-00009');
      }
      return <dynamic>[];
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(create: (_) => RequestsService()),
        ],
        child: MaterialApp(
          home: ReportIncidentScreen(item: MockCatalog.incidentTypes.first, accent: AppColors.rose600),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submit = find.text('Submit Report');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.textContaining('how serious'), findsOneWidget);
    expect(uuids, isEmpty);

    await tester.tap(find.text('High'));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MockCatalog.barangays.first).last);
    await tester.pumpAndSettle();

    // First attempt fails (503), the retry reuses the same client_uuid.
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Subukan muli'), findsOneWidget); // Filipino-first, see ApiException.message()
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(uuids, hasLength(2));
    expect(uuids.toSet(), hasLength(1));
    expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(uuids.first), isTrue);
    expect(find.textContaining('INC-2026-00009'), findsWidgets);
  });
}
