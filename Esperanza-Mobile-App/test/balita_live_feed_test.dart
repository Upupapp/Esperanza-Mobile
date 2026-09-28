// A post the citizen just created must appear in the Balita feed without a
// reload. The feed used to render the loader's one-time snapshot, which
// never contained a post created afterwards, so it only showed up after the
// next sign-in.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/balita/balita_screen.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';

import 'support/fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  testWidgets('a newly created post shows in the feed immediately', (tester) async {
    FakeApi.installFull((r) {
      if (r.method == 'POST' && r.path == '/citizen/community-posts') {
        return {'id': 77, 'body': 'Brand-new synthetic post', 'mine': true, 'status': 'Pending Review', 'visible': false};
      }
      if (r.path == '/announcements') {
        return [
          {'id': 1, 'body': 'Existing announcement', 'published_at': '2026-09-01T00:00:00Z'},
        ];
      }
      return <dynamic>[];
    });

    final balita = BalitaService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(create: (_) => RequestsService()),
          ChangeNotifierProvider.value(value: balita),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: const MaterialApp(home: BalitaScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Existing announcement'), findsOneWidget);
    expect(find.textContaining('Brand-new synthetic post'), findsNothing);

    await tester.runAsync(() => balita.createPost(body: 'Brand-new synthetic post', category: 'General'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Brand-new synthetic post'), findsOneWidget);
  });

  testWidgets("a community post's menu opens without ListTile's hidden-ink assertion", (tester) async {
    // The sheet used to wrap its ListTile in a white DecoratedBox, which
    // hid the tap ripple and threw a debug assertion on open.
    FakeApi.installFull((r) {
      if (r.path == '/citizen/community-posts') {
        return [
          {'id': 7, 'author': 'Testa Sintetiko', 'body': 'Clean-up salamat!', 'visible': true, 'mine': false},
        ];
      }
      return <dynamic>[];
    });
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
    await tester.element(find.byType(BalitaScreen)).read<CitizenSessionService>().login(MockCatalog.demoAccounts.last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Report post'), findsOneWidget);
  });
}
