// Verifies the extended Notifications feed: the profile-completion
// reminder shows only while incomplete and disappears once complete,
// sample notifications render with their type badges, and Guests (no
// account) never see the profile reminder.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/notifications/notifications_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/resident_profile_overview_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';

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

Future<void> _pump(WidgetTester tester, {CitizenAccount? account, ResidentProfileService? residentProfileService}) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  if (account != null) await session.login(account);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider<ResidentProfileService>.value(value: residentProfileService ?? ResidentProfileService()),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed-in resident with an incomplete profile sees the "Complete Your Profile" reminder', (tester) async {
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

  testWidgets('Guest (no account) never sees the profile-completion reminder, but still sees sample notifications', (tester) async {
    await _pump(tester);

    expect(find.text('Complete Your Profile'), findsNothing);
    expect(find.text('Typhoon Advisory — Esperanza, Masbate'), findsOneWidget);
    expect(find.text('Urgent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sample notifications are not tappable (no production side effects)', (tester) async {
    await _pump(tester);

    // No exception/navigation should occur from tapping a sample tile —
    // AppCard renders it without an InkWell when onTap is null, so this
    // just confirms no crash and no unexpected route push.
    await tester.tap(find.text('Typhoon Advisory — Esperanza, Masbate'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
