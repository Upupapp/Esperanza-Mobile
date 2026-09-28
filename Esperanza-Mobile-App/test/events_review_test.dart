// The Events review: what a real event from GET /events carries that the
// card did not show, and past events that read as upcoming.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/announcement.dart';
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
          body: Column(
            children: [
              EventCard(event: withAll),
              EventCard(event: bare),
            ],
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

  testWidgets('past events sit under their own heading, after the upcoming ones', (tester) async {
    FakeApi.installFull((r) {
      if (r.path == '/events') {
        return [
          {'name': 'Coastal Clean-up Drive', 'date': _day(-18)},
          {'name': 'Barangay Health Day', 'date': _day(7)},
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

    final upcoming = tester.getTopLeft(find.text('Barangay Health Day')).dy;
    final heading = tester.getTopLeft(find.text('Past events')).dy;
    final past = tester.getTopLeft(find.text('Coastal Clean-up Drive')).dy;
    expect(upcoming, lessThan(heading));
    expect(heading, lessThan(past));
  });
}
