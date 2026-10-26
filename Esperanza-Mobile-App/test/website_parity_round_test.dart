// What the website showed residents and the app did not (parity check,
// 2026-10-23), pinned so the two do not drift apart again. Nothing here
// reaches the network.
import 'dart:convert';

import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/evacuation_center.dart';
import 'package:esperanza_mobile/models/identity_status.dart';
import 'package:esperanza_mobile/models/incident_status.dart';
import 'package:esperanza_mobile/models/master_file_document.dart';
import 'package:esperanza_mobile/models/request_workflow.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/appointments_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/utils/expected_release.dart';
import 'package:esperanza_mobile/widgets/balita_share_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

void main() {
  tearDown(FakeApi.restore);

  group('expected release, worked out as the website does', () {
    // A Friday.
    final friday = DateTime(2026, 10, 23, 15, 30);

    test('working days skip the weekend', () {
      expect(expectedRelease(friday, '3 working days'), DateTime(2026, 10, 28));
    });

    test('same day is the day it was sent; plain days count every day', () {
      expect(expectedRelease(friday, 'Same day'), DateTime(2026, 10, 23));
      expect(expectedRelease(friday, '5 days'), DateTime(2026, 10, 28));
      expect(expectedRelease(friday, '1-3 days'), DateTime(2026, 10, 26), reason: 'the last number');
    });

    test('no processing time, no date', () {
      expect(expectedRelease(friday, null), isNull);
      expect(expectedRelease(friday, '  '), isNull);
    });
  });

  test('the steps of a request are read from the detail, a bad row skipped', () {
    final w = RequestWorkflow.fromApi({
      'current': 2,
      'stopped': false,
      'steps': [
        {
          'index': 1,
          'name': 'Check the requirements',
          'responsible': 'Records clerk',
          'days': 1,
          'done': true,
          'done_at': '2026-10-20T01:00:00Z',
        },
        {'index': 2, 'name': 'Sign the certificate', 'responsible': 'Punong Barangay', 'days': '2', 'done': false},
        {'name': 'no index'},
      ],
    })!;
    expect(w.steps.map((s) => s.name), ['Check the requirements', 'Sign the certificate']);
    expect(w.doneCount, 1);
    expect(w.current, 2);
    expect(w.steps.first.days, '1');
    expect(RequestWorkflow.fromApi({'steps': []}), isNull);
    expect(RequestWorkflow.fromApi(null), isNull);
  });

  test("an incident's status reads in residents' words", () {
    expect(incidentStatusLabel('Processing'), 'Dispatched');
    expect(incidentStatusLabel('Completed'), 'Resolved');
    expect(incidentStepLabel(verb: 'dispatch', status: 'Processing'), 'Responders on the way');
    expect(incidentStepLabel(verb: 'unknown', status: 'Archived'), 'Closed');
  });

  test('an ID that differs from the account is explained, as on the website', () {
    for (final code in ['NAME_MISMATCH', 'BIRTHDATE_MISMATCH', 'SEX_MISMATCH']) {
      expect(identityReasonText(code), contains('Your barangay office will compare them.'), reason: code);
    }
    expect(identityReasonText('SOMETHING_NEW'), isNull);
  });

  test('a full or nearly full open centre is flagged; a closed one is not', () {
    EvacuationCenter c(int n, {bool open = true}) =>
        EvacuationCenter(name: 'Gym', barangay: 'Poblacion', totalCapacity: 100, currentOccupancy: n, isOpen: open);
    expect(c(100).occupancyWarning, startsWith('Full'));
    expect(c(80).occupancyWarning, 'Almost full');
    expect(c(50).occupancyWarning, isNull);
    expect(c(100, open: false).occupancyWarning, isNull);
  });

  test("an office's booking window is its own, 14 days when it does not say", () {
    final own = AppointmentSchedule.fromApi({'id': 1, 'place': 'MSWDO', 'book_days_ahead': 30})!;
    final unsaid = AppointmentSchedule.fromApi({'id': 2, 'place': 'MSWDO'})!;
    final tooFar = AppointmentSchedule.fromApi({'id': 3, 'place': 'MSWDO', 'book_days_ahead': 400})!;
    expect(own.bookDaysAhead, 30);
    expect(unsaid.bookDaysAhead, 14);
    expect(tooFar.bookDaysAhead, 62);
  });

  test("a wallet document keeps the office's review across a restart", () {
    final doc = MasterFileDocument(
      id: 'pap-1',
      documentType: 'Valid ID',
      label: 'Valid ID',
      attachment: Attachment(
        id: 'pap-1',
        fileName: 'id.jpg',
        category: AttachmentCategory.image,
        sizeBytes: 1,
        addedAt: DateTime(2026, 10, 1),
        documentTypeLabel: 'Valid ID',
      ),
      uploadedAt: DateTime(2026, 10, 1),
      origin: 'Papeles',
      status: 'Verified',
    );
    final back = MasterFileDocument.fromJson(jsonDecode(jsonEncode(doc.toJson())) as Map<String, dynamic>);
    expect(back.status, 'Verified');
  });

  test("a file kept for reuse on this phone is not copied into the resident's Papeles", () async {
    SharedPreferences.setMockInitialValues({});
    final calls = <String>[];
    FakeApi.installFull((r) {
      calls.add('${r.method} ${r.path}');
      return <String, dynamic>{};
    });
    final mf = MasterFileService();
    addTearDown(mf.dispose);
    await mf.saveOrUpdate(
      accountId: 'acct-1',
      documentType: 'valid_id',
      label: 'Valid ID',
      attachment: Attachment(
        id: 'a-1',
        fileName: 'synthetic-id.jpg',
        category: AttachmentCategory.image,
        sizeBytes: 1,
        localPath: '/tmp/synthetic-id.jpg',
        addedAt: DateTime(2026, 10, 1),
        documentTypeLabel: 'Valid ID',
      ),
      origin: 'Dokyu',
    );
    expect(calls, isEmpty, reason: 'the website never copies request uploads into Papeles');
  });

  test('a shared Balita post carries its link on the website', () {
    final post = Announcement.fromAnnouncementApi({
      'id': 42,
      'title': 'Road closure',
      'body': 'The bridge is closed on Saturday.',
    });
    expect(balitaPostLink(post), endsWith('/citizen/announcements?post=42'));
  });

  test('"You are verified" is offered once, for the account notice only', () async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient(
      httpClient: MockClient((req) async {
        if (req.method == 'POST') {
          return http.Response('{"data":{}}', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 9,
                'category': 'account',
                'title': {'en': 'Verified'},
                'body': {'en': 'x'},
                'pill': 'Verified',
                'unread': true,
                'time': '2026-10-05T02:00:00Z',
              },
              {
                'id': 8,
                'category': 'dokyu',
                'title': {'en': 'Approved'},
                'body': {'en': 'x'},
                'pill': 'Verified',
                'unread': true,
                'time': '2026-10-05T01:00:00Z',
              },
            ],
            'meta': {'page': 1, 'last_page': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'https://test.invalid',
    );
    final service = NotificationsService();
    addTearDown(service.dispose);
    await service.loadServer();

    expect(service.pendingAlert, isNull, reason: 'not a Sakuna alert');
    final welcome = service.pendingWelcome;
    expect(welcome?.id, 9);
    await service.alertShown(welcome!);
    expect(service.pendingWelcome, isNull, reason: 'shown once, then read');
  });
}
