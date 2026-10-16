// On the citizen's birthday a pop-up greets them over Home (the owner's
// design, canvas "Balita Birthday Theme", artboard "Birthday pop-up (login /
// after splash)"): right after signing in, or - already signed in - right
// after the opening animation. Once per birthday, before the welcome poster,
// and only for that citizen. Synthetic identities only.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/utils/birthday.dart';
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

void _serve({String birthdate = _birthday}) {
  FakeApi.installFull((r) {
    if (r.path == '/auth/citizen/login') return {'token': 'synthetic-token'};
    if (r.path == '/citizen/profile') return _profile(birthdate: birthdate);
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
Future<void> _launchSignedIn(
  WidgetTester tester, {
  CitizenAccount? account,
  Map<String, Object> more = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'esperanza_citizen_session': jsonEncode((account ?? _account()).toJson()),
    'esperanza_api_token': 'synthetic-token',
    ...more,
  });
  await tester.pumpWidget(const EsperanzaMobileApp());
  await tester.pumpAndSettle();
}

void main() {
  final realToday = Birthday.today;
  setUp(() => Birthday.today = () => DateTime(2026, 10, 16, 8));
  tearDown(() {
    Birthday.today = realToday;
    FakeApi.restore();
  });

  testWidgets('already signed in: it greets them after the opening animation, before the welcome poster', (
    tester,
  ) async {
    _phone(tester);
    _serve();
    await _launchSignedIn(tester);

    expect(find.byType(BirthdayPopup), findsOneWidget);
    expect(find.text('MALIGAYANG KAARAWAN'), findsOneWidget);
    expect(find.text('Happy birthday, Testa!'), findsOneWidget);
    expect(find.text('Salamat!'), findsOneWidget);
    expect(find.byType(HomeWelcomeBanner), findsNothing, reason: 'the poster waits for the greeting');

    await tester.tap(find.text('Salamat!'));
    await tester.pumpAndSettle();
    expect(find.byType(BirthdayPopup), findsNothing);
    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signing in on the birthday: it greets them on arriving Home', (tester) async {
    _phone(tester);
    _serve();
    SharedPreferences.setMockInitialValues({});
    await pumpAppToSignIn(tester);
    await tester.enterText(find.byType(TextField).at(0), 'testa@esperanza-test.invalid');
    await tester.enterText(find.byType(TextField).at(1), 'Synthetic-Pass-1!');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Happy birthday, Testa!'), findsOneWidget);
  });

  testWidgets('once per birthday: opening the app again the same day does not repeat it', (tester) async {
    _phone(tester);
    _serve();
    await _launchSignedIn(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(BirthdayPopup), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    final kept = {for (final k in prefs.getKeys()) k: prefs.get(k)!};
    await tester.pumpWidget(const SizedBox());
    await _launchSignedIn(tester, more: kept);
    expect(find.byType(BirthdayPopup), findsNothing);

    // Next year, again.
    Birthday.today = () => DateTime(2027, 10, 16, 8);
    await tester.pumpWidget(const SizedBox());
    await _launchSignedIn(tester, more: kept);
    expect(find.byType(BirthdayPopup), findsOneWidget);
  });

  testWidgets('any other day, or someone else on this phone, gets no pop-up', (tester) async {
    _phone(tester);
    _serve(birthdate: '1988-03-02');
    await _launchSignedIn(tester, account: _account(birthdate: '1988-03-02'));
    expect(find.byType(BirthdayPopup), findsNothing);
    expect(find.textContaining('Happy birthday'), findsNothing);
    expect(find.byType(HomeWelcomeBanner), findsOneWidget);
  });

  testWidgets('its buttons are full-size targets, and closing it sends nothing', (tester) async {
    _phone(tester);
    final sent = <String>[];
    FakeApi.installFull((r) {
      if (r.method != 'GET') sent.add('${r.method} ${r.path}');
      if (r.path == '/citizen/profile') return _profile();
      return <dynamic>[];
    });
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

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(sent.where((s) => !s.contains('/citizen/devices')), isEmpty);
  });
}
