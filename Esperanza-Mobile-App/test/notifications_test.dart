// Verifies the Notifications feed: the profile-completion reminder shows
// only while incomplete and disappears once complete, server notifications
// (GET /citizen/notifications) render and open their request, and nothing
// fabricated reaches anyone -- the old illustrative samples ("Typhoon
// Advisory") are gone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/notifications/notifications_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/resident_profile_overview_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/notification_feed.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/screens/profile/profile_screen.dart';
import 'package:esperanza_mobile/screens/shared/my_requests_screen.dart';
import 'package:esperanza_mobile/screens/support/help_support_screen.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_status.dart';
import 'package:esperanza_mobile/utils/date_text.dart';
import 'package:esperanza_mobile/widgets/status_chip.dart';

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
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed-in resident with an incomplete profile sees the "Complete Your Profile" reminder', (
    tester,
  ) async {
    await _pump(tester, account: _incompleteAccount);

    expect(find.text('Complete Your Profile'), findsOneWidget);
    expect(find.text('Action Required'), findsWidgets); // badge label, may also appear on other tiles
    expect(find.text('Complete Profile'), findsOneWidget); // the action link

    await tester.tap(find.text('Complete Your Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ResidentProfileOverviewScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the profile reminder disappears once the profile is 100% complete', (tester) async {
    final service = ResidentProfileService();
    // No need to wait for the service's background SharedPreferences
    // restore here: with setMockInitialValues({}) there is nothing
    // stored, so _restore() never reassigns _profiles and profileFor()
    // below is safe to call immediately. (`await Future.delayed(...)`
    // was tried here first — it hangs forever under flutter_test's fake
    // clock, which never advances a real Timer.)
    final profile = service.profileFor(_incompleteAccount);
    profile.personal
      ..firstName = 'Test'
      ..lastName = 'Resident'
      ..sex = 'Male'
      ..birthdate = DateTime(1990, 1, 1)
      ..civilStatus = 'Single'
      ..mobile = '0900 000 0000'
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
    expect(profile.overallCompletionPercent, 100);

    await _pump(tester, account: _incompleteAccount, residentProfileService: service);

    expect(find.text('Complete Your Profile'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guest (no account) sees no reminder and nothing fabricated', (tester) async {
    await _pump(tester);

    expect(find.text('Complete Your Profile'), findsNothing);
    expect(find.textContaining('Typhoon Advisory'), findsNothing);
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('server notifications render in Filipino, mark read on the server, and open their request', (
    tester,
  ) async {
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

    test('a support reply opens Help & Support, not the ticket as a request', () {
      expect(
        serverNotificationDestination(n(link: '/citizen/help/support', ref: 'TKT-2026-0042', category: 'account')),
        isA<HelpSupportScreen>(),
      );
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
