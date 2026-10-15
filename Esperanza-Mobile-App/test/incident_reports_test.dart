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
      await service.reportIncident(
        type: 'Fire',
        title: 't',
        severity: 'Critical',
        barangay: 'Tawad',
        clientUuid: 'same',
      );
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
      if (r.path == '/citizen/incidents/INC-2026-00002') {
        return {..._row('INC-2026-00002', status: 'Processing'), 'timeline': <dynamic>[]};
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
    // B-052: an incident's detail now has its own route, never the
    // Dokyu/Tulong one an INC- ref could never have resolved against.
    expect(paths, ['/citizen/incidents', '/citizen/incidents/INC-2026-00002']);
  });

  test('B-052: an incident\'s detail carries description, severity and a real timeline', () async {
    FakeApi.installFull((r) {
      if (r.path == '/citizen/incidents/INC-2026-00002') {
        return {
          ..._row('INC-2026-00002', status: 'Under Verification'),
          'sitio': 'Purok 3',
          'description': 'Water rising fast near the covered court.',
          'timeline': [
            {'verb': 'validate', 'status': 'Under Verification', 'at': '2026-09-28T02:00:00+08:00'},
          ],
        };
      }
      return <dynamic>[];
    });
    final service = RequestsService();
    addTearDown(service.dispose);

    final detail = await service.loadDetail('INC-2026-00002');

    expect(detail.office, 'Poblacion · Sitio Purok 3');
    expect(detail.purpose, contains('Severity: High'));
    expect(detail.purpose, contains('Water rising fast near the covered court.'));
    expect(detail.statusHistory, hasLength(1));
    expect(detail.statusHistory.single.status, 'Under Verification');
    expect(detail.statusHistory.single.actor, isNotEmpty);

    // The server's own citizen-safe shape has no staff note or responder
    // identity to begin with; this just confirms nothing here invents one.
    expect(detail.statusHistory.single.remarks, isNull);

    // Replaces the matching list-row entry rather than duplicating it.
    expect(service.byCategory(ServiceCategory.sakunaIncident), hasLength(1));
  });

  test('B-052: an incident with no description or sitio still renders cleanly', () async {
    FakeApi.installFull((r) => {..._row('INC-2026-00004'), 'timeline': <dynamic>[]});
    final service = RequestsService();
    addTearDown(service.dispose);

    final detail = await service.loadDetail('INC-2026-00004');

    expect(detail.office, 'Poblacion'); // no sitio on the row -> no trailing separator
    expect(detail.purpose, 'Severity: High'); // no description -> just the severity line
    expect(detail.statusHistory, isEmpty);
  });

  test('Dokyu/Tulong reloads do not drop incidents', () async {
    FakeApi.installFull((r) => r.path == '/citizen/incidents' ? [_row('INC-2026-00003')] : <dynamic>[]);
    final service = RequestsService();
    addTearDown(service.dispose);
    await service.loadIncidents();
    await service.loadRequests();
    expect(service.byCategory(ServiceCategory.sakunaIncident), hasLength(1));
  });

  test('a report with photos goes as a form, and the detail reads them back', () async {
    final sent = <FakeApiRequest>[];
    FakeApi.installFull((r) {
      sent.add(r);
      if (r.method == 'GET') {
        return {
          ..._row('INC-2026-00011'),
          'photos': [
            {'name': 'flood-1.jpg', 'url': 'https://example.invalid/files/a?signature=x'},
            {'name': 'flood-2.jpg', 'url': null},
          ],
        };
      }
      return _row('INC-2026-00011');
    });
    final service = RequestsService();
    addTearDown(service.dispose);

    await service.reportIncident(
      type: 'Flooding',
      title: 'Flooding — Poblacion',
      severity: 'High',
      barangay: 'Poblacion',
      clientUuid: 'abc-456',
      photos: [(bytes: 'synthetic-photo'.codeUnits, filename: 'flood-1.jpg')],
    );
    expect(sent.single.method, 'POST');
    expect(sent.single.path, '/citizen/incidents');
    expect(sent.single.body, isNull, reason: 'Sent as multipart, not JSON.');

    final detail = await service.loadDetail('INC-2026-00011');
    expect(detail.incidentPhotos, ['https://example.invalid/files/a?signature=x', null]);
  });

  testWidgets('the form requires severity and barangay, then submits once with a stable client_uuid', (tester) async {
    // A phone-tall screen: the form (with its photos field) is longer than
    // the test's default 800x600 view.
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final uuids = <String>[];
    var fail = true;
    FakeApi.installFull((r) {
      if (r.path == '/citizen/incidents' && r.method == 'POST') {
        uuids.add(r.body!['client_uuid'] as String);
        if (fail) {
          fail = false;
          throw const FakeApiError(
            status: 503,
            code: 'UNAVAILABLE',
            messageEn: 'Try again',
            messageFil: 'Subukan muli',
          );
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
    expect(find.text('Try again'), findsOneWidget); // English by default, see MessageLanguage
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(uuids, hasLength(2));
    expect(uuids.toSet(), hasLength(1));
    expect(
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(uuids.first),
      isTrue,
    );
    expect(find.textContaining('INC-2026-00009'), findsWidgets);
  });
}
