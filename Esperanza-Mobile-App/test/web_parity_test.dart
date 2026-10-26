// Parity with the citizen website (2026-10-15): what the website had and the
// app did not - barangay profiles and the server's barangay list, the
// offline notice, ticket conversations, the satisfaction survey, "Was this
// helpful?", adding to Papeles, add to calendar, the events calendar, wider
// search, verifying a document, and the request slip / approval notice.
// Synthetic data; the API is faked.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/directory/directory_screen.dart';
import 'package:esperanza_mobile/screens/events/events_screen.dart';
import 'package:esperanza_mobile/screens/support/ticket_thread_screen.dart';
import 'package:esperanza_mobile/screens/verify/verify_document_screen.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/barangay_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/feedback_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/services/support_service.dart';
import 'package:esperanza_mobile/utils/calendar_export.dart';
import 'package:esperanza_mobile/utils/request_sheets.dart';
import 'package:esperanza_mobile/widgets/offline_notice.dart';
import 'package:esperanza_mobile/widgets/request_survey_card.dart';

import 'support/fake_api.dart';

final _labangtaytay = {
  'name': 'Labangtaytay',
  'punong_barangay': 'Hon. Synthetic Captain',
  'barangay_secretary': 'Synthetic Secretary',
  'contact': '0917 000 0000',
  'seal_url': null,
  'history': {
    'founding': 'Founded by synthetic settlers.',
    'today': 'Four puroks today.',
    'leadership': [
      {'name': 'Synthetic Leader', 'title': 'Kapitan del Barrio', 'term': '1970 – 1982'},
    ],
    'landmarks': [
      {'name': 'Synthetic Beach', 'location': 'Purok 10', 'note': 'Opened 2012'},
    ],
  },
  'officials_roster': [
    {'name': 'Hon. Synthetic Captain', 'position': 'Punong Barangay', 'committee': 'BDRRMC', 'photo_url': null},
  ],
};

Future<CitizenSessionService> _session(WidgetTester tester, {String barangay = 'Labangtaytay'}) async {
  final session = CitizenSessionService();
  final base = MockCatalog.demoAccounts.last;
  await tester.runAsync(() async {
    await pumpEventQueue();
    await session.login(CitizenAccount.fromJson({...base.toJson(), 'status': 'Approved', 'barangay': barangay}));
  });
  return session;
}

Future<void> _pump(WidgetTester tester, Widget home, {CitizenSessionService? session}) async {
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session ?? CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BarangayService.reset();
  });
  tearDown(FakeApi.restore);

  group('Barangays from the server', () {
    test('pickers use the built-in names until the server list arrives, then the server\'s', () async {
      expect(BarangayService.names, MockCatalog.barangays);
      FakeApi.installFull(
        (r) => [
          _labangtaytay,
          {'name': 'Agoho'},
        ],
      );
      await BarangayService.load();
      expect(BarangayService.names, ['Agoho', 'Labangtaytay']);
    });

    testWidgets('a barangay opens its profile: history and officials, as on the website', (tester) async {
      FakeApi.installFull(
        (r) => r.path == '/barangays'
            ? [
                _labangtaytay,
                {'name': 'Agoho'},
              ]
            : <dynamic>[],
      );
      await _pump(tester, const DirectoryScreen());
      await tester.tap(find.text('Barangays'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brgy. Labangtaytay'));
      await tester.pumpAndSettle();
      // The redesign (2026-10-22): leaders and places first, the full text
      // behind "Read full history".
      expect(find.text('Synthetic Leader'), findsOneWidget);
      expect(find.text('Synthetic Beach'), findsOneWidget);
      expect(find.text('Founded by synthetic settlers.'), findsNothing);
      await tester.ensureVisible(find.text('Read full history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read full history'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Founded by synthetic settlers.'), 200);
      expect(find.text('Founded by synthetic settlers.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Officials & Staff'), -300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Officials & Staff'));
      await tester.pumpAndSettle();
      expect(find.text('BDRRMC'), findsOneWidget);

      // A barangay without a written profile says so.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brgy. Agoho'));
      await tester.pumpAndSettle();
      expect(find.textContaining('being added barangay by barangay'), findsOneWidget);
    });
  });

  group('Offline notice', () {
    tearDown(() => ApiClient.unreachable.value = false);

    test('no connection marks the server unreachable; any answer clears it', () async {
      ApiClient.unreachable.value = false;
      FakeApi.installFull((r) => throw const SocketException('no route'));
      await expectLater(api.get('/announcements'), throwsA(isA<ApiException>()));
      expect(ApiClient.unreachable.value, isTrue);
      FakeApi.installFull((r) => throw const FakeApiError(status: 404));
      await expectLater(api.get('/announcements'), throwsA(isA<ApiException>()));
      expect(ApiClient.unreachable.value, isFalse, reason: 'A refusal is still an answer: the server is there.');
    });

    testWidgets('the notice shows while offline, says back online, then goes', (tester) async {
      FakeApi.installFull((r) => <dynamic>[]);
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineNotice(
            probeEvery: Duration(hours: 1),
            child: Scaffold(body: Text('screen')),
          ),
        ),
      );
      expect(find.textContaining('No internet connection'), findsNothing);
      ApiClient.unreachable.value = true;
      await tester.pump();
      expect(find.textContaining('No internet connection. Nothing can be saved'), findsOneWidget);
      ApiClient.unreachable.value = false;
      await tester.pump();
      expect(find.text('You are back online.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('You are back online.'), findsNothing);
    });
  });

  group('Support ticket conversation', () {
    Map<String, dynamic> ticket({String status = 'Under Review', List<dynamic>? messages}) => {
      'ref': 'TKT-2026-0042',
      'category': 'Dokyu',
      'subject': 'My clearance is late',
      'body': 'It has been two weeks.',
      'status': status,
      'office': 'Office of the Punong Barangay',
      'created_at': '2026-10-14T01:00:00Z',
      'messages':
          messages ??
          [
            {'from': 'staff', 'name': 'OPB', 'body': 'We are checking it.', 'at': '2026-10-14T03:00:00Z'},
          ],
    };

    test('the conversation starts with the report; an older single reply still shows', () {
      final t = SupportTicket.fromJson({...ticket(messages: []), 'response': 'Done, please claim it.'})!;
      expect(t.conversation.map((m) => m.body), ['It has been two weeks.', 'Done, please claim it.']);
      expect(t.conversation.last.fromStaff, isTrue);
    });

    testWidgets('the resident answers the office', (tester) async {
      Map<String, dynamic>? sent;
      FakeApiRequest? replied;
      FakeApi.installFull((r) {
        if (r.method == 'POST') {
          replied = r;
          sent = r.body;
          return ticket(
            messages: [
              ...ticket()['messages'] as List,
              {'from': 'citizen', 'body': 'Thank you.', 'at': '2026-10-14T04:00:00Z'},
            ],
          );
        }
        return ticket();
      });
      await _pump(tester, TicketThreadScreen(ticket: SupportTicket.fromJson(ticket(messages: []))!));
      expect(find.text('We are checking it.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Thank you.');
      await tester.tap(find.byTooltip('Send reply'));
      await _settle(tester);
      expect(replied!.path, '/citizen/support/tickets/TKT-2026-0042/reply');
      expect(sent, {'message': 'Thank you.'});
      expect(find.text('Thank you.'), findsOneWidget);
    });

    testWidgets('a closed ticket takes no reply and offers a new one', (tester) async {
      FakeApi.installFull((r) => ticket(status: 'Cancelled'));
      await _pump(tester, TicketThreadScreen(ticket: SupportTicket.fromJson(ticket(status: 'Cancelled'))!));
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Open a new ticket'), findsOneWidget);
    });
  });

  group('How was the service', () {
    testWidgets('asked once a request is released; the rating goes to the server and is not asked again', (
      tester,
    ) async {
      Map<String, dynamic>? sent;
      FakeApi.installFull((r) {
        sent = r.body;
        return {'recorded': true};
      });
      await _pump(
        tester,
        const Scaffold(
          body: RequestSurveyCard(reference: 'DOK-2026-000123', status: 'Released'),
        ),
      );
      expect(find.text('How was the service?'), findsOneWidget);
      await tester.tap(find.byTooltip('4 – Good'));
      await tester.pump();
      await tester.tap(find.text('Send rating'));
      await _settle(tester);
      expect(sent, {'ref': 'DOK-2026-000123', 'rating': 4, 'comment': null});
      expect(find.text('How was the service?'), findsNothing);
      expect(await FeedbackService.surveySettled('DOK-2026-000123'), isTrue);
    });

    testWidgets('not asked before the request is done', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: RequestSurveyCard(reference: 'DOK-2026-000124', status: 'Processing'),
        ),
      );
      expect(find.text('How was the service?'), findsNothing);
    });

    test('already answered elsewhere: settled quietly', () async {
      FakeApi.installFull(
        (r) => throw const FakeApiError(status: 409, code: 'ALREADY_SUBMITTED', messageEn: 'Already.'),
      );
      await FeedbackService.rate('DOK-2026-000125', 5, '');
      expect(await FeedbackService.surveySettled('DOK-2026-000125'), isTrue);
    });
  });

  test('"Was this helpful?" sends the question as the website does', () async {
    Map<String, dynamic>? sent;
    FakeApi.installFull((r) {
      sent = r.body;
      return {'recorded': true};
    });
    await FeedbackService.voteHelp('faqs', 'How do I claim my document?', true);
    expect(sent, {'doc_key': 'faqs', 'item': 'How do I claim my document?', 'helpful': true});
    expect(await FeedbackService.helpVote('faqs', 'How do I claim my document?'), isTrue);
  });

  group('Add to calendar', () {
    test('reads times the way the website does', () {
      expect(CalendarExport.timeSpan('8:00 AM - 5:00 PM'), (start: 480, end: 1020));
      expect(CalendarExport.timeSpan('09:00-09:30'), (start: 540, end: 570));
      expect(CalendarExport.timeSpan('8:00 - 11:00 AM'), (start: 480, end: 660));
      expect(CalendarExport.timeSpan('9 am'), (start: 540, end: 600));
      expect(CalendarExport.timeSpan('Whole day'), isNull);
    });

    test('Esperanza time to UTC, all day without a time, a reminder the day before', () {
      final timed = CalendarExport.window(DateTime(2026, 10, 20), '09:00-09:30');
      expect(timed, (allDay: false, start: '20261020T010000Z', end: '20261020T013000Z'));
      final allDay = CalendarExport.window(DateTime(2026, 10, 31), null);
      expect(allDay, (allDay: true, start: '20261031', end: '20261101'));
      final ics = CalendarExport.ics(
        CalendarEntry(uid: 'a@esperanza', title: 'Clean-up, Purok 2', date: DateTime(2026, 10, 20), time: '9:00 AM'),
        now: DateTime.utc(2026, 10, 15),
      );
      expect(ics, contains('DTSTART:20261020T010000Z'));
      expect(ics, contains(r'SUMMARY:Clean-up\, Purok 2'));
      expect(ics, contains('TRIGGER:-P1D'));
      expect(
        CalendarExport.googleCalendar(
          CalendarEntry(uid: 'a', title: 'X', date: DateTime(2026, 10, 20)),
        ).queryParameters['dates'],
        '20261020/20261021',
      );
    });
  });

  testWidgets('events as a month, and only my barangay\'s when asked', (tester) async {
    final today = DateTime.now();
    String day(int d) => DateTime(today.year, today.month, d).toIso8601String().substring(0, 10);
    FakeApi.installFull(
      (r) => [
        {'title': 'Synthetic fiesta', 'date': day(10), 'barangay': 'Agoho', 'venue': 'Plaza'},
        {'title': 'Synthetic clean-up', 'date': day(10), 'barangay': null, 'venue': 'Town hall'},
      ],
    );
    final session = await _session(tester, barangay: 'Labangtaytay');
    await _pump(tester, const EventsScreen(), session: session);
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('Synthetic fiesta'), findsOneWidget);
    await tester.tap(find.text('Brgy. Labangtaytay only'));
    await tester.pumpAndSettle();
    expect(find.text('Synthetic fiesta'), findsNothing, reason: "Another barangay's event drops out.");
    expect(find.text('Synthetic clean-up'), findsNothing,
        reason: 'Only the barangay\'s own, as the website\'s "Barangay only" (2026-10-26).');
  });

  group('Verify a document', () {
    test('the code inside a scanned QR', () {
      expect(VerifyDocumentScreen.codeFrom('https://web.example.invalid/verify/?code=abc123'), 'abc123');
      expect(VerifyDocumentScreen.codeFrom('https://web.example.invalid/verify/xyz789'), 'xyz789');
      expect(VerifyDocumentScreen.codeFrom('ABCD-EFGH-JKLM'), 'ABCD-EFGH-JKLM');
    });

    testWidgets('a typed code checks the document; an unknown one says so', (tester) async {
      FakeApi.installFull((r) {
        if (r.path == '/verify/ABCD-EFGH-JKLM') {
          return {
            'authentic': true,
            'control_number': 'BC-2026-000042',
            'title': 'Barangay Clearance',
            'issued_on': '2026-10-14',
            'valid_until': '2027-04-14',
            'expired': false,
            'revoked': false,
          };
        }
        throw const FakeApiError(status: 404);
      });
      await _pump(tester, const VerifyDocumentScreen());
      await tester.enterText(find.byType(TextField), 'ABCD-EFGH-JKLM');
      await tester.tap(find.text('Check'));
      await _settle(tester);
      expect(find.text('This document is genuine and valid.'), findsOneWidget);
      expect(find.text('BC-2026-000042'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'NOPE');
      await tester.tap(find.text('Check'));
      await _settle(tester);
      expect(find.textContaining('No document matches this code'), findsOneWidget);
    });
  });

  group('Request slip and approval notice', () {
    ServiceRequest request({ServiceCategory category = ServiceCategory.dokyu, String status = 'Processing'}) =>
        ServiceRequest(
          id: 'DOK-2026-000123',
          referenceNumber: 'DOK-2026-000123',
          applicantId: '',
          applicantName: '',
          typeName: 'Barangay Clearance',
          category: category,
          office: 'Office of the Punong Barangay',
          purpose: 'Employment',
          submittedAt: DateTime.utc(2026, 10, 14),
          status: status,
          statusHistory: const [],
          attachments: const [],
          expectedDays: '',
        )..payment = const RequestPayment(amount: 50, status: 'Pending Review');

    test('what to bring, as the website lists it', () {
      expect(RequestSheets.bring(request(), RequestSheet.slip), [
        'A valid ID with your photo',
        'This slip, or your reference number',
        'The fee of PHP 50.00, paid at the office',
      ]);
      expect(RequestSheets.noticeReady(request()), isFalse);
      expect(RequestSheets.noticeReady(request(category: ServiceCategory.tulong, status: 'Ready for Release')), isTrue);
    });

    test('both are made as PDFs on the phone', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final sheet in RequestSheet.values) {
        final bytes = await RequestSheets.build(
          request(category: ServiceCategory.tulong, status: 'Ready for Release'),
          sheet,
          applicant: 'Testa Sintetiko',
          barangay: 'Poblacion',
          now: DateTime(2026, 10, 15),
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      }
    });
  });

  test('a document added to Papeles goes to the wallet like the website\'s', () async {
    final calls = <String>[];
    FakeApi.installFull((r) {
      calls.add('${r.method} ${r.path}');
      return r.method == 'GET' ? <dynamic>[] : {'id': 7};
    });
    final dir = await Directory.systemTemp.createTemp('esp_parity');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/clearance.pdf')..writeAsBytesSync('%PDF-1.4'.codeUnits);
    final service = MasterFileService();
    addTearDown(service.dispose);
    await service.addToWallet(accountId: 'acct-1', name: 'Clearance', filePath: file.path);
    expect(calls, ['POST /citizen/papeles', 'GET /citizen/papeles']);
  });
}
