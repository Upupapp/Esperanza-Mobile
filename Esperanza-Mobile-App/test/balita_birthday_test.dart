// The birthday is greeted by the server's pop-up, as on the website
// (2026-10-22, app/web parity): Balita no longer opens with a greeting card
// the phone drew from the birthdate, which the website never had, and the
// phone no longer works the birthday out at all. Synthetic identities only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/balita/balita_screen.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';

import 'support/fake_api.dart';

CitizenAccount _citizen(String birthdate, {String id = 'ESP-RES-2026-000777', String firstName = 'Testa'}) =>
    CitizenAccount(
      id: id,
      firstName: firstName,
      lastName: 'Sintetiko',
      email: 'testa@esperanza-test.invalid',
      mobile: '09170000000',
      barangay: 'Poblacion',
      purok: '—',
      address: '—',
      birthdate: birthdate,
      sex: 'Female',
      civilStatus: 'Single',
      occupation: '—',
      profileCompleteness: 100,
      status: 'Approved',
    );

Future<void> _pumpBalita(WidgetTester tester, CitizenAccount account) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: const MaterialApp(home: BalitaScreen()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.element(find.byType(BalitaScreen)).read<CitizenSessionService>().login(account);
  await tester.pumpAndSettle();
}

void main() {
  final sent = <String>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sent.clear();
    FakeApi.installFull((r) {
      if (r.method != 'GET') sent.add('${r.method} ${r.path}');
      if (r.path == '/announcements') {
        return [
          {
            'id': 1,
            'title': 'Synthetic advisory',
            'body': 'Synthetic advisory body',
            'published_at': '2026-10-07T00:00:00Z',
          },
        ];
      }
      return <dynamic>[];
    });
  });
  tearDown(FakeApi.restore);

  testWidgets('on the birthday Balita shows the posts and no greeting of its own', (tester) async {
    final now = DateTime.now();
    final birthdate = '1995-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _pumpBalita(tester, _citizen(birthdate));
    expect(find.textContaining('Happy birthday'), findsNothing);
    expect(find.byTooltip('Dismiss birthday greeting'), findsNothing);
    expect(find.textContaining('Synthetic advisory'), findsWidgets);
    expect(sent, isEmpty);
  });
}
