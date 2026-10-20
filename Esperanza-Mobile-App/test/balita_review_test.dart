// Balita's side-by-side review: what the feed card and comments sheet
// showed or allowed that the backend does not. (The composer and the report
// dialog it also covered are gone: only the LGU posts, owner 2026-10-20.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/screens/balita/comments_sheet.dart';
import 'package:esperanza_mobile/screens/balita/post_card.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/theme/app_typography.dart';
import 'package:esperanza_mobile/utils/date_text.dart';

import 'support/fake_api.dart';

Announcement _announcement() => Announcement.fromAnnouncementApi({
  'id': 7,
  'title': 'Libreng Bakuna sa Poblacion',
  'body': 'Free vaccination this Saturday.',
  'published_at': '2026-09-27T23:00:00Z',
  'likes': 3,
});

Future<CitizenSessionService> _pump(WidgetTester tester, Widget child, {bool signedIn = false}) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  addTearDown(session.dispose);
  if (signedIn) await tester.runAsync(() => session.login(MockCatalog.demoAccounts.last));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(create: (_) => BalitaService()),
      ],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

void main() {
  tearDown(FakeApi.restore);

  testWidgets('an announcement headline is drawn as a headline, not as body text', (tester) async {
    await _pump(tester, PostCard(post: _announcement()));
    final headline = tester.widget<Text>(find.text('Libreng Bakuna sa Poblacion'));
    expect(headline.style, AppTypography.cardHeading);
    expect(find.text('Free vaccination this Saturday.'), findsOneWidget);
  });

  testWidgets('an LGU post keeps like, comment and share, and has no post menu', (tester) async {
    FakeApi.installFull((r) => <dynamic>[]);
    await _pump(tester, PostCard(post: _announcement()), signedIn: true);
    expect(find.text('Like'), findsOneWidget);
    expect(find.text('Comment'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Esperanza LGU'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    // Nothing to report or delete: every post is the LGU's own.
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    expect(find.textContaining('Pending review'), findsNothing);
  });

  testWidgets('comments say when they were posted and are held to 1,000 characters', (tester) async {
    const at = '2026-09-20T02:00:00Z';
    FakeApi.installFull(
      (r) => [
        {'id': 1, 'author': 'Ana Santos', 'body': 'Salamat po!', 'created_at': at},
      ],
    );
    await _pump(tester, SizedBox(height: 700, child: CommentsSheet(post: _announcement())));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.textContaining(timeAgo(DateTime.parse(at).toLocal())), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).maxLength, BalitaService.commentMaxLength);
  });
}
