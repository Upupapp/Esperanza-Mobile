// A resident attaches the documents a request needs from the request's own
// detail screen (POST /citizen/requests/{ref}/requirements/{key}/attach).
// Until that endpoint existed the wizard could not upload anything and the
// office verified requests with nothing on file; the detail now says which
// requirements are still open (`attachable`) and which file each one holds.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';

import 'support/fake_api.dart';

const _ref = 'DOK-2026-00007';

Map<String, dynamic> _detail({bool idAttached = true}) => {
  'ref': _ref,
  'type': 'dokyu',
  'service': 'Barangay Clearance',
  'service_key': 'brgy_clearance',
  'status': 'Under Verification',
  'submitted': '2026-10-04T00:00:00Z',
  'office': 'Barangay Office',
  'requirements': [
    {
      'key': 'req_1',
      'label': 'Valid ID',
      'status': 'Pending Review',
      'attachable': true,
      'file': idAttached ? {'name': 'synthetic-id.pdf', 'mime': 'application/pdf', 'bytes': 2048, 'url': null, 'uploaded_at': '2026-10-04T01:00:00Z'} : null,
    },
    {'key': 'req_2', 'label': 'Cedula', 'status': 'Pending Review', 'attachable': true, 'file': null},
    {'key': 'req_3', 'label': 'Barangay ID', 'status': 'Approved', 'attachable': false, 'file': null},
  ],
  'history': [
    {'to': 'Submitted', 'at': '2026-10-04T00:00:00Z'},
    {'from': 'Submitted', 'to': 'Under Verification', 'at': '2026-10-04T02:00:00Z'},
  ],
};

void main() {
  test('the detail says which requirements are open and which file each holds', () async {
    FakeApi.installFull((req) => _detail());
    final service = RequestsService();
    addTearDown(service.dispose);

    final r = await service.loadDetail(_ref);

    expect(r.attachableRequirements.map((p) => p.key), ['req_1', 'req_2']);
    expect(r.attachments.single.fileName, 'synthetic-id.pdf');
    expect(r.attachments.single.documentTypeLabel, 'Valid ID');
    expect(r.attachments.single.sizeBytes, 2048);
  });

  test('attaching posts the file to that requirement and returns the new detail', () async {
    final calls = <String>[];
    FakeApi.installFull((req) {
      calls.add('${req.method} ${req.path}');
      return _detail();
    });
    final dir = Directory.systemTemp.createTempSync('attach_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/synthetic-cedula.pdf')..writeAsStringSync('%PDF-1.4 synthetic');
    final service = RequestsService();
    addTearDown(service.dispose);

    final r = await service.attachRequirement(_ref, requirementKey: 'req_2', filePath: file.path);

    expect(calls, ['POST /citizen/requests/$_ref/requirements/req_2/attach']);
    expect(r.referenceNumber, _ref);
  });

  testWidgets('the detail screen lists the open requirements, with no Remove for a server file', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FakeApi.installFull((req) => _detail());
    final requests = RequestsService();
    final session = CitizenSessionService();
    var attempts = 0;
    while (session.loading) {
      if (++attempts > 100) throw StateError('CitizenSessionService never finished loading.');
      await tester.pump(const Duration(milliseconds: 1));
    }
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RequestsService>.value(value: requests),
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
        ],
        child: const MaterialApp(home: RequestDetailScreen(requestId: _ref)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Documents for this request'), findsOneWidget);
    expect(find.text('1 document still needs to be attached.'), findsOneWidget);
    expect(find.text('Valid ID'), findsWidgets);
    expect(find.text('Cedula'), findsWidgets);
    expect(find.text('synthetic-id.pdf'), findsOneWidget);
    // A decided requirement is not offered.
    expect(find.text('Barangay ID'), findsNothing);
    // The server keeps the file; it can be replaced, not removed.
    expect(find.text('Remove'), findsNothing);
    expect(find.text('Replace'), findsOneWidget);
  });
}
