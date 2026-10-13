// The Profile re-reads the account from the server when it opens, and on
// pull-down. It used to be read only at sign-in, so a residency the LGU
// approved while the app was open still read "reviewing" (owner's
// screenshot, 2026-10-13).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/profile/profile_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';

import 'support/fake_api.dart';

final _pending = CitizenAccount(
  id: 'ESP-TEST-0200',
  firstName: 'Testa',
  lastName: 'Sintetiko',
  email: 'testa@esperanza-test.invalid',
  mobile: '09170000000',
  barangay: 'Poblacion',
  purok: '',
  address: '',
  birthdate: '',
  sex: '',
  civilStatus: '',
  occupation: '',
  profileCompleteness: 50,
  status: 'Pending Review',
);

void main() {
  testWidgets('opening the Profile shows a residency the LGU approved since sign-in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var status = 'Pending Review';
    final calls = <String>[];
    FakeApi.installFull((r) {
      calls.add('${r.method} ${r.path}');
      if (r.path == '/citizen/profile') {
        return {
          'account_no': 'ESP-TEST-0200',
          'first_name': 'Testa',
          'last_name': 'Sintetiko',
          'barangay': 'Poblacion',
          'status': status,
          'identity_status': 'Verified',
          'profile_completeness': 50,
        };
      }
      return <dynamic>[];
    });
    addTearDown(FakeApi.restore);
    final session = CitizenSessionService();
    await tester.runAsync(() async {
      await pumpEventQueue();
      await session.login(_pending);
    });
    expect(session.account!.status, 'Pending Review');

    // The LGU approves the residency while the app is open.
    status = 'Approved';
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider<ResidentProfileService>(create: (_) => ResidentProfileService()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(calls, contains('GET /citizen/profile'));
    expect(session.account!.status, 'Approved');
  });
}
