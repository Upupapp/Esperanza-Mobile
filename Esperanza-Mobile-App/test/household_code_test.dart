// The household's code in the barangay's resident registry (e.g. HH-2026-0004)
// shown to the resident on the Resident Profile (owner, 2026-10-27), as on the
// website. The server assigns it (GET /citizen/resident-profile household.ref);
// the app never types or invents one.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/resident_profile.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/widgets/household_code_card.dart';

import 'support/fake_api.dart';

CitizenAccount _account() => CitizenAccount(
  id: 'ESP-RES-TEST-0042',
  firstName: 'Test',
  lastName: 'Resident',
  email: 'test@example.com',
  mobile: '09171234567',
  barangay: 'Agoho',
  purok: 'Purok 1',
  address: 'Purok 1, Barangay Agoho, Esperanza, Masbate',
  birthdate: '—',
  sex: '—',
  civilStatus: '—',
  occupation: '—',
  profileCompleteness: 40,
  status: 'Approved',
);

Map<String, dynamic> _view({String? code}) => {
  'individual': {'ref': 'RES-2026-0901', 'verification': 'Verified', 'sex': 'Female'},
  'household': code == null ? null : {'ref': code, 'sitio': 'Purok 2'},
  'family': null,
  'submitted_at': '2026-10-06T01:00:00Z',
  'review': {'outcome': 'verified', 'note': null, 'at': '2026-10-06T02:00:00Z'},
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  test('the code is taken from the server on every sync, and kept on the phone', () async {
    final account = _account();
    final service = ResidentProfileService();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    var code = 'HH-2026-0004';
    FakeApi.installFull((_) => _view(code: code));
    await service.sync(account);
    expect(service.profileFor(account).household.registryCode, 'HH-2026-0004');

    // The barangay merged households: the server's code wins, every time.
    code = 'HH-2026-0007';
    await service.sync(account);
    expect(service.profileFor(account).household.registryCode, 'HH-2026-0007');

    // Saved with the profile, so it shows offline after a restart.
    final again = ResidentProfileService();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(again.profileFor(account).household.registryCode, 'HH-2026-0007');
  });

  test('no household on the server, no code', () async {
    final account = _account();
    final service = ResidentProfileService();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    FakeApi.installFull((_) => _view());
    await service.sync(account);
    expect(service.profileFor(account).household.registryCode, isNull);
  });

  test('the code survives the household JSON round trip; an older copy has none', () {
    final h = Household(householdId: 'local-1', registryCode: 'HH-2026-0004');
    expect(Household.fromJson(h.toJson()).registryCode, 'HH-2026-0004');
    final older = h.toJson()..remove('registryCode');
    expect(Household.fromJson(older).registryCode, isNull);
  });

  testWidgets('the card shows the code, and says the barangay confirms it until verified', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HouseholdCodeCard(code: 'HH-2026-0004', verified: false))));
    expect(find.text('HH-2026-0004'), findsOneWidget);
    expect(find.text('Household code'), findsOneWidget);
    expect(find.text('Your barangay office confirms it when it verifies your profile.'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HouseholdCodeCard(code: 'HH-2026-0004', verified: true))));
    expect(find.text('Your barangay office confirms it when it verifies your profile.'), findsNothing);
  });
}
