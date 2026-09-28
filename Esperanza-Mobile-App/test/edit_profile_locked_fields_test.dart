// Edit Profile's locked fields. A verified account can't change its name or
// barangay here, and both used to be drawn differently: the name as a grey
// read-only box, the barangay as bare text in another label style, so the
// second one read like a heading, not a field.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/profile/edit_profile_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/widgets/app_text_field.dart';

import 'support/fake_api.dart';

CitizenAccount _account(String status) => CitizenAccount(
  id: 'ESP-TEST-0101',
  firstName: 'Testa',
  lastName: 'Sintetiko',
  email: '',
  mobile: '09170000000',
  barangay: 'Poblacion',
  purok: '',
  address: '',
  birthdate: '',
  sex: '',
  civilStatus: '',
  occupation: '',
  profileCompleteness: 50,
  status: status,
);

Future<void> _pump(WidgetTester tester, String status) async {
  SharedPreferences.setMockInitialValues({});
  FakeApi.installFull((_) => <dynamic>[]);
  addTearDown(FakeApi.restore);
  final session = CitizenSessionService();
  addTearDown(session.dispose);
  await tester.runAsync(() => session.login(_account(status)));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(value: session, child: const MaterialApp(home: EditProfileScreen())),
  );
  await tester.pumpAndSettle();
}

/// The grey box a locked value sits in.
Finder _boxOf(String value) => find.ancestor(of: find.text(value), matching: find.byType(Container)).first;

void main() {
  testWidgets('a verified account sees name and barangay as the same kind of locked field', (tester) async {
    await _pump(tester, 'Approved');
    expect(find.byType(AppSelectField<String>), findsNothing);

    final name = tester.getSize(_boxOf('Testa Sintetiko'));
    final barangay = tester.getSize(_boxOf('Poblacion'));
    expect(barangay.width, name.width);
    expect(barangay.height, name.height);
    expect(barangay.height, greaterThanOrEqualTo(44));

    final nameLabel = tester.widget<Text>(find.text('Full name')).style;
    final barangayLabel = tester.widget<Text>(find.text('Barangay')).style;
    expect(barangayLabel, nameLabel);
    expect(find.text('Verified accounts update their barangay through the barangay office.'), findsOneWidget);
  });

  testWidgets('an unverified account can still pick its barangay', (tester) async {
    await _pump(tester, 'Pending Review');
    expect(find.byType(AppSelectField<String>), findsOneWidget);
    expect(find.text('Verified accounts update their barangay through the barangay office.'), findsNothing);
  });
}
