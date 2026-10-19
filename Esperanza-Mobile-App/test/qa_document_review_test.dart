// Esperanza QA, 2026-10-07, on the phone: the bell's unread number and Mark
// all as read; a rejected document's reason and replacement; the proof of
// release; the documents picked while filling in a Tulong request; and the
// one mobile-number rule.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/home/root_shell.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/utils/ph_mobile.dart';
import 'package:esperanza_mobile/services/message_language.dart';

import 'support/fake_api.dart';

final _account = CitizenAccount(
  id: 'ESP-TEST-7',
  firstName: 'Test',
  lastName: 'Resident',
  email: 'test@example.com',
  mobile: '09000000000',
  barangay: 'Poblacion',
  purok: 'Purok 1',
  address: 'Purok 1, Brgy. Poblacion',
  birthdate: '—',
  sex: '—',
  civilStatus: '—',
  occupation: '—',
  profileCompleteness: 10,
  status: 'Approved',
);

Map<String, dynamic> _notice(int id, {required bool unread}) => {
  'id': id,
  'category': 'tulong',
  'title': {'fil': 'Paunawa $id', 'en': 'Notice $id'},
  'body': {'fil': 'Katawan $id', 'en': 'Body $id'},
  'pill': 'Rejected',
  'ref': 'AR-2026-000$id',
  'unread': unread,
  'pinned': false,
  'time': '2026-10-07T01:00:00Z',
};

Map<String, dynamic> _detail({String status = 'Initial Screening', Map<String, dynamic>? proof}) => {
  'ref': 'AR-2026-00001',
  'type': 'tulong',
  'service': 'Educational Assistance',
  'status': status,
  'submitted': '2026-10-07T01:00:00Z',
  'requirements': [
    {
      'key': 'req_1',
      'label': 'Certificate of Enrollment',
      'status': 'Rejected',
      'reason': 'Expired',
      'remarks': 'The enrollment is for last semester.',
      'replaceable': true,
      'attachable': false,
      'file': {'name': 'coe.pdf', 'bytes': 10, 'url': 'https://test.invalid/f/1', 'uploaded_at': '2026-10-07T01:00:00Z'},
    },
    {'key': 'req_2', 'label': 'Valid Government-Issued ID', 'status': 'Approved', 'replaceable': false, 'attachable': false},
  ],
  'proof_of_release': proof,
};

Future<(NotificationsService, List<String>)> _pumpBell(
  WidgetTester tester,
  List<Map<String, dynamic>> rows, {
  Widget bell = const AlertsAction(),
}) async {
  SharedPreferences.setMockInitialValues({});
  final posts = <String>[];
  FakeApi.installFull((r) {
    if (r.method == 'POST') {
      posts.add(r.path);
      for (final n in rows) {
        n['unread'] = false;
      }
      return {'marked': rows.length, 'unread': 0};
    }
    if (r.path == '/citizen/notifications') return rows;
    return <dynamic>[];
  });
  addTearDown(FakeApi.restore);

  final session = CitizenSessionService();
  await session.login(_account);
  final profiles = ResidentProfileService();
  // A complete profile, so the only notifications are the server's.
  final profile = profiles.profileFor(_account);
  profile.personal
    ..firstName = 'Test'
    ..lastName = 'Resident'
    ..sex = 'Male'
    ..birthdate = DateTime(1990, 1, 1)
    ..civilStatus = 'Single'
    ..mobile = '09000000000'
    ..barangay = 'Poblacion'
    ..sitioPurok = 'Purok 1'
    ..completeAddress = 'Purok 1, Brgy. Poblacion'
    ..occupation = 'Fisherman';
  profile.familyName = 'Resident Family';
  profile.household
    ..barangay = 'Poblacion'
    ..sitioPurok = 'Purok 1'
    ..completeAddress = 'Purok 1, Brgy. Poblacion'
    ..housingOwnership = 'Owned'
    ..housingType = 'Concrete'
    ..waterSource = 'Piped / Communal System'
    ..toiletFacility = 'Water-Sealed (Own Use)'
    ..electricitySource = 'Grid-Connected (Meralco/Coop)';
  final notifications = NotificationsService();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider<ResidentProfileService>.value(value: profiles),
        ChangeNotifierProvider<NotificationsService>.value(value: notifications),
      ],
      child: MaterialApp(
        home: Scaffold(appBar: AppBar(actions: [bell])),
      ),
    ),
  );
  await tester.runAsync(notifications.loadServer);
  await tester.pumpAndSettle();
  return (notifications, posts);
}

void main() {
  group('the bell', () {
    testWidgets('shows how many are unread, and nothing when none are', (tester) async {
      await _pumpBell(tester, [_notice(1, unread: true), _notice(2, unread: true), _notice(3, unread: false)]);
      expect(find.text('2'), findsOneWidget);
      expect(find.byTooltip('Alerts, 2 unread'), findsOneWidget);
    });

    testWidgets("on Home's round bell the count sits on the rim, not cut off by the circle", (tester) async {
      // Home frames the bell in a frosted circle that clips to its shape; the
      // count used to be drawn inside it, so its top-right was cut away
      // (2026-10-19).
      await _pumpBell(
        tester,
        [_notice(1, unread: true)],
        bell: AlertsAction(frame: (button) => ClipOval(child: button)),
      );
      final count = find.text('1');
      expect(count, findsOneWidget);
      expect(find.ancestor(of: count, matching: find.byType(ClipOval)), findsNothing);
      final circle = tester.getRect(find.byType(ClipOval));
      final badge = tester.getRect(find.ancestor(of: count, matching: find.byType(Container)).first);
      // On the top-right rim: reaching past the circle's box, centred near
      // the point where the rim crosses that corner's diagonal.
      expect(badge.top, lessThan(circle.top));
      expect(badge.right, greaterThan(circle.right));
      expect(badge.center.dx, greaterThan(circle.center.dx));
      expect(badge.center.dy, lessThan(circle.center.dy));
    });

    testWidgets('with nothing unread there is no badge at all', (tester) async {
      await _pumpBell(tester, [_notice(1, unread: false)]);
      expect(find.byTooltip('Alerts'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('reading one lowers the number; Mark all as read clears it, on the server too', (tester) async {
      // These notices are checked in Filipino, the language chosen in Settings
      // (English is the default since the live test of 2026-10-07, UX-15).
      MessageLanguage.filipino.value = true;
      addTearDown(() => MessageLanguage.filipino.value = false);
      final (notifications, posts) = await _pumpBell(tester, [
        _notice(1, unread: true),
        _notice(2, unread: true),
        _notice(3, unread: true),
      ]);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byTooltip('Alerts, 3 unread'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paunawa 1'));
      await tester.pumpAndSettle();
      expect(posts, ['/citizen/notifications/1/read']);
      expect(notifications.isRead('srv-1'), isTrue);
      if (find.byType(RequestDetailScreen).evaluate().isNotEmpty) {
        await tester.pageBack(); // the notice opened its request
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('Mark all as read'), findsOneWidget);
      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();
      expect(posts.last, '/citizen/notifications/read-all');
      expect(find.text('Mark all as read'), findsNothing, reason: 'nothing left unread');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Alerts'), findsOneWidget, reason: 'the badge is gone');

      // After a refresh the server's own read state holds.
      await tester.runAsync(notifications.loadServer);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Alerts'), findsOneWidget);
    });
  });

  group('the request detail', () {
    test('carries each document\'s reason and whether it may be replaced, and the proof of release', () async {
      FakeApi.installFull(
        (r) => _detail(
          status: 'Completed',
          proof: {
            'file': {'name': 'handover.jpg', 'bytes': 2048, 'url': 'https://test.invalid/f/9', 'uploaded_at': '2026-10-07T02:00:00Z'},
          },
        ),
      );
      addTearDown(FakeApi.restore);
      final service = RequestsService();
      addTearDown(service.dispose);

      final r = await service.loadDetail('AR-2026-00001');
      final rejected = r.requirementRows.firstWhere((q) => q.key == 'req_1');
      expect(rejected.isRejected, isTrue);
      expect(rejected.reason, 'Expired');
      expect(rejected.remarks, 'The enrollment is for last semester.');
      expect(rejected.replaceable, isTrue);
      expect(r.requirementRows.firstWhere((q) => q.key == 'req_2').replaceable, isFalse);

      expect(r.releaseProof?.fileName, 'handover.jpg');
      expect(r.releaseProof?.remoteUrl, 'https://test.invalid/f/9');
      expect(r.releaseProof?.category, AttachmentCategory.image);
    });

    test('has no proof of release before release', () async {
      FakeApi.installFull((r) => _detail());
      addTearDown(FakeApi.restore);
      final service = RequestsService();
      addTearDown(service.dispose);
      expect((await service.loadDetail('AR-2026-00001')).releaseProof, isNull);
    });

    testWidgets('a rejected document shows why and offers a replacement; the proof of release can be opened', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      FakeApi.installFull(
        (r) => _detail(
          proof: {
            'file': {'name': 'handover.jpg', 'bytes': 2048, 'url': 'https://test.invalid/f/9', 'uploaded_at': '2026-10-07T02:00:00Z'},
          },
        ),
      );
      addTearDown(FakeApi.restore);
      final session = CitizenSessionService();
      await session.login(_account);
      final requests = RequestsService();
      await tester.runAsync(() => requests.loadDetail('AR-2026-00001'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
            ChangeNotifierProvider(create: (_) => MasterFileService()),
            ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: const MaterialApp(home: RequestDetailScreen(requestId: 'AR-2026-00001')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.scrollUntilVisible(find.textContaining('Reason: Expired'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Reason: Expired — The enrollment is for last semester.'), findsOneWidget);
      expect(find.textContaining('Upload a replacement'), findsOneWidget);
      expect(find.textContaining('replace it below'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Proof of release'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Proof of release'), findsOneWidget);
      expect(find.text('handover.jpg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  test('documents picked while filling in a request go to its own requirements, by name', () async {
    final uploads = <String>[];
    FakeApi.installFull((r) {
      uploads.add('${r.method} ${r.path}');
      return _detail();
    });
    addTearDown(FakeApi.restore);
    final service = RequestsService();
    addTearDown(service.dispose);
    final request = await service.loadDetail('AR-2026-00001');
    uploads.clear();

    Attachment picked(String name, {String? path}) => Attachment(
      id: name,
      fileName: name,
      category: AttachmentCategory.pdf,
      sizeBytes: 1,
      localPath: path,
      addedAt: DateTime(2026, 10, 7),
      documentTypeLabel: name,
    );

    final failed = await service.attachPicked(request, {
      'Valid Government-Issued ID': picked('id.pdf', path: 'test/support/fake_api.dart'),
      'Something not on this request': picked('x.pdf', path: 'test/support/fake_api.dart'),
      'Certificate of Enrollment': picked('coe.pdf'), // no readable file
    });
    expect(uploads, ['POST /citizen/requests/AR-2026-00001/requirements/req_2/attach']);
    expect(failed, unorderedEquals(['Something not on this request', 'Certificate of Enrollment']));
  });

  group('PhMobile', () {
    test('takes exactly 11 digits starting 09', () {
      expect(PhMobile.validate('09171234567'), isNull);
      expect(PhMobile.validate('0917123456'), PhMobile.invalidMessage); // 10
      expect(PhMobile.validate('091712345678'), PhMobile.invalidMessage); // 12
      expect(PhMobile.validate('0917abc4567'), PhMobile.invalidMessage);
      expect(PhMobile.validate('0917-123-456'), PhMobile.invalidMessage);
      expect(PhMobile.validate('19171234567'), PhMobile.invalidMessage);
    });

    test('empty is fine unless required', () {
      expect(PhMobile.validate(''), isNull);
      expect(PhMobile.validate('  ', required: true), 'Please enter a contact number.');
    });

    test('a number saved before digits-only opens as the 11 digits', () {
      expect(PhMobile.normalise('0917 123 4567'), '09171234567');
      expect(PhMobile.normalise('+63 917 123 4567'), '09171234567');
      expect(PhMobile.normalise('not a number'), 'not a number');
    });

    testWidgets('letters and symbols cannot be typed, and no more than 11 digits', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(controller: controller, inputFormatters: PhMobile.inputFormatters),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '0917-abc-123 4567 89');
      expect(controller.text, '09171234567');
    });
  });
}
