// The Events review: what a real event from GET /events carries that the
// card did not show, and past events that read as upcoming.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/screens/events/event_detail_screen.dart';
import 'package:esperanza_mobile/screens/events/events_screen.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/widgets/event_card.dart';

import 'support/fake_api.dart';

String _day(int offset) {
  final d = DateTime.now().add(Duration(days: offset));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  test('an event keeps its barangay and recurrence, and knows when it is past', () {
    final e = EventItem.fromApi({
      'name': 'Zumba sa Plaza',
      'date': _day(-1),
      'barangay': 'Baras',
      'recurrence': 'Every Saturday',
    });
    expect(e.barangay, 'Baras');
    expect(e.recurrence, 'Every Saturday');
    expect(e.isPast(DateTime.now()), isTrue);
    expect(
      EventItem.fromApi({'name': 'Today', 'date': _day(0)}).isPast(DateTime.now()),
      isFalse,
      reason: 'upcoming all day on its own date',
    );
    expect(EventItem.fromApi({'name': 'Undated'}).isPast(DateTime.now()), isFalse);
  });

  group('real start and end times (owner, 2026-11-06)', () {
    final noonToday = DateTime.now();
    String iso(DateTime d) {
      // As the server writes it: ISO-8601 in Manila time.
      final m = d.toUtc().add(const Duration(hours: 8));
      String two(int v) => v.toString().padLeft(2, '0');
      return '${m.year}-${two(m.month)}-${two(m.day)}T${two(m.hour)}:${two(m.minute)}:${two(m.second)}+08:00';
    }

    test('the times are read, and the card shows their range', () {
      final e = EventItem.fromApi({
        'name': 'Blood Letting',
        'date': _day(2),
        'time': 'Morning',
        'start_time': '08:00',
        'end_time': '12:30',
        'starts_at': '2026-11-08T08:00:00+08:00',
        'ends_at': '2026-11-08T12:30:00+08:00',
      });
      expect(e.startTime, '08:00');
      expect(e.endTime, '12:30');
      expect(e.startsAtTime, DateTime.utc(2026, 11, 8, 0, 0));
      expect(e.endsAt, DateTime.utc(2026, 11, 8, 4, 30));
      expect(e.time, '8:00 AM – 12:30 PM');
      expect(
        EventItem.fromApi({'name': 'Start only', 'start_time': '17:00', 'ends_at': '2026-11-08T23:59:59+08:00'}).time,
        '5:00 PM',
      );
      // No times (or unreadable ones): the free-text time older events carry.
      expect(EventItem.fromApi({'name': 'Old', 'time': '5:30 PM'}).time, '5:30 PM');
      expect(EventItem.fromApi({'name': 'Bad', 'start_time': '25:00', 'time': 'Afternoon'}).time, 'Afternoon');
      expect(EventItem.fromApi({'name': 'Wrong type', 'start_time': 8, 'ends_at': 12}).endsAt, isNull);
    });

    test('an event is past from its end time, not from the next day', () {
      final e = EventItem.fromApi({
        'name': 'Morning Clean-up',
        'date': _day(0),
        'start_time': '06:00',
        'end_time': '09:00',
        'ends_at': iso(noonToday.subtract(const Duration(hours: 1))),
      });
      expect(e.isPast(noonToday), isTrue, reason: 'it ended an hour ago, on its own date');
      final end = e.endsAt!;
      expect(e.isPast(end), isTrue, reason: 'at its end time it is over');
      expect(e.isPast(end.subtract(const Duration(minutes: 1))), isFalse);
      // An older server sends no ends_at: today's date-only rule.
      expect(EventItem.fromApi({'name': 'Today', 'date': _day(0)}).isPast(noonToday), isFalse);
      expect(EventItem.fromApi({'name': 'Yesterday', 'date': _day(-1)}).isPast(noonToday), isTrue);
    });

    test('calendar order uses the end time to split, and the start time to sort', () {
      final now = DateTime.now();
      final ended = EventItem.fromApi({'name': 'Ended', 'date': _day(0), 'ends_at': iso(now.subtract(const Duration(minutes: 5)))});
      final later = EventItem.fromApi({
        'name': 'Later',
        'date': _day(0),
        'starts_at': iso(now.add(const Duration(hours: 3))),
        'ends_at': iso(now.add(const Duration(hours: 4))),
      });
      final sooner = EventItem.fromApi({
        'name': 'Sooner',
        'date': _day(0),
        'starts_at': iso(now.add(const Duration(hours: 1))),
        'ends_at': iso(now.add(const Duration(hours: 2))),
      });
      expect(EventItem.inCalendarOrder([ended, later, sooner], now: now).map((e) => e.title), ['Sooner', 'Later', 'Ended']);
    });

    testWidgets('the Events tab puts an event that ended today under Past', (tester) async {
      final now = DateTime.now();
      FakeApi.installFull((r) {
        if (r.path == '/events') {
          return [
            {'name': 'Ended This Morning', 'date': _day(0), 'ends_at': iso(now.subtract(const Duration(minutes: 30)))},
            {'name': 'Still On Today', 'date': _day(0), 'ends_at': iso(now.add(const Duration(hours: 3)))},
          ];
        }
        return <dynamic>[];
      });
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
          child: const MaterialApp(home: EventsScreen()),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.text('Still On Today'), findsOneWidget);
      expect(find.text('Ended This Morning'), findsNothing);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('Ended This Morning'), findsOneWidget);
      expect(find.text('Still On Today'), findsNothing);
    });
  });

  testWidgets('the card shows only what the event has, with its barangay and recurrence', (tester) async {
    final withAll = EventItem.fromApi({
      'name': 'Zumba sa Plaza',
      'date': _day(3),
      'time': '5:30 PM',
      'venue': 'Baras Plaza',
      'barangay': 'Baras',
      'recurrence': 'Every Saturday',
    });
    final bare = EventItem.fromApi({'name': 'Planning Meeting', 'date': _day(9)});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                EventCard(event: withAll),
                EventCard(event: bare),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Baras Plaza · Brgy. Baras'), findsOneWidget);
    expect(find.text('Every Saturday'), findsOneWidget);
    // One clock and one pin, both on the full card: the bare one has
    // neither, rather than empty rows.
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
  });

  testWidgets('Upcoming and Past are separate pills, as in the PAAIPE app, and a card opens its event', (tester) async {
    FakeApi.installFull((r) {
      if (r.path == '/events') {
        return [
          {'name': 'Coastal Clean-up Drive', 'date': _day(-18)},
          {'name': 'Barangay Health Day', 'date': _day(7), 'category': 'Health'},
        ];
      }
      return <dynamic>[];
    });
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        child: const MaterialApp(home: EventsScreen()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('Barangay Health Day'), findsOneWidget);
    expect(find.text('Coastal Clean-up Drive'), findsNothing, reason: 'a past event is not upcoming');
    expect(
      tester.getSize(find.ancestor(of: find.text('Past'), matching: find.byType(InkWell)).first).height,
      greaterThanOrEqualTo(44),
    );

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(find.text('Coastal Clean-up Drive'), findsOneWidget);
    expect(find.text('Barangay Health Day'), findsNothing);

    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barangay Health Day'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
  });


  testWidgets('the Web Admin description previews on the card and shows in full on the page', (tester) async {
    final long = List.filled(40, 'Free check-ups for all ages.').join(' ');
    final e = EventItem.fromApi({'name': 'Health Day', 'date': _day(4), 'description': long});
    expect(e.description, long);
    expect(EventItem.fromApi({'name': 'Old event', 'date': _day(4)}).description, isNull);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: EventCard(event: e)))));
    final preview = tester.widget<Text>(find.text(long));
    expect(preview.maxLines, 3);

    await tester.pumpWidget(MaterialApp(home: EventDetailScreen(event: e)));
    expect(tester.widget<Text>(find.text(long)).maxLines, isNull);
  });
}
