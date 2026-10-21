// Occasion pop-ups (2026-10-19; their own server feature since 2026-10-21):
// an LGU greeting for a fiesta, a holiday, an LGU event - written, scheduled
// and approved by the LGU - pops up when a resident opens the app, as the
// server decides. Balita posts are only posts now: no "greeting" kind, no
// "Pagbati" chip. Synthetic identities only.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/occasion_greeting.dart';
import 'package:esperanza_mobile/screens/balita/balita_post_screen.dart';
import 'package:esperanza_mobile/screens/balita/post_card.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/widgets/birthday_popup.dart';
import 'package:esperanza_mobile/widgets/home_welcome_banner.dart';
import 'package:esperanza_mobile/widgets/occasion_greeting_popup.dart';

import 'support/fake_api.dart';

final _account = CitizenAccount(
  id: 'ESP-RES-2026-000555',
  firstName: 'Halimbawa',
  lastName: 'Sintetiko',
  email: 'halimbawa@esperanza-test.invalid',
  mobile: '09170000001',
  barangay: 'Baras',
  purok: '',
  address: '',
  birthdate: '1990-03-03',
  sex: 'Female',
  civilStatus: '',
  occupation: '',
  profileCompleteness: 100,
  status: 'Approved',
  identityStatus: 'Verified',
  serverAccessLevel: 'Verified',
);

Map<String, dynamic> _popup({int? postId = 41, Map<String, dynamic>? button, bool dismissible = false}) => {
  'id': 41,
  'occurrence': '2026-12-25',
  'type': 'national_holiday',
  'type_label': {'en': 'National Holiday', 'fil': 'Pambansang pista opisyal'},
  'birthday': false,
  'title': 'Maligayang Pasko, Esperanza!',
  'message': 'Isang mapayapa at masayang Pasko sa inyong lahat.',
  'image_url': null,
  'image_alt': '',
  'frequency': 'daily',
  'dismissal': dismissible ? 'until_dismissed' : 'seen',
  'dismissible': dismissible,
  'post_id': postId,
  'button': button ?? {'label': null, 'url': null},
};

Map<String, dynamic> _post() => {
  'id': 41,
  'title': 'Maligayang Pasko, Esperanza!',
  'body': 'Isang mapayapa at masayang Pasko sa inyong lahat.',
  'category': 'Community',
  'barangay': null,
  'author': 'Esperanza LGU',
  'published_at': '2026-12-24T16:00:00+00:00',
  'likes': 0,
  'comments_count': 0,
};

/// What the app asked the server, as "METHOD path".
final _asked = <String>[];

void _serve({Map<String, dynamic>? popup}) {
  _asked.clear();
  FakeApi.installFull((r) {
    _asked.add('${r.method} ${r.path}');
    if (r.path == '/citizen/popups/active') return popup;
    if (r.path == '/citizen/popups/41/seen') return {'id': 41, 'recorded': true, 'times_seen': 1};
    if (r.path == '/citizen/popups/41/dismiss') return {'id': 41, 'dismissed': true};
    if (r.path == '/announcements/41') return _post();
    if (r.path == '/citizen/profile') return const <String, dynamic>{};
    return <dynamic>[];
  });
}

Future<void> _launchSignedIn(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    'esperanza_citizen_session': jsonEncode(_account.toJson()),
    'esperanza_api_token': 'synthetic-token',
  });
  await tester.pumpWidget(const EsperanzaMobileApp());
  await tester.pumpAndSettle();
}

void main() {
  tearDown(FakeApi.restore);

  group('reading what the server sends', () {
    test('a pop-up, with only a web link ever opened', () {
      final g = OccasionGreeting.fromApi(_popup(button: {'label': 'Basahin', 'url': 'https://esperanza.gov.ph/pasko'}));
      expect(g.id, 41);
      expect(g.postId, 41);
      expect(g.birthday, isFalse);
      expect(g.dismissible, isFalse);
      expect(g.imageUrl, isNull);
      expect(g.imageAlt, 'Maligayang Pasko, Esperanza!', reason: 'an empty alt text falls back to the title');
      expect(g.buttonLabel, 'Basahin');
      expect(g.buttonUrl, 'https://esperanza.gov.ph/pasko');
      expect(g.occasion!.key, 'national_holiday');
      expect(g.occasion!.label(filipino: true), 'Pambansang pista opisyal');
      expect(g.occasion!.label(filipino: false), 'National Holiday');

      final unsafe = OccasionGreeting.fromApi(_popup(button: {'label': 'Open', 'url': 'javascript:alert(1)'}));
      expect(unsafe.buttonUrl, isNull);
      expect(() => OccasionGreeting.fromApi({'id': 1}), throwsFormatException, reason: 'no title');
    });

    test('its picture is a media link resolved against the API, with its own alt text', () {
      final g = OccasionGreeting.fromApi({
        ..._popup(),
        'image_url': '/api/v1/media/popup-41?signature=synthetic',
        'image_alt': 'Parol sa plaza',
      });
      expect(g.imageUrl, startsWith('http'));
      expect(g.imageUrl, endsWith('/api/v1/media/popup-41?signature=synthetic'));
      expect(g.imageAlt, 'Parol sa plaza');
    });

    test('an older server\'s greeting shape still reads', () {
      final g = OccasionGreeting.fromApi({
        'id': 7,
        'title': 'Maligayang Pista!',
        'message': '',
        'occasion': 'custom',
        'occasion_label': {'en': 'Custom Occasion', 'fil': 'Ibang okasyon'},
        'occasion_name': 'Pista ng Barangay Baras',
        'poster_url': 'https://esperanza.gov.ph/poster.png',
        'post_id': '7',
      });
      expect(g.imageUrl, 'https://esperanza.gov.ph/poster.png', reason: 'poster_url when there is no image_url');
      expect(g.occasion!.label(filipino: true), 'Pista ng Barangay Baras');
      expect(g.postId, 7);
      expect(g.birthday, isFalse);
      expect(g.dismissible, isFalse);
    });

    test("the pop-up names the kind of occasion, as the website does, not the staff's working title", () {
      final o = GreetingOccasion.fromApi({
        'type': 'barangay_fiesta',
        'type_label': {'en': 'Barangay Fiesta', 'fil': 'Pista ng Barangay'},
        'occasion_name': 'Pista 2026 (copy)',
      });
      expect(o!.label(filipino: true), 'Pista ng Barangay');
      expect(o.label(filipino: false), 'Barangay Fiesta');
    });

    test('a custom occasion with no label is not called "custom"', () {
      final o = GreetingOccasion.fromApi({'type': 'custom', 'type_label': null});
      expect(o!.label(filipino: true), isNull);
    });

    test('a Balita post reads the same with or without the old greeting keys', () {
      final plain = Announcement.fromAnnouncementApi(_post());
      final old = Announcement.fromAnnouncementApi({
        ..._post(),
        'post_type': 'greeting',
        'greeting': {'occasion': 'holiday', 'occasion_label': 'not a map'},
      });
      expect(plain.title, 'Maligayang Pasko, Esperanza!');
      expect(old.title, plain.title);
      expect(old.body, plain.body);
      expect(Announcement.fromAnnouncementApi({'id': 7, 'title': 'Older server'}).remoteId, 7);
    });

    test('Home is offered its opening pop-ups once per launch or sign-in', () async {
      SharedPreferences.setMockInitialValues({});
      final session = CitizenSessionService();
      addTearDown(session.dispose);
      expect(session.takeLaunchPopups(), isTrue);
      expect(session.takeLaunchPopups(), isFalse, reason: 'coming back to Home does not ask again');
      await session.login(_account);
      expect(session.takeLaunchPopups(), isTrue, reason: 'a new sign-in asks again');
      expect(session.takeLaunchPopups(), isFalse);
    });
  });

  testWidgets('a due pop-up shows on opening, counts as seen once, and comes before the welcome poster', (
    tester,
  ) async {
    _serve(popup: _popup());
    await _launchSignedIn(tester);

    expect(find.byType(OccasionGreetingPopup), findsOneWidget);
    expect(find.text('Maligayang Pasko, Esperanza!'), findsOneWidget);
    expect(find.text('GREETING · NATIONAL HOLIDAY'), findsOneWidget);
    expect(find.byType(HomeWelcomeBanner), findsNothing, reason: 'the poster waits');
    expect(_asked.where((a) => a == 'POST /citizen/popups/41/seen'), hasLength(1));
    expect(_asked.where((a) => a.contains('/citizen/greetings/')), isEmpty, reason: 'the old routes are not used');
    expect(find.text('Huwag nang ipakita'), findsNothing, reason: 'not dismissible');

    await tester.tap(find.text('Salamat!'));
    await tester.pumpAndSettle();
    expect(find.byType(OccasionGreetingPopup), findsNothing);
    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
    expect(_asked.where((a) => a == 'GET /citizen/popups/active'), hasLength(1), reason: 'asked once per launch');
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Tingnan sa Balita" opens its post, a post like any other', (tester) async {
    _serve(popup: _popup());
    await _launchSignedIn(tester);

    await tester.tap(find.text('Tingnan sa Balita'));
    await tester.pumpAndSettle();
    expect(find.byType(OccasionGreetingPopup), findsNothing);
    expect(find.byType(BalitaPostScreen), findsOneWidget);
    // The welcome poster waits for next time rather than opening over the
    // post the resident chose (seen on the emulator, 2026-10-19).
    expect(find.byType(HomeWelcomeBanner), findsNothing);
    expect(find.descendant(of: find.byType(PostCard), matching: find.text('Greeting')), findsNothing);
    expect(find.descendant(of: find.byType(PostCard), matching: find.text('Pagbati')), findsNothing);
  });

  testWidgets('a pop-up-only greeting offers no post, only thanks', (tester) async {
    _serve(popup: _popup(postId: null));
    await _launchSignedIn(tester);
    expect(find.text('Tingnan sa Balita'), findsNothing);
    expect(find.text('Salamat!'), findsOneWidget);
    // Every button is a full-size target.
    expect(tester.getSize(find.byTooltip('Close')).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(find.widgetWithText(TextButton, 'Salamat!')).height, greaterThanOrEqualTo(44));
  });

  testWidgets('a dismissible pop-up offers "Huwag nang ipakita", which puts it away on the server', (tester) async {
    _serve(popup: _popup(dismissible: true));
    await _launchSignedIn(tester);

    final dontShow = find.text('Huwag nang ipakita');
    expect(dontShow, findsOneWidget);
    expect(tester.getSize(find.widgetWithText(TextButton, 'Huwag nang ipakita')).height, greaterThanOrEqualTo(44));
    expect(find.bySemanticsLabel(RegExp("Don't show again")), findsOneWidget);
    expect(_asked.where((a) => a.endsWith('/dismiss')), isEmpty, reason: 'only when the resident asks');

    await tester.ensureVisible(dontShow);
    await tester.tap(dontShow);
    await tester.pumpAndSettle();
    expect(find.byType(OccasionGreetingPopup), findsNothing);
    expect(_asked.where((a) => a == 'POST /citizen/popups/41/dismiss'), hasLength(1));
    expect(find.byType(HomeWelcomeBanner), findsOneWidget, reason: 'closing is not going on to a page');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a birthday pop-up from the server is drawn in the birthday design, with its own words', (tester) async {
    _serve(
      popup: {
        ..._popup(postId: null, dismissible: true),
        'type': 'birthday',
        'type_label': {'en': 'Birthday', 'fil': 'Kaarawan'},
        'birthday': true,
        'title': 'Happy birthday, Halimbawa!',
        'message': 'Mula sa Bayan ng Esperanza, isang masayang kaarawan.',
      },
    );
    await _launchSignedIn(tester);

    expect(find.byType(BirthdayPopup), findsOneWidget);
    expect(find.byType(OccasionGreetingPopup), findsNothing);
    expect(find.text('MALIGAYANG KAARAWAN'), findsOneWidget);
    expect(find.text('Happy birthday, Halimbawa!'), findsOneWidget);
    expect(find.text('Mula sa Bayan ng Esperanza, isang masayang kaarawan.'), findsOneWidget);
    expect(find.text('Salamat!'), findsOneWidget);
    expect(_asked.where((a) => a == 'POST /citizen/popups/41/seen'), hasLength(1));

    await tester.tap(find.text('Huwag nang ipakita'));
    await tester.pumpAndSettle();
    expect(find.byType(BirthdayPopup), findsNothing);
    expect(_asked.where((a) => a == 'POST /citizen/popups/41/dismiss'), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('with none due, nothing pops up and nothing is recorded', (tester) async {
    _serve(popup: null);
    await _launchSignedIn(tester);
    expect(find.byType(OccasionGreetingPopup), findsNothing);
    expect(find.byType(BirthdayPopup), findsNothing);
    expect(_asked, contains('GET /citizen/popups/active'));
    expect(_asked.where((a) => a.contains('/seen')), isEmpty);
    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
  });
}
