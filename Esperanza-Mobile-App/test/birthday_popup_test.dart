// The birthday pop-up over Home (the owner's design, canvas "Balita Birthday
// Theme", artboard "Birthday pop-up (login / after splash)"). Since
// 2026-10-21 the server sends it - on the resident's birthday, once a year,
// as a pop-up marked `birthday` - and the app draws it in this design with
// the server's words. The phone no longer triggers one itself from the
// birthdate (owner decision). Synthetic identities only.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/widgets/birthday_popup.dart';
import 'package:esperanza_mobile/widgets/home_welcome_banner.dart';

import 'support/fake_api.dart';
import 'support/start_app.dart';

const _birthday = '1995-10-16';

Map<String, dynamic> _profile({String birthdate = _birthday}) => {
  'account_no': 'ESP-RES-2026-000777',
  'first_name': 'Testa',
  'last_name': 'Sintetiko',
  'email': 'testa@esperanza-test.invalid',
  'mobile': '09170000000',
  'barangay': 'Poblacion',
  'birthdate': birthdate,
  'sex': 'Female',
  'status': 'Approved',
  'identity_status': 'Verified',
  'access_level': 'Verified',
  'profile_completeness': 100,
};

CitizenAccount _account({String birthdate = _birthday}) => CitizenAccount(
  id: 'ESP-RES-2026-000777',
  firstName: 'Testa',
  lastName: 'Sintetiko',
  email: 'testa@esperanza-test.invalid',
  mobile: '09170000000',
  barangay: 'Poblacion',
  purok: '',
  address: '',
  birthdate: birthdate,
  sex: 'Female',
  civilStatus: '',
  occupation: '',
  profileCompleteness: 100,
  status: 'Approved',
  identityStatus: 'Verified',
  serverAccessLevel: 'Verified',
);

Map<String, dynamic> _birthdayPopup({String? imageUrl}) => {
  'id': 90,
  'occurrence': '2026-10-16',
  'type': 'birthday',
  'type_label': {'en': 'Birthday', 'fil': 'Kaarawan'},
  'birthday': true,
  'title': 'Happy birthday, Testa!',
  'message': 'Mula sa Bayan ng Esperanza: malusog at masayang taon sa iyo.',
  'image_url': imageUrl,
  'image_alt': 'Cake ng Bayan',
  'frequency': 'once',
  'dismissal': 'seen',
  'dismissible': false,
  'post_id': null,
  'button': {'label': null, 'url': null},
};

/// What the app sent the server besides reads, as "METHOD path".
final _sent = <String>[];

/// The server: [popup] is what GET /citizen/popups/active answers.
void _serve({String birthdate = _birthday, Map<String, dynamic>? popup}) {
  _sent.clear();
  FakeApi.installFull((r) {
    if (r.method != 'GET') _sent.add('${r.method} ${r.path}');
    if (r.path == '/auth/citizen/login') return {'token': 'synthetic-token'};
    if (r.path == '/citizen/profile') return _profile(birthdate: birthdate);
    if (r.path == '/citizen/popups/active') return popup;
    if (r.path == '/citizen/popups/90/seen') return {'id': 90, 'recorded': true};
    return <dynamic>[];
  });
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Opens the app with [account] already signed in on this phone.
Future<void> _launchSignedIn(WidgetTester tester, {CitizenAccount? account}) async {
  SharedPreferences.setMockInitialValues({
    'esperanza_citizen_session': jsonEncode((account ?? _account()).toJson()),
    'esperanza_api_token': 'synthetic-token',
  });
  await tester.pumpWidget(const EsperanzaMobileApp());
  await tester.pumpAndSettle();
}

void main() {
  tearDown(FakeApi.restore);

  testWidgets(
    'already signed in: the server\'s birthday pop-up greets them in the birthday design, before the poster',
    (tester) async {
      _phone(tester);
      _serve(popup: _birthdayPopup());
      await _launchSignedIn(tester);

      expect(find.byType(BirthdayPopup), findsOneWidget);
      expect(find.text('MALIGAYANG KAARAWAN'), findsOneWidget);
      expect(find.text('Happy birthday, Testa!'), findsOneWidget);
      expect(find.text('Mula sa Bayan ng Esperanza: malusog at masayang taon sa iyo.'), findsOneWidget);
      expect(find.text('Salamat!'), findsOneWidget);
      expect(find.text('Huwag nang ipakita'), findsNothing, reason: 'not dismissible');
      expect(find.byType(HomeWelcomeBanner), findsNothing, reason: 'the poster waits for the greeting');
      expect(_sent, contains('POST /citizen/popups/90/seen'));

      await tester.tap(find.text('Salamat!'));
      await tester.pumpAndSettle();
      expect(find.byType(BirthdayPopup), findsNothing);
      expect(find.byType(HomeWelcomeBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('signing in on the birthday: the server\'s pop-up greets them on arriving Home', (tester) async {
    _phone(tester);
    _serve(popup: _birthdayPopup());
    SharedPreferences.setMockInitialValues({});
    await pumpAppToSignIn(tester);
    await tester.enterText(find.byType(TextField).at(0), 'testa@esperanza-test.invalid');
    await tester.enterText(find.byType(TextField).at(1), 'Synthetic-Pass-1!');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(BirthdayPopup), findsOneWidget);
    expect(find.text('Happy birthday, Testa!'), findsOneWidget);
  });

  testWidgets('on the birthday, with no pop-up from the server, the phone shows none of its own', (tester) async {
    _phone(tester);
    _serve(popup: null);
    await _launchSignedIn(tester);
    expect(find.byType(BirthdayPopup), findsNothing);
    expect(find.textContaining('Happy birthday'), findsNothing);
    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
    expect(_sent.where((s) => s.contains('/popups/')), isEmpty);
  });

  testWidgets('a picture from the server takes the cake\'s place, with its alt text', (tester) async {
    _phone(tester);
    _serve(popup: _birthdayPopup(imageUrl: '/api/v1/media/popup-90?signature=synthetic'));
    await _launchSignedIn(tester);

    final picture = tester.widget<Image>(find.descendant(of: find.byType(BirthdayPopup), matching: find.byType(Image)));
    expect(picture.semanticLabel, 'Cake ng Bayan');
    final url = (picture.image as NetworkImage).url;
    expect(url, startsWith('http'));
    expect(url, endsWith('/api/v1/media/popup-90?signature=synthetic'));
  });

  testWidgets('its buttons are full-size targets, and closing it sends nothing more', (tester) async {
    _phone(tester);
    _serve(popup: _birthdayPopup());
    await _launchSignedIn(tester);

    expect(tester.getSize(find.byTooltip('Close')).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(find.byTooltip('Close')).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(find.ancestor(of: find.text('Salamat!'), matching: find.byType(InkWell))).height, 48);
    // The close button sits on the card, at its top-right corner.
    final card = tester.getRect(
      find.descendant(of: find.byType(BirthdayPopup), matching: find.byType(Container)).first,
    );
    final close = tester.getRect(find.byTooltip('Close'));
    expect(card.contains(close.center), isTrue);
    expect(close.center.dx, greaterThan(card.center.dx));
    expect(close.center.dy, lessThan(card.center.dy));

    final before = _sent.where((s) => !s.contains('/citizen/devices')).toList();
    expect(before, ['POST /citizen/popups/90/seen']);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(_sent.where((s) => !s.contains('/citizen/devices')), before);
  });
}
