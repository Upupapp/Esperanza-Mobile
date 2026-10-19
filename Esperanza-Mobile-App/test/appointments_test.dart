// Appointments (scope round 2026-10-15): book a time with an office - a
// schedule, a day, a free time and the purpose - and see or cancel the
// resident's own appointments. Synthetic data; the API is faked.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/appointments/appointments_screen.dart';
import 'package:esperanza_mobile/services/appointments_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';

import 'support/fake_api.dart';

final _schedule = {
  'id': 7,
  'office': 'Municipal Civil Registrar',
  'place': 'Municipal Civil Registrar',
  'label': 'Claiming of certificates',
  'weekdays': [1, 2, 3, 4, 5],
  'start_time': '08:00',
  'end_time': '12:00',
  'slot_minutes': 30,
  'capacity': 2,
  'location': 'Ground floor, Municipal Hall',
  'notes': null,
};

Map<String, dynamic> _appointment({String status = 'Booked', bool canCancel = true}) => {
  'ref': 'APT-2026-000101',
  'status': status,
  'date': '2026-10-20',
  'start_time': '09:00',
  'end_time': '09:30',
  'when': 'Tue, Oct 20, 2026, 9:00 AM',
  'office': 'Municipal Civil Registrar',
  'place': 'Municipal Civil Registrar',
  'schedule': 'Claiming of certificates',
  'location': 'Ground floor, Municipal Hall',
  'purpose': 'Claim my birth certificate',
  'can_cancel': canCancel,
};

Future<CitizenSessionService> _pump(WidgetTester tester, Widget home, {String status = 'Approved'}) async {
  tester.view.physicalSize = const Size(390, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  final base = MockCatalog.demoAccounts.last;
  await tester.runAsync(() async {
    await pumpEventQueue();
    await session.login(CitizenAccount.fromJson({...base.toJson(), 'status': status}));
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
  return session;
}

void main() {
  tearDown(FakeApi.restore);

  test('a schedule reads as its days and hours', () {
    final s = AppointmentSchedule.fromApi(_schedule)!;
    expect(s.openText, 'Mon–Fri · 8:00 AM – 12:00 PM');
    expect(clock('13:30'), '1:30 PM');
  });

  testWidgets('a verified resident books an office, a day, a time and a purpose', (tester) async {
    Map<String, dynamic>? sent;
    FakeApi.installFull((r) {
      if (r.path == '/citizen/appointments/schedules') return [_schedule];
      if (r.path == '/citizen/appointments/schedules/7/availability') {
        return {
          'schedule': _schedule,
          'days': [
            {'date': '2026-10-19', 'weekday': 'Monday', 'closed': 'Holiday', 'slots': <dynamic>[]},
            {
              'date': '2026-10-20',
              'weekday': 'Tuesday',
              'closed': null,
              'slots': [
                {'start': '08:00', 'end': '08:30', 'left': 0},
                {'start': '09:00', 'end': '09:30', 'left': 2},
              ],
            },
          ],
        };
      }
      if (r.method == 'POST' && r.path == '/citizen/appointments') {
        sent = r.body;
        return _appointment();
      }
      return <dynamic>[];
    });
    await _pump(tester, const BookAppointmentScreen());

    await tester.tap(find.text('Municipal Civil Registrar'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('Closed'), findsOneWidget, reason: 'A closed day says so.');
    await tester.tap(find.text('Oct 20'));
    await tester.pumpAndSettle();
    expect(find.text('8:00 AM · Full'), findsOneWidget);
    await tester.tap(find.text('9:00 AM · 2 left'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Claim my birth certificate');
    await tester.ensureVisible(find.text('Confirm booking'));
    await tester.tap(find.text('Confirm booking'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(sent, {
      'schedule_id': 7,
      'date': '2026-10-20',
      'start_time': '09:00',
      'purpose': 'Claim my birth certificate',
    });
    expect(find.text('Your appointment is booked'), findsOneWidget);
    expect(find.text('Reference APT-2026-000101'), findsOneWidget);
  });

  testWidgets('a time taken meanwhile says so in plain words', (tester) async {
    FakeApi.installFull((r) {
      if (r.path == '/citizen/appointments/schedules') return [_schedule];
      if (r.path.endsWith('/availability')) {
        return {
          'days': [
            {
              'date': '2026-10-20',
              'closed': null,
              'slots': [
                {'start': '09:00', 'end': '09:30', 'left': 1},
              ],
            },
          ],
        };
      }
      if (r.method == 'POST') throw const FakeApiError(status: 422, code: 'SLOT_FULL', messageEn: 'Full.');
      return <dynamic>[];
    });
    await _pump(tester, const BookAppointmentScreen());
    await tester.tap(find.text('Municipal Civil Registrar'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oct 20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9:00 AM · 1 left'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Claim my clearance');
    await tester.ensureVisible(find.text('Confirm booking'));
    await tester.tap(find.text('Confirm booking'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('That time was just taken. Please choose another time.'), findsOneWidget);
  });

  testWidgets('an unverified account can look at the times but not book', (tester) async {
    FakeApi.installFull((r) => r.path == '/citizen/appointments/schedules' ? [_schedule] : <dynamic>[]);
    await _pump(tester, const BookAppointmentScreen(), status: 'Pending Review');
    expect(find.textContaining('Your account must be verified before you can book.'), findsOneWidget);
    expect(find.text('Municipal Civil Registrar'), findsOneWidget);
  });

  testWidgets('my appointments: upcoming first, and one is cancelled after asking', (tester) async {
    var cancelled = false;
    FakeApi.installFull((r) {
      if (r.method == 'POST' && r.path == '/citizen/appointments/APT-2026-000101/cancel') {
        cancelled = true;
        return _appointment(status: 'Cancelled', canCancel: false);
      }
      if (r.path == '/citizen/appointments') {
        return cancelled ? [_appointment(status: 'Cancelled', canCancel: false)] : [_appointment()];
      }
      return <dynamic>[];
    });
    await _pump(tester, const AppointmentsScreen());
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Tue, Oct 20, 2026, 9:00 AM'), findsOneWidget);

    await tester.tap(find.text('Cancel appointment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel appointment').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(cancelled, isTrue);
    expect(find.text('You have no upcoming appointments.'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });
}
