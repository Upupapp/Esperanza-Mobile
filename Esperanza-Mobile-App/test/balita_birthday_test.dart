// On the citizen's birthday Balita opens with a greeting card (the owner's
// design, canvas "Balita Birthday Theme", artboard A). Only that citizen sees
// it: it is drawn on the phone from their own birthdate, never posted or sent.
// Closing it puts it away until the next birthday. Synthetic identities only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/balita/balita_screen.dart';
import 'package:esperanza_mobile/screens/balita/birthday_greeting_card.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/utils/birthday.dart';

import 'support/fake_api.dart';

CitizenAccount _citizen(String birthdate, {String id = 'ESP-RES-2026-000777', String firstName = 'Testa'}) =>
    CitizenAccount(
      id: id,
      firstName: firstName,
      lastName: 'Sintetiko',
      email: 'testa@esperanza-test.invalid',
      mobile: '09170000000',
      barangay: 'Poblacion',
      purok: '—',
      address: '—',
      birthdate: birthdate,
      sex: 'Female',
      civilStatus: 'Single',
      occupation: '—',
      profileCompleteness: 100,
      status: 'Approved',
    );

Future<void> _pumpBalita(WidgetTester tester, CitizenAccount account) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: const MaterialApp(home: BalitaScreen()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.element(find.byType(BalitaScreen)).read<CitizenSessionService>().login(account);
  await tester.pumpAndSettle();
}

void main() {
  final realToday = Birthday.today;
  final sent = <String>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sent.clear();
    FakeApi.installFull((r) {
      if (r.method != 'GET') sent.add('${r.method} ${r.path}');
      if (r.path == '/announcements') {
        return [
          {
            'id': 1,
            'title': 'Synthetic advisory',
            'body': 'Synthetic advisory body',
            'published_at': '2026-10-07T00:00:00Z',
          },
        ];
      }
      return <dynamic>[];
    });
  });
  tearDown(() {
    Birthday.today = realToday;
    FakeApi.restore();
  });

  group('the birthday', () {
    test('reads the server date, an ISO timestamp and an older demo date', () {
      expect(Birthday.of('1995-10-16'), DateTime(1995, 10, 16));
      expect(Birthday.of('1995-10-16T00:00:00.000000Z')?.day, 16);
      expect(Birthday.of('June 8, 1990'), DateTime(1990, 6, 8));
      expect(Birthday.of(''), isNull);
      expect(Birthday.of('—'), isNull);
    });

    test('falls on the same month and day, any year', () {
      final birth = DateTime(1995, 10, 16);
      expect(Birthday.falls(birth, DateTime(2026, 10, 16)), isTrue);
      expect(Birthday.falls(birth, DateTime(2026, 10, 17)), isFalse);
      expect(Birthday.falls(birth, DateTime(2026, 11, 16)), isFalse);
    });

    test('a 29 February birthday is kept on 28 February in other years', () {
      final birth = DateTime(2004, 2, 29);
      expect(Birthday.falls(birth, DateTime(2026, 2, 28)), isTrue);
      expect(Birthday.falls(birth, DateTime(2028, 2, 28)), isFalse);
      expect(Birthday.falls(birth, DateTime(2028, 2, 29)), isTrue);
    });

    test('needs a signed-in citizen with a birthdate', () {
      Birthday.today = () => DateTime(2026, 10, 16);
      expect(Birthday.isToday(null), isFalse);
      expect(Birthday.isToday(_citizen('')), isFalse);
      expect(Birthday.isToday(_citizen('1995-10-16')), isTrue);
    });
  });

  testWidgets('on the birthday the greeting card leads the feed', (tester) async {
    Birthday.today = () => DateTime(2026, 10, 16, 9);
    await _pumpBalita(tester, _citizen('1995-10-16'));

    expect(find.text('TODAY · OCT 16'), findsOneWidget);
    expect(find.text('Happy birthday, Testa!'), findsOneWidget);
    expect(find.textContaining('Maligayang kaarawan!'), findsOneWidget);
    expect(find.byIcon(Icons.cake_outlined), findsOneWidget);
    // Above the LGU's own posts.
    final greeting = tester.getTopLeft(find.byType(BirthdayGreetingCard)).dy;
    expect(greeting, lessThan(tester.getTopLeft(find.textContaining('Synthetic advisory').first).dy));
    // The close button is a full-size target.
    final close = tester.getSize(find.byTooltip('Dismiss birthday greeting'));
    expect(close.height, greaterThanOrEqualTo(44));
    expect(close.width, greaterThanOrEqualTo(44));
  });

  testWidgets('only the citizen sees it: nothing is posted or sent', (tester) async {
    Birthday.today = () => DateTime(2026, 10, 16);
    await _pumpBalita(tester, _citizen('1995-10-16'));
    expect(find.byType(BirthdayGreetingCard), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss birthday greeting'));
    await tester.pumpAndSettle();
    expect(sent, isEmpty, reason: 'the greeting is drawn on the phone, never written to the server');
    // Not a feed post: the feed itself holds only the LGU's own post.
    expect(tester.element(find.byType(BalitaScreen)).read<BalitaService>().posts, hasLength(1));
  });

  testWidgets('another account on the same phone does not get it', (tester) async {
    Birthday.today = () => DateTime(2026, 10, 16);
    await _pumpBalita(tester, _citizen('1988-03-02', id: 'ESP-RES-2026-000888', firstName: 'Halimbawa'));
    expect(find.byType(BirthdayGreetingCard), findsNothing);
    expect(find.textContaining('Happy birthday'), findsNothing);
  });

  testWidgets('any other day there is no greeting', (tester) async {
    Birthday.today = () => DateTime(2026, 10, 17);
    await _pumpBalita(tester, _citizen('1995-10-16'));
    expect(find.byType(BirthdayGreetingCard), findsNothing);
    expect(find.textContaining('Synthetic advisory'), findsWidgets);
  });

  testWidgets('closing it puts it away for the rest of the year; it returns next year', (tester) async {
    Birthday.today = () => DateTime(2026, 10, 16);
    await _pumpBalita(tester, _citizen('1995-10-16'));
    await tester.tap(find.byTooltip('Dismiss birthday greeting'));
    await tester.pumpAndSettle();
    expect(find.text('Happy birthday, Testa!'), findsNothing);

    // Opening Balita again the same day: still closed.
    await tester.pumpWidget(const SizedBox());
    await _pumpBalita(tester, _citizen('1995-10-16'));
    expect(find.text('Happy birthday, Testa!'), findsNothing);

    // The next birthday: back.
    Birthday.today = () => DateTime(2027, 10, 16);
    await tester.pumpWidget(const SizedBox());
    await _pumpBalita(tester, _citizen('1995-10-16'));
    expect(find.text('Happy birthday, Testa!'), findsOneWidget);
  });
}
