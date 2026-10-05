// An account the LGU approves while the app is already open reaches the
// resident without a restart.
//
// The session was only re-read at sign-in and at app launch. Found
// 2026-10-05 on a real account: staff verified it from the Web Admin, the
// server answered `valid: true`, and the app still said "Digital ID not yet
// available ... Pending Review" until it was force-stopped and reopened.
// Dokyu and Tulong gate on the same cached status, so they stayed locked too.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/access_level.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/widgets/session_refresh_on_resume.dart';

import 'support/fake_api.dart';

const _accountNo = 'ESP-RES-2026-0901';

CitizenAccount _cached(String status) => CitizenAccount(
  id: _accountNo,
  firstName: 'Test',
  lastName: 'Resident',
  email: 'test.resident@example.test',
  mobile: '',
  barangay: 'Magsaysay',
  purok: 'Purok 2',
  address: '',
  birthdate: '',
  sex: '',
  civilStatus: '',
  occupation: '',
  profileCompleteness: 50,
  status: status,
);

Map<String, dynamic> _profile(String status) => {
  'account_no': _accountNo,
  'first_name': 'Test',
  'last_name': 'Resident',
  'email': 'test.resident@example.test',
  'barangay': 'Magsaysay',
  'purok': 'Purok 2',
  'status': status,
  'profile_completeness': 50,
};

Map<String, dynamic> _card() => {
  'account_no': _accountNo,
  'name': 'Test Resident',
  'barangay': 'Magsaysay',
  'purok': 'Purok 2',
  'status': 'Approved',
  'access_level': 'Verified',
  'valid': true,
  'issued_at': '2026-10-05',
  'qr': 'ESPID|$_accountNo|0000000000',
  'photo_url': null,
};

/// A session signed in from the cache as Pending Review, with a token, while
/// the server already says Approved. Records every path the app requests.
Future<(CitizenSessionService, List<String>)> _pendingWhileServerApproved({required Future<void> Function() settle}) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    if (++attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await settle();
  }
  await session.login(_cached('Pending Review'));

  final paths = <String>[];
  FakeApi.installFull((r) {
    paths.add(r.path);
    if (r.path == '/citizen/profile') return _profile('Approved');
    if (r.path == '/citizen/digital-id') return _card();
    throw const FakeApiError();
  });
  await api.setToken('test-token');
  return (session, paths);
}

void main() {
  tearDown(FakeApi.restore);

  test('revalidate() picks up an approval made since sign-in', () async {
    final (session, _) = await _pendingWhileServerApproved(settle: () => Future<void>.delayed(Duration.zero));
    addTearDown(session.dispose);
    expect(session.accessLevel, AccessLevel.unverified);

    await session.revalidate();

    expect(session.accessLevel, AccessLevel.verified);
  });

  test('overlapping revalidate() calls share one request', () async {
    final (session, paths) = await _pendingWhileServerApproved(settle: () => Future<void>.delayed(Duration.zero));
    addTearDown(session.dispose);

    // A resume and the Digital ID screen opening at the same moment.
    await Future.wait([session.revalidate(), session.revalidate(), session.revalidate()]);

    expect(paths.where((p) => p == '/citizen/profile'), hasLength(1));
  });

  test('a guest has nothing to re-read and sends nothing', () async {
    SharedPreferences.setMockInitialValues({});
    final session = CitizenSessionService();
    addTearDown(session.dispose);
    while (session.loading) {
      await Future<void>.delayed(Duration.zero);
    }
    await session.continueAsGuest();
    final paths = <String>[];
    FakeApi.installFull((r) {
      paths.add(r.path);
      return <String, dynamic>{};
    });
    await api.setToken('test-token');

    await session.revalidate();

    expect(paths, isEmpty);
  });

  testWidgets('returning to the foreground re-reads the account', (tester) async {
    final (session, _) = await _pendingWhileServerApproved(settle: () => tester.pump(const Duration(milliseconds: 1)));
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<CitizenSessionService>.value(
        value: session,
        child: const SessionRefreshOnResume(child: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    // Nothing has re-read it yet: still the cached status.
    expect(session.accessLevel, AccessLevel.unverified);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(session.accessLevel, AccessLevel.verified);
  });

  testWidgets('opening Digital ID shows the card an approval made since sign-in', (tester) async {
    final (session, _) = await _pendingWhileServerApproved(settle: () => tester.pump(const Duration(milliseconds: 1)));
    addTearDown(session.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<CitizenSessionService>.value(
        value: session,
        child: const MaterialApp(home: DigitalIdScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Digital ID not yet available'), findsNothing);
    expect(find.text('Valid · Verified by LGU'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
