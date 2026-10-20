// Only the LGU posts to Balita (owner, 2026-10-20): a resident reads, likes,
// comments and shares, and nothing on the Balita tab lets them write a post,
// report one or delete one. The feed is GET /announcements alone; the
// residents' community-post routes are gone from the server.
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

  testWidgets('a signed-in resident sees the LGU posts and no way to write, report or delete one', (tester) async {
    final paths = <String>[];
    FakeApi.installFull((r) {
      paths.add('${r.method} ${r.path}');
      if (r.path == '/announcements') {
        return [
          {'id': 1, 'body': 'Existing announcement', 'published_at': '2026-09-01T00:00:00Z'},
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

    expect(find.textContaining('Existing announcement'), findsOneWidget);
    expect(find.text('Like'), findsOneWidget);
    expect(find.text('Comment'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    // No composer entry point of any kind, and no post menu.
    expect(find.byTooltip('New Post'), findsNothing);
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    expect(find.text('Report post'), findsNothing);
    expect(find.text('Delete post'), findsNothing);
    expect(paths.where((p) => p.contains('community-posts')), isEmpty);
  });
}
