// The valid ID, the selfie and the profile photo reach the LGU (backlog B1,
// B9). Until 2026-10-04 the sign-up ID "stayed on this phone", the face step
// was a timer, and the profile photo was never sent.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/profile_photo.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/digital_id_service.dart';

import 'support/fake_api.dart';

Future<CitizenSessionService> _session() async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  for (var i = 0; session.loading && i < 200; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  return session;
}

void main() {
  test('the accepted ID types come from the server', () async {
    FakeApi.installFull((req) {
      expect('${req.method} ${req.path}', 'GET /id-types');
      return ['PhilSys National ID', 'Postal ID'];
    });
    final session = await _session();
    expect(await session.idTypes(), ['PhilSys National ID', 'Postal ID']);
  });

  test('the ID and selfie go to the verification endpoint in one request', () async {
    final calls = <String>[];
    FakeApi.installFull((req) {
      calls.add('${req.method} ${req.path}');
      return {'can_submit': true, 'submission': {'status': 'Pending Review'}};
    });
    final dir = Directory.systemTemp.createTempSync('identity_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final front = File('${dir.path}/synthetic-id.jpg')..writeAsStringSync('synthetic image');
    final selfie = File('${dir.path}/synthetic-selfie.jpg')..writeAsStringSync('synthetic image');
    final session = await _session();

    await session.submitVerificationId(idType: 'Postal ID', frontPath: front.path, selfiePath: selfie.path);

    expect(calls, ['POST /citizen/verification/id']);
  });

  test('a sent photo comes back as waiting, with the approved one kept', () async {
    FakeApi.installFull((req) {
      expect('${req.method} ${req.path}', 'POST /citizen/profile/photo');
      return {
        'url': 'https://test.invalid/files/approved',
        'latest': {'status': 'Pending Review', 'remarks': null},
        'can_change': true,
        'next_change_at': null,
        'change_months': 6,
      };
    });
    final session = await _session();

    final photo = await session.uploadProfilePhoto([1, 2, 3]);

    expect(photo!.isPending, isTrue);
    expect(photo.approvedUrl, 'https://test.invalid/files/approved');
    expect(session.photo, same(photo));
  });

  test('the six-month rule and a rejection read from the server', () {
    final photo = ProfilePhotoView.fromApi({
      'url': null,
      'latest': {'status': 'Rejected', 'remarks': 'Face is not visible.'},
      'can_change': false,
      'next_change_at': '2027-04-04T00:00:00Z',
      'change_months': 6,
    })!;
    expect(photo.isRejected, isTrue);
    expect(photo.latestRemarks, 'Face is not visible.');
    expect(photo.canChange, isFalse);
    expect(photo.nextChangeAt, DateTime.utc(2027, 4, 4));
  });

  test('the Digital ID carries the approved photo only', () {
    final card = DigitalIdCard.fromApi({
      'account_no': 'ESP-RES-2026-00001',
      'name': 'Test Resident',
      'barangay': 'Poblacion',
      'status': 'Approved',
      'valid': true,
      'qr': 'ESPID|ESP-RES-2026-00001|sig',
      'photo_url': 'https://test.invalid/files/approved',
    })!;
    expect(card.photoUrl, 'https://test.invalid/files/approved');

    final without = DigitalIdCard.fromApi({'account_no': 'A', 'qr': 'Q'})!;
    expect(without.photoUrl, isNull);
  });
}
