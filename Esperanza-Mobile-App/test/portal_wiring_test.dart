// The citizen-portal features that used to be simulated on the device, now
// against esperanza-backend: Report a Problem (support tickets), profile
// edits and contact changes, the Digital ID card, and the Master File
// (Papeles wallet). Notifications and the resident profile have their own
// files (notifications_test, resident_profile_service_test).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/support_service.dart';

import 'support/fake_api.dart';

CitizenAccount _account({String status = 'Approved'}) => CitizenAccount(
  id: 'ESP-TEST-0100',
  firstName: 'Testa',
  lastName: 'Sintetiko',
  email: '',
  mobile: '09170000000',
  barangay: 'Poblacion',
  purok: '',
  address: '',
  birthdate: '',
  sex: '',
  civilStatus: '',
  occupation: '',
  profileCompleteness: 50,
  status: status,
);

Map<String, dynamic> _profile({String occupation = 'Fisher', String mobile = '09170000000'}) => {
  'account_no': 'ESP-TEST-0100',
  'first_name': 'Testa',
  'last_name': 'Sintetiko',
  'barangay': 'Poblacion',
  'occupation': occupation,
  'mobile': mobile,
  'status': 'Approved',
  'profile_completeness': 70,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  test('Report a Problem files a real ticket with a backend category', () async {
    FakeApiRequest? sent;
    FakeApi.installFull((r) {
      sent = r;
      return {'ref': 'TKT-2026-0042', 'status': 'Submitted'};
    });
    final ref = await SupportService.fileTicket(category: 'App Problem', subject: ' Crash ', body: ' On open ');
    expect(ref, 'TKT-2026-0042');
    expect(sent!.path, '/citizen/support/tickets');
    expect(sent!.body, {'category': 'App Problem', 'subject': 'Crash', 'body': 'On open'});
    expect(SupportService.categories, ['Account & Login', 'Dokyu', 'Tulong', 'Technical Issue', 'App Problem', 'Other']);
  });

  group('profile edits', () {
    Future<CitizenSessionService> signedIn() async {
      final session = CitizenSessionService();
      addTearDown(session.dispose);
      await pumpEventQueue();
      await session.login(_account());
      return session;
    }

    test('saveProfile PUTs only the changes and adopts the server profile', () async {
      FakeApiRequest? sent;
      FakeApi.installFull((r) {
        sent = r;
        return _profile(occupation: 'Teacher');
      });
      final session = await signedIn();
      await session.saveProfile({'occupation': 'Teacher'});
      expect(sent!.method, 'PUT');
      expect(sent!.path, '/citizen/profile');
      expect(sent!.body, {'occupation': 'Teacher'});
      expect(session.account!.occupation, 'Teacher');
      expect(session.account!.profileCompleteness, 70);
    });

    test('a verified account is identity-locked', () async {
      final session = await signedIn();
      expect(session.identityLocked, isTrue);
    });

    test('a new mobile number changes only after the code is verified', () async {
      final paths = <String>[];
      FakeApi.installFull((r) {
        paths.add(r.path);
        if (r.path == '/citizen/profile/contact') return {'channel': 'mobile', 'destination': '0918****321'};
        return _profile(mobile: '09181234321');
      });
      final session = await signedIn();
      final masked = await session.requestContactChange(channel: 'mobile', value: '09181234321');
      expect(masked, '0918****321');
      expect(session.account!.mobile, '09170000000');
      await session.verifyContactChange('123456');
      expect(paths, ['/citizen/profile/contact', '/citizen/profile/contact/verify']);
      expect(session.account!.mobile, '09181234321');
    });
  });

  testWidgets('Digital ID renders the LGU card with its verification QR', (tester) async {
    FakeApi.installFull((r) => {
      'account_no': 'ESP-TEST-0100',
      'name': 'Testa Sintetiko',
      'barangay': 'Poblacion',
      'status': 'Approved',
      'valid': true,
      'issued_at': '2026-09-01',
      'qr': 'ESPID|ESP-TEST-0100|sig',
    });
    final session = CitizenSessionService();
    await tester.runAsync(() async {
      await pumpEventQueue();
      await session.login(_account());
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<CitizenSessionService>.value(
        value: session,
        child: const MaterialApp(home: DigitalIdScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Testa Sintetiko'), findsOneWidget);
    expect(find.text('ESP-TEST-0100'), findsOneWidget);
    expect(find.text('Valid · Verified by LGU'), findsOneWidget);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView, skipOffstage: false));
    expect(qr, isNotNull);
  });

  group('Master File (Papeles)', () {
    test('sync adopts server documents; a saved upload goes to the wallet; archive calls the server', () async {
      final dir = await Directory.systemTemp.createTemp('esp_papeles');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/id.jpg')..writeAsBytesSync([1, 2, 3]);
      final calls = <String>[];
      FakeApi.installFull((r) {
        calls.add('${r.method} ${r.path}');
        if (r.method == 'GET') {
          return [
            {'id': 5, 'name': 'Barangay Clearance', 'type': 'Barangay Clearance', 'category': 'Dokyu', 'file_type': 'pdf', 'bytes': 2048, 'uploaded_at': '2026-09-01T00:00:00Z'},
          ];
        }
        if (r.path == '/citizen/papeles') return {'id': 9, 'name': 'Valid ID', 'type': 'Valid ID'};
        return {'archived': true};
      });

      final service = MasterFileService();
      await pumpEventQueue();
      await service.syncFromServer('ESP-TEST-0100');
      expect(service.documentsFor('ESP-TEST-0100').map((d) => d.id), ['pap-5']);
      expect(service.documentsFor('ESP-TEST-0100').single.attachment.category, AttachmentCategory.pdf);

      final saved = await service.saveOrUpdate(
        accountId: 'ESP-TEST-0100',
        documentType: 'Valid ID',
        label: 'Valid ID',
        attachment: Attachment(
          id: 'a1',
          fileName: 'id.jpg',
          category: AttachmentCategory.image,
          sizeBytes: 3,
          localPath: file.path,
          addedAt: DateTime(2026, 9, 28),
          documentTypeLabel: 'Valid ID',
        ),
        origin: 'Dokyu',
      );
      expect(saved.id, 'pap-9');
      expect(saved.attachment.localPath, file.path, reason: 'kept for reuse on this device');

      await service.archive('ESP-TEST-0100', saved);
      expect(calls.last, 'POST /citizen/papeles/9/archive');
      expect(service.documentsFor('ESP-TEST-0100').map((d) => d.id), ['pap-5']);
    });

    test('an upload that fails offline keeps the local copy', () async {
      final dir = await Directory.systemTemp.createTemp('esp_papeles');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/id.jpg')..writeAsBytesSync([1]);
      api = ApiClient(httpClient: null, baseUrl: 'http://127.0.0.1:9');
      final service = MasterFileService();
      await pumpEventQueue();
      final saved = await service.saveOrUpdate(
        accountId: 'A',
        documentType: 'Valid ID',
        label: 'Valid ID',
        attachment: Attachment(
          id: 'a1',
          fileName: 'id.jpg',
          category: AttachmentCategory.image,
          sizeBytes: 1,
          localPath: file.path,
          addedAt: DateTime(2026, 9, 28),
          documentTypeLabel: 'Valid ID',
        ),
        origin: 'Dokyu',
      );
      expect(saved.id, startsWith('mfd-'));
      expect(service.documentsFor('A'), hasLength(1));
    });
  });

  test('an upload whose file has vanished is an ApiException, not an I/O error', () async {
    FakeApi.installFull((_) => {'id': 1});
    await expectLater(
      api.postMultipart('/citizen/papeles', filePath: '/nonexistent/esp.jpg', fileField: 'file'),
      throwsA(isA<ApiException>()),
    );
  });
}
