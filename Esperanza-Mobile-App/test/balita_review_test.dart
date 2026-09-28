// Balita's side-by-side review: what the feed card, comments sheet,
// composer and report dialog showed or allowed that the backend does not.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/screens/balita/comments_sheet.dart';
import 'package:esperanza_mobile/screens/balita/compose_post_screen.dart';
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

Announcement _community({bool mine = false, String status = 'Approved', bool visible = true}) =>
    Announcement.fromCommunityApi({
      'id': 31,
      'author': 'Testa Sintetiko',
      'body': 'Salamat sa lahat!',
      'created_at': '2026-09-28T03:00:00Z',
      'status': status,
      'visible': visible,
      'mine': mine,
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

  testWidgets('your own post awaiting approval offers no like, comment or share (the backend refuses them)', (
    tester,
  ) async {
    await _pump(tester, PostCard(post: _community(mine: true, status: 'Pending Review', visible: false)));
    expect(find.textContaining('Pending review'), findsOneWidget);
    expect(find.text('Like'), findsNothing);
    expect(find.text('Comment'), findsNothing);
    expect(find.text('Share'), findsNothing);
  });

  testWidgets('an approved post keeps its actions', (tester) async {
    await _pump(tester, PostCard(post: _community()));
    expect(find.text('Like'), findsOneWidget);
    expect(find.text('Comment'), findsOneWidget);
  });

  testWidgets('the composer holds a post to the backend limit', (tester) async {
    await _pump(tester, const SizedBox(height: 900, child: ComposePostScreen()));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLength, BalitaService.postMaxLength);
    expect(BalitaService.postMaxLength, 2000);
  });

  testWidgets('a report cannot be sent empty and is held to 255 characters', (tester) async {
    FakeApi.installFull((r) => <dynamic>[]);
    await _pump(tester, PostCard(post: _community()), signedIn: true);
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report post'));
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(TextButton, 'Submit');
    expect(tester.widget<TextButton>(submit).onPressed, isNull);
    final field = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    expect(tester.widget<TextField>(field).maxLength, BalitaService.reportReasonMaxLength);
    await tester.enterText(field, 'Spam');
    await tester.pump();
    expect(tester.widget<TextButton>(submit).onPressed, isNotNull);
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
