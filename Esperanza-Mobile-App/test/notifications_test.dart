// Verifies the Notifications feed: only what the server sent, as on the
// website (no reminders the phone makes itself), its tabs, server notifications
// (GET /citizen/notifications) render and open their request, and nothing
// fabricated reaches anyone -- the old illustrative samples ("Typhoon
// Advisory") are gone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/app_notification.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/notification_kind.dart';
import 'package:esperanza_mobile/screens/balita/balita_post_screen.dart';
import 'package:esperanza_mobile/screens/notifications/notifications_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/notification_feed.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/screens/profile/profile_screen.dart';
import 'package:esperanza_mobile/screens/shared/my_requests_screen.dart';
import 'package:esperanza_mobile/screens/support/help_support_screen.dart';
import 'package:esperanza_mobile/screens/appointments/appointments_screen.dart';
import 'package:esperanza_mobile/screens/home/root_shell.dart';
import 'package:esperanza_mobile/screens/profile/data_requests_screen.dart';
import 'package:esperanza_mobile/screens/support/support_tickets_screen.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_status.dart';
import 'package:esperanza_mobile/utils/date_text.dart';
import 'package:esperanza_mobile/widgets/status_chip.dart';
import 'package:esperanza_mobile/services/message_language.dart';

import 'support/fake_api.dart';

final _incompleteAccount = CitizenAccount(
  id: 'ESP-TEST-1',
  firstName: 'Test',
  lastName: 'Resident',
  email: 'test@example.com',
  mobile: '0900 000 0000',
  barangay: 'Poblacion',
  purok: 'Purok 1',
  address: 'Purok 1, Brgy. Poblacion',
  birthdate: '—',
  sex: '—',
  civilStatus: '—',
  occupation: '—',
  profileCompleteness: 10,
  status: 'Pending Review',
);

Future<void> _pump(
  WidgetTester tester, {
  CitizenAccount? account,
  ResidentProfileService? residentProfileService,
  NotificationsService? notifications,
}) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  if (account != null) await session.login(account);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider<ResidentProfileService>.value(value: residentProfileService ?? ResidentProfileService()),
        ChangeNotifierProvider<NotificationsService>.value(value: notifications ?? NotificationsService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("an incomplete profile adds no reminder of the app's own, as on the website", (tester) async {
    await _pump(tester, account: _incompleteAccount);
    expect(find.text('Complete Your Profile'), findsNothing);
    expect(find.text('No notifications yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guest (no account) sees no reminder and nothing fabricated', (tester) async {
    await _pump(tester);

    expect(find.text('Complete Your Profile'), findsNothing);
    expect(find.textContaining('Typhoon Advisory'), findsNothing);
    expect(find.text('No notifications yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // The website's redesign (28 Nov 2026, after eBPCO's): All / Unread with
  // counts, Category (the kinds this resident has), Search and When, Clear
  // filters; an unread notice has a blue dot that marks it read.
  Future<NotificationsService> pumpThree(WidgetTester tester, {List<String>? posts}) async {
    Map<String, dynamic> row(int id, String category, String title, {bool pinned = false, String time = ''}) => {
      'id': id,
      'category': category,
      'title': {'fil': title, 'en': title},
      'body': {'fil': '$title body', 'en': '$title body'},
      'ref': '${category.toUpperCase()}-$id',
      'unread': true,
      'pinned': pinned,
      'time': time,
    };
    FakeApi.installFull((r) {
      if (r.path == '/citizen/notifications') {
        return [
          row(1, 'dokyu', 'Dokyu update', time: '2026-09-28T03:00:00Z'),
          row(2, 'tulong', 'Tulong update', time: '2026-09-28T02:00:00Z'),
          row(3, 'account', 'Pinned notice', pinned: true, time: '2026-09-01T00:00:00Z'),
        ];
      }
      if (r.method == 'POST') {
        posts?.add(r.path);
        return {'unread': false};
      }
      return <dynamic>[];
    });
    addTearDown(FakeApi.restore);
    final notifications = NotificationsService();
    await _pump(tester, account: _incompleteAccount, notifications: notifications);
    await tester.runAsync(notifications.loadServer);
    await tester.pumpAndSettle();
    return notifications;
  }

  testWidgets('All / Unread with counts, the kinds under Category, pinned first', (tester) async {
    await pumpThree(tester);

    // Pinned first, though it is the oldest.
    expect(tester.getTopLeft(find.text('Pinned notice')).dy, lessThan(tester.getTopLeft(find.text('Dokyu update')).dy));
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Unread (3)'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Read'), findsNothing, reason: 'no Read tab any more');
    expect(find.text('Clear filters'), findsNothing, reason: 'only once something is filtered');

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    expect(find.text('Dokyu (1)'), findsOneWidget);
    expect(find.text('Tulong (1)'), findsOneWidget);
    expect(find.text('Account (1)'), findsOneWidget);
    await tester.tap(find.text('Dokyu (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Dokyu update'), findsOneWidget);
    expect(find.text('Tulong update'), findsNothing);
    expect(find.text('Pinned notice'), findsNothing);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Tulong update'), findsOneWidget);
    expect(find.text('Pinned notice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search looks in the title, message and reference; When narrows by day; the empty state leads back', (tester) async {
    await pumpThree(tester);

    await tester.enterText(find.byType(TextField), 'tulong-2');
    await tester.pumpAndSettle();
    expect(find.text('Tulong update'), findsOneWidget);
    expect(find.text('Dokyu update'), findsNothing);
    expect(find.text('Clear filters'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Any time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today').last);
    await tester.pumpAndSettle();
    // Every notice here is from September.
    expect(find.text('No notifications match these filters.'), findsOneWidget);
    await tester.tap(find.text('Show all notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Dokyu update'), findsOneWidget);
    expect(find.text('Any time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the blue dot marks one read on the server; the Unread list keeps it until reopened', (tester) async {
    final posts = <String>[];
    final notifications = await pumpThree(tester, posts: posts);

    await tester.tap(find.text('Unread (3)'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Mark as read'), findsNWidgets(3));

    await tester.tap(find.byKey(const ValueKey('mark-read-srv-1')));
    await tester.pumpAndSettle();
    expect(posts, ['/citizen/notifications/1/read']);
    expect(notifications.isRead('srv-1'), isTrue);
    expect(find.text('Unread (2)'), findsOneWidget);
    expect(find.text('Dokyu update'), findsOneWidget, reason: 'still listed, now plain');
    expect(find.byKey(const ValueKey('mark-read-srv-1')), findsNothing, reason: 'no dot once read');
    expect(tester.takeException(), isNull);
  });

  test('the When choices: today, the last 7 and 30 days from midnight, or one day', () {
    final now = DateTime(2026, 11, 28, 10);
    AppNotification at(DateTime d) => AppNotification(id: 'x', kind: NotificationKind.info, icon: Icons.info, title: 't', body: 'b', at: d);
    bool when(DateTime d, NotificationWhen w, [DateTime? date]) =>
        notificationMatches(at(d), unread: true, unreadOnly: false, when: w, date: date, now: now);

    expect(when(DateTime(2026, 11, 28, 0, 5), NotificationWhen.today), isTrue);
    expect(when(DateTime(2026, 11, 27, 23, 59), NotificationWhen.today), isFalse);
    expect(when(DateTime(2026, 11, 22), NotificationWhen.week), isTrue);
    expect(when(DateTime(2026, 11, 21, 23), NotificationWhen.week), isFalse);
    expect(when(DateTime(2026, 10, 30), NotificationWhen.month), isTrue);
    expect(when(DateTime(2026, 10, 29, 12), NotificationWhen.month), isFalse);
    expect(when(DateTime(2026, 11, 3, 15), NotificationWhen.on, DateTime(2026, 11, 3)), isTrue);
    expect(when(DateTime(2026, 11, 4, 1), NotificationWhen.on, DateTime(2026, 11, 3)), isFalse);
    expect(
      notificationMatches(at(now), unread: false, unreadOnly: true),
      isFalse,
      reason: 'Unread lists only the unread',
    );
  });

  testWidgets('server notifications render in Filipino, mark read on the server, and open their request', (
    tester,
  ) async {
    // These notices are checked in Filipino, the language chosen in Settings
    // (English is the default since the live test of 2026-10-07, UX-15).
    MessageLanguage.filipino.value = true;
    addTearDown(() => MessageLanguage.filipino.value = false);
    final posts = <String>[];
    FakeApi.installFull((r) {
      if (r.path == '/citizen/notifications') {
        return [
          {
            'id': 41,
            'category': 'dokyu',
            'title': {'fil': 'Naaprubahan ang iyong kahilingan', 'en': 'Your request was approved'},
            'body': {'fil': 'Naaprubahan ang DR-2026-0001.', 'en': 'Request DR-2026-0001 was approved.'},
            'pill': 'Approved',
            'ref': 'DR-2026-0001',
            'unread': true,
            'pinned': false,
            'time': '2026-09-28T01:00:00Z',
          },
        ];
      }
      if (r.method == 'POST') {
        posts.add(r.path);
        return {'unread': false};
      }
      if (r.path == '/citizen/requests/DR-2026-0001') {
        return {'ref': 'DR-2026-0001', 'type': 'dokyu', 'service': 'Cedula', 'status': 'Approved'};
      }
      return <dynamic>[];
    });
    addTearDown(FakeApi.restore);

    final notifications = NotificationsService();
    await _pump(tester, account: _incompleteAccount, notifications: notifications);
    await tester.runAsync(notifications.loadServer);
    await tester.pumpAndSettle();

    expect(find.text('Naaprubahan ang iyong kahilingan'), findsOneWidget);
    expect(notifications.isRead('srv-41'), isFalse);

    await tester.ensureVisible(find.text('Naaprubahan ang iyong kahilingan'));
    await tester.tap(find.text('Naaprubahan ang iyong kahilingan'));
    await tester.pumpAndSettle();

    expect(posts, ['/citizen/notifications/41/read']);
    expect(notifications.isRead('srv-41'), isTrue);
    expect(find.byType(RequestDetailScreen), findsOneWidget);
  });

  // Esperanza QA, 2026-10-07: a new Balita post notifies residents, and the
  // notification opens the post -- even one older than the loaded feed.
  testWidgets('a New in Balita notification opens that post', (tester) async {
    // These notices are checked in Filipino, the language chosen in Settings
    // (English is the default since the live test of 2026-10-07, UX-15).
    MessageLanguage.filipino.value = true;
    addTearDown(() => MessageLanguage.filipino.value = false);
    final gets = <String>[];
    FakeApi.installFull((r) {
      gets.add('${r.method} ${r.path}');
      if (r.path == '/citizen/notifications') {
        return [
          {
            'id': 77,
            'category': 'community',
            'title': {'fil': 'Bagong Balita: Libreng bakuna', 'en': 'New in Balita: Libreng bakuna'},
            'body': {'fil': 'Bukas ang health center.', 'en': 'Bukas ang health center.'},
            'pill': 'Balita',
            'link': '/citizen/announcements?post=7',
            'unread': true,
            'pinned': false,
            'time': '2026-10-07T01:00:00Z',
          },
        ];
      }
      if (r.path == '/announcements/7') {
        return {
          'id': 7,
          'title': 'Libreng bakuna sa Sabado',
          'body': 'Bukas ang health center mula 8 AM.',
          'author': 'MHO',
          'category': 'Health',
          'published_at': '2026-10-07T01:00:00Z',
          'likes': 0,
          'comments_count': 0,
        };
      }
      if (r.method == 'POST') return {'unread': false};
      return <dynamic>[];
    });
    addTearDown(FakeApi.restore);

    final notifications = NotificationsService();
    await _pump(tester, account: _incompleteAccount, notifications: notifications);
    await tester.runAsync(notifications.loadServer);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Bagong Balita: Libreng bakuna'));
    await tester.tap(find.text('Bagong Balita: Libreng bakuna'));
    await tester.pumpAndSettle();

    expect(find.byType(BalitaPostScreen), findsOneWidget);
    expect(gets, contains('GET /announcements/7'), reason: 'an older post is fetched by its id');
    expect(find.textContaining('Libreng bakuna sa Sabado'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a server notification wears its own status badge and says when it arrived', (tester) async {
    // "Ready for release" used to wear a generic "Approved" badge, and the
    // line where every other notification shows its time showed only the
    // request reference.
    const time = '2026-09-01T01:15:00Z';
    FakeApi.installFull((r) {
      if (r.path == '/citizen/notifications') {
        return [
          {
            'id': 42,
            'title': {'fil': 'Handa nang kunin: Barangay Clearance'},
            'body': {'fil': 'Handa nang kunin ang DR-2026-0120.'},
            'pill': 'Mark to Release',
            'ref': 'DR-2026-0120',
            'unread': true,
            'time': time,
          },
          {
            'id': 43,
            'title': {'fil': 'May bagong paalala'},
            'body': {'fil': 'Walang status ang abisong ito.'},
            'pill': 'Not A Canonical Status',
            'unread': true,
            'time': time,
          },
        ];
      }
      return <dynamic>[];
    });
    addTearDown(FakeApi.restore);

    final notifications = NotificationsService();
    await _pump(tester, account: _incompleteAccount, notifications: notifications);
    await tester.runAsync(notifications.loadServer);
    await tester.pumpAndSettle();

    final chips = tester.widgetList<StatusChip>(find.byType(StatusChip)).map((c) => c.status).toList();
    expect(chips, [AppStatus.readyForRelease], reason: 'an unknown pill keeps the generic badge');
    expect(find.text('Approved'), findsNothing);
    expect(find.text('${shortDate(DateTime.parse(time))} · DR-2026-0120'), findsOneWidget);
  });

  group('a tap goes where the server\'s link says, never to a fake request', () {
    ServerNotification n({String? link, String? ref, String? category}) => ServerNotification(
      id: 1,
      category: category,
      title: 't',
      body: 'b',
      pill: null,
      ref: ref,
      link: link,
      unread: true,
      pinned: false,
      at: DateTime(2026, 9, 28),
    );

    test('a request link opens that request', () {
      final d = serverNotificationDestination(
        n(link: '/citizen/assistance-requests/TA-2026-0031', ref: 'TA-2026-0031'),
      );
      expect(d, isA<RequestDetailScreen>());
      expect((d! as RequestDetailScreen).requestId, 'TA-2026-0031');
    });

    test('an account review opens the profile, not the account number as a request', () {
      expect(
        serverNotificationDestination(n(link: '/citizen/profile', ref: 'ESP-RES-2026-0001', category: 'account')),
        isA<ProfileScreen>(),
      );
    });

    test('a support reply opens the tickets, not the FAQs and not the ticket as a request', () {
      expect(
        serverNotificationDestination(n(link: '/citizen/help/support', ref: 'TKT-2026-0042', category: 'account')),
        isA<SupportTicketsScreen>(),
      );
      expect(serverNotificationDestination(n(link: '/citizen/help')), isA<HelpSupportScreen>());
    });

    test('the links the app could not open now lead somewhere (parity check, 2026-10-22)', () {
      // An incident's update, as IncidentLifecycle links it.
      final incident = serverNotificationDestination(n(link: '/citizen/emergency?incident=INC-2026-00012'));
      expect(incident, isA<RequestDetailScreen>());
      expect((incident! as RequestDetailScreen).requestId, 'INC-2026-00012');
      // A Sakuna alert: the Emergency tab, through the shell and its guard.
      final alert = serverNotificationDestination(n(link: '/citizen/emergency'));
      expect(alert, isA<ShellTabLink>());
      expect((alert! as ShellTabLink).tab, 3);
      expect(serverNotificationDestination(n(link: '/citizen/appointments')), isA<AppointmentsScreen>());
      expect(serverNotificationDestination(n(link: '/citizen/settings')), isA<DataRequestsScreen>());
    });

    test('a resolved data request opens My data requests, with or without the tab (Sprint 4)', () {
      expect(serverNotificationDestination(n(link: '/citizen/settings?tab=privacy')), isA<DataRequestsScreen>());
      expect(serverNotificationDestination(n(link: '/citizen/settings#privacy')), isA<DataRequestsScreen>());
      expect(serverNotificationDestination(n(link: '/citizen/settingsx')), isNot(isA<DataRequestsScreen>()));
    });

    test('a rejected payment opens the request list, not the payment as a request', () {
      expect(
        serverNotificationDestination(n(link: '/citizen/document-requests', ref: 'PAY-2026-0007', category: 'dokyu')),
        isA<MyRequestsScreen>(),
      );
    });

    test('no link: only a Dokyu/Tulong ref is treated as a request', () {
      expect(serverNotificationDestination(n(ref: 'DR-2026-0001', category: 'dokyu')), isA<RequestDetailScreen>());
      expect(serverNotificationDestination(n(ref: 'ESP-RES-2026-0001', category: 'account')), isNull);
    });

    test('an unknown link leads nowhere rather than somewhere wrong', () {
      expect(serverNotificationDestination(n(link: '/citizen/something-new', ref: 'X-1')), isNull);
    });
  });

  testWidgets('opening Notifications fetches what arrived since the app started', (tester) async {
    var loads = 0;
    FakeApi.installFull((r) {
      if (r.path == '/citizen/notifications') {
        loads++;
        return [
          {
            'id': 50,
            'title': {'fil': 'Bagong abiso'},
            'body': {'fil': 'Dumating habang bukas ang app.'},
            'time': '2026-09-28T01:00:00Z',
          },
        ];
      }
      return <dynamic>[];
    });
    addTearDown(FakeApi.restore);

    await _pump(tester, account: _incompleteAccount);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(loads, 1);
    expect(find.text('Bagong abiso'), findsOneWidget);
  });
}
