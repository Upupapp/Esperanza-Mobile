// Events: registration, attendance and e-certificates (owner, 2026-10-30,
// round 2 item 6). The LGU posts an event; a resident registers on its page,
// shows the code at the event, and opens the certificate once it is issued
// to those who attended (esperanza-backend CitizenEventController: GET
// /citizen/event-registrations, POST and DELETE
// /citizen/events/{key}/registration; every event row's `registration`).
// Nothing here reaches the network.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/models/event_registration.dart';
import 'package:esperanza_mobile/screens/events/event_detail_screen.dart';
import 'package:esperanza_mobile/screens/events/event_registration_panel.dart';
import 'package:esperanza_mobile/screens/home/root_shell.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/event_registration_service.dart';
import 'package:esperanza_mobile/services/json_read.dart';
import 'package:esperanza_mobile/services/message_language.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notification_feed.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/widgets/restricted_feature_notice.dart';

import 'support/fake_api.dart';

const _key = 'health-day-x1';
const _path = '/citizen/events/$_key/registration';
const _verifyUrl = 'https://esperanza.example.test/verify/EVT-2026-000001?t=abc';

String _day(int offset) {
  final d = DateTime.now().add(Duration(days: offset));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _openRegistration({int count = 38, int? capacity = 50, bool full = false, String? closesAt}) => {
  'open': true,
  'capacity': capacity,
  'closes_at': closesAt,
  'count': count,
  'full': full,
};

Map<String, dynamic> _event({int inDays = 5, Map<String, dynamic>? registration}) => {
  'key': _key,
  'name': 'Barangay Health Day',
  'date': _day(inDays),
  'time': '8:00 AM',
  'venue': 'Municipal Plaza',
  'registration': registration ?? _openRegistration(),
};

Map<String, dynamic> _registration({
  String key = _key,
  bool? attended,
  Map<String, dynamic>? certificate,
  String? cancelledAt,
}) => {
  'event_key': key,
  'code': 'ABCD2345',
  'registered_at': '2026-10-28T09:00:00+08:00',
  'cancelled_at': cancelledAt,
  'attended': attended,
  'certificate': certificate,
};

EventRegistrationInfo _info(Map<String, dynamic> raw) => EventRegistrationInfo.fromApi(raw)!;

const _certificate = {'control_number': 'EVT-2026-000001', 'verify_url': _verifyUrl};

/// The server as the page sees it: the resident's registrations live in
/// [mine], which registering and cancelling change.
class _Server {
  _Server({List<Map<String, dynamic>>? mine, this.registerError, Map<String, dynamic>? event})
    : mine = mine ?? [],
      event = event ?? _event();

  final List<Map<String, dynamic>> mine;
  final FakeApiError? registerError;
  final Map<String, dynamic> event;
  final sent = <FakeApiRequest>[];

  Iterable<FakeApiRequest> calls(String method, String path) =>
      sent.where((r) => r.method == method && r.path == path);

  void install() {
    FakeApi.installFull((r) {
      sent.add(r);
      if (r.path == '/citizen/event-reminders') return <dynamic>[];
      if (r.path == '/citizen/event-registrations') return mine;
      if (r.path == '/events/$_key') return event;
      if (r.path == _path && r.method == 'POST') {
        if (registerError != null) throw registerError!;
        final row = _registration();
        mine
          ..clear()
          ..add(row);
        return row;
      }
      if (r.path == _path && r.method == 'DELETE') {
        mine.clear();
        return {'event_key': _key, 'cancelled': true};
      }
      throw const FakeApiError();
    });
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester, Map<String, dynamic> event, {bool signedIn = true}) async {
  final session = CitizenSessionService();
  addTearDown(session.dispose);
  if (signedIn) await tester.runAsync(() => session.login(MockCatalog.demoAccounts.last));
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: session,
      // A new key each time: a second pump in one test starts the page afresh.
      child: MaterialApp(key: UniqueKey(), home: EventDetailScreen(event: EventItem.fromApi(event))),
    ),
  );
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    FakeApi.restore();
    MessageLanguage.filipino.value = false;
  });

  group('what the server sends', () {
    test('an event row carries its registration: places, closing time and count', () {
      final e = EventItem.fromApi(
        _event(
          registration: {
            'open': 'true',
            'capacity': '50',
            'closes_at': '2026-11-05T17:00:00+08:00',
            'count': 38,
            'full': false,
          },
        ),
      );
      final r = e.registration!;
      expect(r.open, isTrue);
      expect(r.capacity, 50);
      expect(r.placesLeft, 12);
      expect(r.isFull, isFalse);
      final closes = DateTime.parse('2026-11-05T17:00:00+08:00');
      expect(r.closesAt, closes);
      expect(r.closedBy(closes.subtract(const Duration(minutes: 1))), isFalse);
      expect(r.closedBy(closes), isTrue);

      // An older server sends no block: the event offers no registration.
      expect(EventItem.fromApi({'key': 'k', 'name': 'Pulong', 'date': _day(2)}).registration, isNull);
      expect(_info({'open': 0}).open, isFalse);

      // No limit: never full on its own count, and no places-left line.
      final unlimited = _info({'open': true, 'capacity': null, 'count': 400});
      expect(unlimited.placesLeft, isNull);
      expect(unlimited.isFull, isFalse);
      expect(_info({'open': true, 'capacity': 0, 'count': 3}).capacity, isNull, reason: 'zero is no limit');

      // Full by the count, or by the server's own word.
      expect(_info({'open': true, 'capacity': 50, 'count': 50}).isFull, isTrue);
      expect(_info({'open': true, 'capacity': 50, 'count': 52}).placesLeft, 0);
      expect(_info({'open': true, 'count': 3, 'full': true}).isFull, isTrue);
    });

    test('a registration reads its code, attendance and certificate; a row it cannot use is skipped', () {
      final r = EventRegistration.fromApi(_registration())!;
      expect(r.eventKey, _key);
      expect(r.code, 'ABCD2345');
      expect(r.displayCode, 'ABCD-2345');
      expect(r.active, isTrue);
      expect(r.attended, isNull);
      expect(r.certificate, isNull);
      expect(r.registeredAt, DateTime.parse('2026-10-28T09:00:00+08:00'));

      final done = EventRegistration.fromApi(_registration(attended: true, certificate: _certificate))!;
      expect(done.attended, isTrue);
      expect(done.certificate?.controlNumber, 'EVT-2026-000001');
      expect(done.certificate?.verifyUrl, _verifyUrl);

      expect(EventRegistration.fromApi({..._registration(), 'attended': '0'})!.attended, isFalse);
      expect(
        EventRegistration.fromApi(_registration(certificate: {'control_number': 'EVT-2026-000002'}))!.certificate,
        isNull,
        reason: 'nothing to open without its verify URL',
      );
      expect(EventRegistration.fromApi(_registration(cancelledAt: '2026-10-29T10:00:00+08:00'))!.active, isFalse);

      // The reply to registering may not name its event.
      expect(EventRegistration.fromApi({'code': 'WXYZ6789'}, eventKey: _key)?.eventKey, _key);

      final rows = JsonRead.rows([
        _registration(),
        {'code': 'NOKEY234'},
        {'event_key': 'no-code'},
        'not a row',
      ], EventRegistration.fromApi);
      expect(rows.map((r) => r.code), ['ABCD2345']);

      expect(formatRegistrationCode('abcd2345'), 'ABCD-2345');
      expect(formatRegistrationCode('ABCD-2345'), 'ABCD-2345');
      expect(formatRegistrationCode(' abc '), 'ABC');
    });

    test('the service uses the citizen routes, and a refusal keeps the server\'s words', () async {
      final server = _Server(
        mine: [
          _registration(key: 'other-event'),
          _registration(cancelledAt: '2026-10-29T10:00:00+08:00'),
        ],
      )..install();

      expect((await EventRegistrationService.mine()).length, 2);
      expect(await EventRegistrationService.forEvent(_key), isNull, reason: 'a cancelled one holds no place');

      final registered = await EventRegistrationService.register(_key);
      expect(registered.displayCode, 'ABCD-2345');
      expect(server.calls('POST', _path), hasLength(1));
      expect((await EventRegistrationService.forEvent(_key))?.code, 'ABCD2345');

      await EventRegistrationService.cancel(_key);
      expect(server.calls('DELETE', _path), hasLength(1));

      expect((await EventRegistrationService.summary(_key))?.placesLeft, 12);

      _Server(
        registerError: const FakeApiError(
          status: 409,
          code: 'EVENT_FULL',
          messageEn: 'This event is full.',
          messageFil: 'Puno na ang kaganapang ito.',
        ),
      ).install();
      await expectLater(
        EventRegistrationService.register(_key),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.code, 'code', EventRegistrationService.eventFull)
              .having((e) => e.message(filipino: true), 'Filipino', 'Puno na ang kaganapang ito.'),
        ),
      );
    });

    test('a reply that does not carry the registration is read back from the list', () async {
      final mine = <Map<String, dynamic>>[];
      FakeApi.installFull((r) {
        if (r.method == 'POST') {
          mine.add(_registration());
          return <String, dynamic>{};
        }
        if (r.path == '/citizen/event-registrations') return mine;
        throw const FakeApiError();
      });
      expect((await EventRegistrationService.register(_key)).code, 'ABCD2345');
    });
  });

  test('"Your certificate is ready" opens the event it names, else the Events tab', () {
    ServerNotification n(String link) => ServerNotification(
      id: 1,
      category: 'community',
      title: 'Your certificate is ready',
      body: 'b',
      pill: 'Event',
      ref: null,
      link: link,
      unread: true,
      pinned: false,
      at: DateTime(2026, 10, 30),
    );

    expect((serverNotificationDestination(n('/citizen/events?event=$_key'))! as EventLinkScreen).eventKey, _key);
    final tab = serverNotificationDestination(n('/citizen/events'));
    expect(tab, isA<ShellTabLink>());
    expect((tab! as ShellTabLink).tab, 2);
  });

  group('the event page', () {
    testWidgets('open: Register shows the places left, registers, then shows the code and its QR', (tester) async {
      final server = _Server()..install();
      await _pump(tester, _event());

      expect(find.byKey(const Key('event_registration_open')), findsOneWidget);
      expect(find.text('Registration is open'), findsOneWidget);
      expect(find.text('12 of 50 places left'), findsOneWidget);
      expect(find.text('Remind me a day before'), findsOneWidget);

      await _tap(tester, find.text('Register'));

      expect(server.calls('POST', _path), hasLength(1));
      expect(find.text('You are registered'), findsOneWidget);
      expect(find.text('ABCD-2345'), findsOneWidget);
      expect(tester.widget<QrImageView>(find.byType(QrImageView)).semanticsLabel, 'QR code of your code');
      expect(find.text('Cancel registration'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
      // Registering turned the day-before reminder on, on the server.
      expect(find.text('Reminder on · Turn off'), findsOneWidget);
      expect(find.text('You are registered. We will remind you the day before.'), findsOneWidget);
    });

    testWidgets('registered: Cancel asks first, then frees the place', (tester) async {
      final server = _Server(mine: [_registration()])..install();
      await _pump(tester, _event());

      expect(find.byKey(const Key('event_registration_registered')), findsOneWidget);
      expect(find.text('ABCD-2345'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);

      await _tap(tester, find.text('Cancel registration'));
      expect(find.text('Cancel your registration?'), findsOneWidget);
      await _tap(tester, find.text('Keep it'));
      expect(server.calls('DELETE', _path), isEmpty);
      expect(find.text('You are registered'), findsOneWidget);

      await _tap(tester, find.text('Cancel registration'));
      // The sheet's own button, over the page's.
      await _tap(tester, find.text('Cancel registration').last);
      expect(server.calls('DELETE', _path), hasLength(1));
      expect(find.text('Your registration was cancelled.'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('ABCD-2345'), findsNothing);
    });

    testWidgets('full: says so and offers no Register', (tester) async {
      _Server().install();
      await _pump(tester, _event(registration: _openRegistration(count: 50, full: true)));

      expect(find.byKey(const Key('event_registration_full')), findsOneWidget);
      expect(find.text('This event is full'), findsOneWidget);
      expect(find.text('All 50 places are taken. Check again later in case a place opens up.'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
    });

    testWidgets('closed: a closing time that has passed says so and offers no Register', (tester) async {
      _Server().install();
      final closed = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
      await _pump(tester, _event(registration: _openRegistration(closesAt: closed)));

      expect(find.byKey(const Key('event_registration_closed')), findsOneWidget);
      expect(find.text('Registration is closed'), findsOneWidget);
      expect(find.text('Register'), findsNothing);
    });

    testWidgets("a refusal is shown in the server's words, and the page follows it", (tester) async {
      final server = _Server(
        registerError: const FakeApiError(
          status: 409,
          code: 'EVENT_FULL',
          messageEn: 'Sorry, every place was just taken.',
          messageFil: 'Paumanhin, naubos na ang mga puwesto.',
        ),
        event: _event(registration: _openRegistration(count: 50, full: true)),
      )..install();
      await _pump(tester, _event(registration: _openRegistration(count: 49)));
      expect(find.text('1 of 50 places left'), findsOneWidget);

      await _tap(tester, find.text('Register'));
      expect(server.calls('POST', _path), hasLength(1));
      expect(find.text('Sorry, every place was just taken.'), findsOneWidget);
      expect(find.text('This event is full'), findsOneWidget);
      expect(find.text('Register'), findsNothing);

      _Server(
        registerError: const FakeApiError(
          status: 422,
          code: 'REGISTRATION_CLOSED',
          messageEn: 'Registration for this event has closed.',
          messageFil: 'Sarado na ang pagpaparehistro para sa kaganapang ito.',
        ),
      ).install();
      await _pump(tester, _event());
      await _tap(tester, find.text('Register'));
      expect(find.text('Registration for this event has closed.'), findsOneWidget);
      expect(find.text('Registration is closed'), findsOneWidget);
    });

    testWidgets('attended: "You attended", and the certificate opens in the browser', (tester) async {
      final opened = <Uri>[];
      final original = EventRegistrationPanel.openInBrowser;
      EventRegistrationPanel.openInBrowser = (uri) async {
        opened.add(uri);
        return true;
      };
      addTearDown(() => EventRegistrationPanel.openInBrowser = original);

      _Server(mine: [_registration(attended: true, certificate: _certificate)]).install();
      await _pump(tester, _event(inDays: -3));

      expect(find.byKey(const Key('event_registration_attended')), findsOneWidget);
      expect(find.text('You attended'), findsOneWidget);
      expect(find.text('Certificate no. EVT-2026-000001'), findsOneWidget);
      expect(find.text('Cancel registration'), findsNothing, reason: 'the event is over');

      await _tap(tester, find.text('View certificate'));
      expect(opened, [Uri.parse(_verifyUrl)]);

      // Attended, certificate not issued (or the event gives none).
      _Server(mine: [_registration(attended: true)]).install();
      await _pump(tester, _event(inDays: -3));
      expect(find.text('You attended'), findsOneWidget);
      expect(find.text('View certificate'), findsNothing);
      expect(find.text('If this event gives certificates, you will be told when yours is ready.'), findsOneWidget);

      // Marked as not attending.
      _Server(mine: [_registration(attended: false)]).install();
      await _pump(tester, _event(inDays: -3));
      expect(find.text('You were not recorded as attending'), findsOneWidget);
    });

    testWidgets('signed out: a prompt to sign in, which opens the account notice', (tester) async {
      final server = _Server()..install();
      await _pump(tester, _event(), signedIn: false);

      expect(server.calls('GET', '/citizen/event-registrations'), isEmpty);
      expect(find.text('12 of 50 places left'), findsOneWidget);
      expect(find.text('You need an account to register.'), findsOneWidget);
      expect(find.text('Register'), findsNothing);

      await _tap(tester, find.text('Sign in to register'));
      expect(find.byType(RestrictedFeatureNotice), findsOneWidget);
      expect(find.text('Event registration'), findsOneWidget);
    });

    testWidgets('an event without registration, or past and not registered, shows none of it', (tester) async {
      _Server().install();
      await _pump(tester, _event(registration: {'open': false, 'count': 0}));
      expect(find.byType(EventRegistrationPanel), findsOneWidget);
      expect(find.textContaining('Regist'), findsNothing);

      final noBlock = _event()..remove('registration');
      await _pump(tester, noBlock);
      expect(find.textContaining('Regist'), findsNothing);

      await _pump(tester, _event(inDays: -2));
      expect(find.textContaining('Regist'), findsNothing);
    });

    testWidgets('Filipino first: Magparehistro, Nakarehistro ka, Dumalo ka, Tingnan ang sertipiko', (tester) async {
      MessageLanguage.filipino.value = true;

      _Server().install();
      await _pump(tester, _event());
      expect(find.text('Bukas ang pagpaparehistro'), findsOneWidget);
      expect(find.text('May 12 pang bakanteng puwesto sa 50'), findsOneWidget);
      expect(find.text('Magparehistro'), findsOneWidget);

      _Server(mine: [_registration()]).install();
      await _pump(tester, _event());
      expect(find.text('Nakarehistro ka'), findsOneWidget);
      expect(find.text('Kanselahin ang pagpaparehistro'), findsOneWidget);

      _Server(mine: [_registration(attended: true, certificate: _certificate)]).install();
      await _pump(tester, _event(inDays: -3));
      expect(find.text('Dumalo ka'), findsOneWidget);
      expect(find.text('Tingnan ang sertipiko'), findsOneWidget);
    });
  });
}
