// Occasion greetings (2026-10-19): an LGU greeting for a festival, a holiday,
// the foundation day - written, scheduled and approved in Balita - pops up
// when a resident opens the app, as the server decides, and its post carries
// "Pagbati" in the feed. Synthetic identities only.
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

Map<String, dynamic> _greeting({int? postId = 41, Map<String, dynamic>? button}) => {
  'id': 41,
  'title': 'Maligayang Pasko, Esperanza!',
  'message': 'Isang mapayapa at masayang Pasko sa inyong lahat.',
  'occasion': 'holiday',
  'occasion_label': {'en': 'Holiday', 'fil': 'Pista opisyal'},
  'occasion_name': null,
  'poster_url': null,
  'frequency': 'daily',
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
  'post_type': 'greeting',
  'greeting': {
    'occasion': 'holiday',
    'occasion_label': {'en': 'Holiday', 'fil': 'Pista opisyal'},
    'occasion_name': null,
  },
};

/// What the app asked the server, as "METHOD path".
final _asked = <String>[];

void _serve({Map<String, dynamic>? greeting}) {
  _asked.clear();
  FakeApi.installFull((r) {
    _asked.add('${r.method} ${r.path}');
    if (r.path == '/citizen/greetings/active') return greeting;
    if (r.path == '/citizen/greetings/41/seen') return {'id': 41, 'recorded': true, 'times_seen': 1};
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
    test('a greeting pop-up, with only a web link ever opened', () {
      final g = OccasionGreeting.fromApi(
        _greeting(button: {'label': 'Basahin', 'url': 'https://esperanza.gov.ph/pasko'}),
      );
      expect(g.id, 41);
      expect(g.postId, 41);
      expect(g.buttonLabel, 'Basahin');
      expect(g.buttonUrl, 'https://esperanza.gov.ph/pasko');
      expect(g.occasion!.label(filipino: true), 'Pista opisyal');
      expect(g.occasion!.label(filipino: false), 'Holiday');

      final unsafe = OccasionGreeting.fromApi(_greeting(button: {'label': 'Open', 'url': 'javascript:alert(1)'}));
      expect(unsafe.buttonUrl, isNull);
      expect(() => OccasionGreeting.fromApi({'id': 1}), throwsFormatException, reason: 'no title');
    });

    test('a custom occasion is called by its own name', () {
      final o = GreetingOccasion.fromApi({
        'occasion': 'custom',
        'occasion_label': {'en': 'Custom Occasion', 'fil': 'Ibang okasyon'},
        'occasion_name': 'Pista ng Barangay Baras',
      });
      expect(o!.label(filipino: true), 'Pista ng Barangay Baras');
    });

    test('a greeting post in the feed knows its occasion; a regular post has none', () {
      expect(Announcement.fromAnnouncementApi(_post()).greeting!.key, 'holiday');
      expect(Announcement.fromAnnouncementApi({..._post(), 'post_type': 'regular', 'greeting': null}).greeting, isNull);
      expect(Announcement.fromAnnouncementApi({'id': 7, 'title': 'Older server'}).greeting, isNull);
    });
  });

  testWidgets('a due greeting pops up on opening, counts as seen once, and comes before the welcome poster', (
    tester,
  ) async {
    _serve(greeting: _greeting());
    await _launchSignedIn(tester);

    expect(find.byType(OccasionGreetingPopup), findsOneWidget);
    expect(find.text('Maligayang Pasko, Esperanza!'), findsOneWidget);
    expect(find.text('GREETING · HOLIDAY'), findsOneWidget);
    expect(find.byType(HomeWelcomeBanner), findsNothing, reason: 'the poster waits');
    expect(_asked.where((a) => a == 'POST /citizen/greetings/41/seen'), hasLength(1));

    await tester.tap(find.text('Salamat!'));
    await tester.pumpAndSettle();
    expect(find.byType(OccasionGreetingPopup), findsNothing);
    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Tingnan sa Balita" opens its post, marked as a greeting', (tester) async {
    _serve(greeting: _greeting());
    await _launchSignedIn(tester);

    await tester.tap(find.text('Tingnan sa Balita'));
    await tester.pumpAndSettle();
    expect(find.byType(OccasionGreetingPopup), findsNothing);
    expect(find.byType(BalitaPostScreen), findsOneWidget);
    expect(find.descendant(of: find.byType(PostCard), matching: find.text('Greeting')), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Greeting: Holiday'),
      findsOneWidget,
      reason: 'a screen reader hears the occasion',
    );
  });

  testWidgets('a pop-up-only greeting offers no post, only thanks', (tester) async {
    _serve(greeting: _greeting(postId: null));
    await _launchSignedIn(tester);
    expect(find.text('Tingnan sa Balita'), findsNothing);
    expect(find.text('Salamat!'), findsOneWidget);
    // Every button is a full-size target.
    expect(tester.getSize(find.byTooltip('Close')).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(find.widgetWithText(TextButton, 'Salamat!')).height, greaterThanOrEqualTo(44));
  });

  testWidgets('with none due, nothing pops up and nothing is recorded', (tester) async {
    _serve(greeting: null);
    await _launchSignedIn(tester);
    expect(find.byType(OccasionGreetingPopup), findsNothing);
    expect(_asked, contains('GET /citizen/greetings/active'));
    expect(_asked.where((a) => a.contains('/seen')), isEmpty);
    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
  });
}
