// QA sweep 2026-11-18, fixer app-4: a Balita video that fails partway
// through can be tried again; a sign-up whose sign-in fails never sends the
// form twice; a deep-linked older post's photos still open; Home's Active
// Requests leave Sakuna reports out; the Events tab reads what is coming up
// on its own; a TLS failure is an ApiException; a saved Papeles upload stays
// saved when the re-read fails; a notice left after sign-out opens nothing;
// the confirm sheet measures its labels as it draws them; a Balita link with
// no post opens nothing and throws nothing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'package:esperanza_mobile/screens/auth/register_screen.dart';
import 'package:esperanza_mobile/screens/balita/post_image_viewer.dart';
import 'package:esperanza_mobile/screens/directory/barangay_profile_screen.dart';
import 'package:esperanza_mobile/screens/events/events_screen.dart';
import 'package:esperanza_mobile/screens/home/home_screen.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/barangay_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/deep_links.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/push_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/widgets/app_dialogs.dart';
import 'package:esperanza_mobile/widgets/app_text_field.dart';
import 'package:esperanza_mobile/widgets/balita_video_player.dart';

import 'support/fake_api.dart';

/// A player with no platform behind it: it starts, plays and pauses on its
/// own value, or fails to start when [fails].
class _FakeVideo extends VideoPlayerController {
  _FakeVideo({this.fails = false}) : super.networkUrl(Uri.parse('https://test.invalid/clip.mp4'));

  final bool fails;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    if (fails) throw Exception('no stream');
    value = value.copyWith(isInitialized: true, duration: const Duration(seconds: 30), size: const Size(640, 360));
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await super.dispose();
  }
}

const _videoFailure = 'This video could not be played. Check your connection and try again.';

Future<List<_FakeVideo>> _pumpVideo(WidgetTester tester, {bool firstFails = false}) async {
  final made = <_FakeVideo>[];
  BalitaVideoPlayer.debugControllerFactory = (_) {
    final v = _FakeVideo(fails: firstFails && made.isEmpty);
    made.add(v);
    return v;
  };
  addTearDown(() => BalitaVideoPlayer.debugControllerFactory = null);
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 360, height: 240, child: BalitaVideoPlayer(url: 'https://test.invalid/clip.mp4')),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return made;
}

String _day(int offset) {
  final d = DateTime.now().add(Duration(days: offset));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Finder _field(String label) =>
    find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(TextField));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  group('149: a Balita video that fails can be tried again', () {
    testWidgets('a stream error partway through shows the failure with Try Again, which starts a new player', (tester) async {
      final made = await _pumpVideo(tester);
      expect(find.byTooltip('Pause'), findsOneWidget, reason: 'playing');

      // A dropped connection: video_player's value turns into an error.
      made.first.value = VideoPlayerValue.erroneous('Connection dropped');
      await tester.pump();
      expect(find.text(_videoFailure), findsOneWidget);
      expect(find.text('0:00 / 0:00'), findsNothing, reason: 'not a dead player with a play button');

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      await tester.pump();
      expect(made, hasLength(2));
      expect(made.first.disposed, isTrue);
      expect(find.text(_videoFailure), findsNothing);
      expect(find.byTooltip('Pause'), findsOneWidget, reason: 'the new player plays');
    });

    testWidgets('a video that never started offers Try Again too', (tester) async {
      final made = await _pumpVideo(tester, firstFails: true);
      expect(find.text(_videoFailure), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      await tester.pump();
      expect(made, hasLength(2));
      expect(find.byTooltip('Pause'), findsOneWidget);
    });
  });

  testWidgets('177: an account created whose sign-in fails moves on to Sign In, never sending the form again', (tester) async {
    var registers = 0;
    var logins = 0;
    FakeApi.installFull((r) {
      if (r.path == '/portal-settings') return {'identity_capture': 'hosted'};
      if (r.path == '/id-types') return <dynamic>[];
      if (r.path == '/auth/citizen/email/send-code') return {'sent': true};
      if (r.path == '/auth/citizen/email/verify-code') return {'verification_token': 'synthetic-email-proof'};
      if (r.path == '/auth/citizen/register') {
        registers++;
        return {
          'account_no': 'ESP-RES-2026-0999',
          'verification': {'required': false},
        };
      }
      if (r.path == '/auth/citizen/login') {
        logins++;
        if (logins == 1) {
          throw const FakeApiError(status: 503, code: 'UNAVAILABLE', messageEn: 'Synthetic outage', messageFil: 'Synthetic outage');
        }
        return {'token': 'synthetic-session-token'};
      }
      if (r.path == '/citizen/profile') {
        return {
          'account_no': 'ESP-RES-2026-0999',
          'first_name': 'Testa',
          'last_name': 'Sintetiko',
          'email': 'testa.sintetiko@example.invalid',
          'barangay': MockCatalog.barangays.first,
          'status': 'Pending Review',
        };
      }
      throw FakeApiError(messageEn: 'sweep_1118_app_4 has no fixture for ${r.method} ${r.path}');
    });
    tester.view.physicalSize = const Size(412, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: RegisterScreen())),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    await tester.enterText(_field('First name'), 'Testa');
    await tester.enterText(_field('Last name'), 'Sintetiko');
    await tester.enterText(_field('Email address'), 'testa.sintetiko@example.invalid');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Verification code'), '123456');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MockCatalog.barangays.first).last);
    await tester.pumpAndSettle();
    await tester.enterText(_field('Password'), 'Synthetic#Pass2026');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsOneWidget, reason: 'on Terms & Conditions');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit for Verification'));
    await tester.pumpAndSettle();
    expect(registers, 1);
    expect(logins, 1);
    expect(find.textContaining('Your account was created, but signing in did not work'), findsOneWidget);
    expect(find.text('Submit for Verification'), findsNothing, reason: 'the form cannot be sent a second time');

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(registers, 1, reason: 'Sign In signs in; it does not register again');
    expect(logins, 2);
    expect(find.textContaining('signing in did not work'), findsNothing);
    expect(find.text('Continue to App'), findsOneWidget);
  });

  group('181: the photos of a post the feed does not hold', () {
    const olderPost = {
      'id': 7,
      'title': null,
      'body': 'Synthetic older post with a photo',
      'category': 'Community',
      'barangay': null,
      'official': true,
      'author': 'Esperanza LGU',
      'published_at': '2026-01-10T00:00:00.000Z',
      'likes': 0,
      'shares': 0,
      'comments_count': 0,
      'image_url': 'https://test.invalid/older.jpg',
    };

    Future<void> openViewer(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CitizenSessionService()),
            ChangeNotifierProvider(create: (_) => BalitaService()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(onPressed: () => PostImageViewer.open(context, 'ann-7'), child: const Text('open')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    testWidgets('are fetched and shown, not closed at once', (tester) async {
      FakeApi.installFull((r) {
        if (r.method == 'GET' && r.path == '/announcements/7') return olderPost;
        throw const FakeApiError();
      });
      await openViewer(tester);
      expect(find.byType(PostImageViewer), findsOneWidget);
      expect(find.text('Synthetic older post with a photo'), findsOneWidget);
    });

    testWidgets('a post the server no longer has still closes the viewer', (tester) async {
      FakeApi.installFull((r) => throw const FakeApiError());
      await openViewer(tester);
      expect(find.byType(PostImageViewer), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  testWidgets('182: Home Active Requests leave Sakuna incident reports out, as View all does', (tester) async {
    FakeApi.installFull((r) {
      if (r.path == '/citizen/incidents') {
        return [
          {'ref': 'INC-2026-990001', 'type': 'flood', 'title': 'Synthetic flood report', 'status': 'Submitted', 'reported': '2026-11-18T00:00:00Z'},
        ];
      }
      throw const FakeApiError();
    });
    tester.view.physicalSize = const Size(412, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = RequestsService();
    await tester.runAsync(() => requests.loadIncidents());
    expect(requests.all.map((r) => r.referenceNumber), ['INC-2026-990001'], reason: 'the report is loaded');
    final session = CitizenSessionService();
    await session.login(MockCatalog.demoAccounts.first);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider<RequestsService>.value(value: requests),
          ChangeNotifierProvider<ResidentProfileService>(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider<NotificationsService>(create: (_) => NotificationsService()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('INC-2026-990001'), findsNothing);
    expect(find.text('No active requests'), findsOneWidget);
  });

  testWidgets('183: Events reads what is coming up on its own, so a long history never pushes it out', (tester) async {
    final queries = <Map<String, String>>[];
    FakeApi.installFull((r) {
      if (r.path != '/events') return <dynamic>[];
      queries.add(r.query);
      if (r.query['upcoming'] == '1') {
        return [
          {'key': 'ev-next', 'name': 'Synthetic Coming Fiesta', 'date': _day(5)},
        ];
      }
      if (r.query.containsKey('from') && r.query.containsKey('to')) {
        return [
          {'key': 'ev-last', 'name': 'Synthetic Last Month Drive', 'date': _day(-30)},
        ];
      }
      // The whole history, oldest first: all an unfiltered first read gets.
      return [
        for (var i = 0; i < 5; i++) {'key': 'ev-old-$i', 'name': 'Synthetic Old Event $i', 'date': _day(-900 - i)},
      ];
    });
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        child: const MaterialApp(home: EventsScreen()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('Synthetic Coming Fiesta'), findsOneWidget);
    expect(queries, isNotEmpty);
    expect(
      queries.every((q) => q['upcoming'] == '1' || (q.containsKey('from') && q.containsKey('to'))),
      isTrue,
      reason: 'no unbounded read of the whole history: $queries',
    );
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(find.text('Synthetic Last Month Drive'), findsOneWidget);
    expect(find.text('Synthetic Coming Fiesta'), findsNothing);
  });

  group('188: a TLS failure', () {
    tearDown(() => ApiClient.unreachable.value = false);

    test('is an ApiException that can be retried, and marks the server unreachable', () async {
      ApiClient.unreachable.value = false;
      final client = ApiClient(
        httpClient: MockClient((_) async => throw HandshakeException('CERTIFICATE_VERIFY_FAILED')),
        baseUrl: 'https://test.invalid',
      );
      await expectLater(
        client.get('/events'),
        throwsA(isA<ApiException>().having((e) => e.retryable, 'retryable', isTrue)),
      );
      expect(ApiClient.unreachable.value, isTrue);
    });

    test('in an upload too', () async {
      final client = ApiClient(
        httpClient: MockClient((_) async => throw HandshakeException('CERTIFICATE_VERIFY_FAILED')),
        baseUrl: 'https://test.invalid',
      );
      await expectLater(client.postMultipart('/citizen/papeles', fields: {'name': 'Clearance'}), throwsA(isA<ApiException>()));
    });
  });

  test('189: a Papeles upload that was saved stays saved when reading the wallet again fails', () async {
    final calls = <String>[];
    FakeApi.installFull((r) {
      calls.add('${r.method} ${r.path}');
      if (r.method == 'POST' && r.path == '/citizen/papeles') {
        return {'id': 41, 'name': 'Clearance', 'type': 'Supporting document', 'file_type': 'pdf', 'uploaded_at': '2026-11-18T00:00:00Z'};
      }
      throw const FakeApiError(status: 503, code: 'UNAVAILABLE', messageEn: 'Synthetic outage', messageFil: 'Synthetic outage');
    });
    final dir = await Directory.systemTemp.createTemp('esp_sweep_app4');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/clearance.pdf')..writeAsBytesSync('%PDF-1.4'.codeUnits);
    final service = MasterFileService();
    addTearDown(service.dispose);

    // Not thrown: the upload itself went through.
    await service.addToWallet(accountId: 'acct-1', name: 'Clearance', filePath: file.path);
    expect(calls, ['POST /citizen/papeles', 'GET /citizen/papeles']);
    expect(service.documentsFor('acct-1').map((d) => d.id), ['pap-41']);
  });

  testWidgets('207: a notice left in the tray opens nothing once nobody is signed in', (tester) async {
    final session = CitizenSessionService();
    await tester.runAsync(() => pumpEventQueue());
    await tester.pumpWidget(
      ChangeNotifierProvider<CitizenSessionService>.value(
        value: session,
        child: const MaterialApp(home: Scaffold(body: Text('tray check'))),
      ),
    );
    expect(session.loading, isFalse);
    expect(PushService.signedInFor(tester.element(find.text('tray check'))), isFalse);
    await tester.runAsync(() => session.login(MockCatalog.demoAccounts.first));
    expect(PushService.signedInFor(tester.element(find.text('tray check'))), isTrue);
  });

  testWidgets('208: confirm buttons sit side by side only when the outlined cancel label fits whole', (tester) async {
    const cancelLabel = 'MMMMMMM';
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var sideBySide = 0;
    // Quarter-point widths: never exactly on the edge where the label just
    // fits (this bare MaterialApp's bodyMedium adds 0.25 letter spacing, so
    // the edge lands on a half point).
    for (var w = 330; w <= 380; w++) {
      tester.view.physicalSize = Size(2.0 * w + 0.5, 1600);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(w),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => AppDialogs.confirm(context, title: 'T', message: 'M', confirmLabel: 'OK', cancelLabel: cancelLabel),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final cancel = find.text(cancelLabel);
      if ((tester.getCenter(cancel).dy - tester.getCenter(find.text('OK')).dy).abs() < 1) {
        sideBySide++;
        expect(
          tester.renderObject<RenderParagraph>(cancel).didExceedMaxLines,
          isFalse,
          reason: 'side by side at ${w + 0.25} wide, the cancel label was cut',
        );
      }
      await tester.tap(cancel);
      await tester.pumpAndSettle();
    }
    expect(sideBySide, greaterThan(0));
  });

  testWidgets("212: an official's profile fits a phone on its side, and the rest scrolls", (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final barangay = BarangayInfo.fromApi({
      'name': 'Labangtaytay',
      'history': {
        'summary': 'Puroks 9–12 · Formerly Barrio Tabunok',
        'leadership': [
          {'name': 'Cora Tatlo', 'title': 'Punong Barangay', 'term': '2001 – 2010'},
          {'name': 'Dan Apat', 'title': 'Punong Barangay', 'term': '2010 – Present'},
        ],
      },
      'officials_roster': [
        {'name': 'Hon. Dan Apat', 'position': 'Punong Barangay', 'committee': 'Chairperson, BDRRMC'},
        {'name': 'Cora Tatlo', 'position': 'Barangay Kagawad', 'committee': 'Environment'},
      ],
    })!;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CitizenSessionService(),
        child: MaterialApp(home: BarangayProfileScreen(barangay: barangay)),
      ),
    );
    await tester.pumpAndSettle();
    for (final text in ['Officials & Staff', 'Cora Tatlo']) {
      await tester.ensureVisible(find.text(text).last);
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    // Before, the fixed 320dp photo alone was taller than the dialog: the
    // column overflowed and the name and committee were cut off.
    expect(tester.takeException(), isNull);
    final dialog = find.byType(Dialog);
    expect(find.descendant(of: dialog, matching: find.text('Cora Tatlo')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.byType(SingleChildScrollView)), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.text('Committee')), findsOneWidget);
  });

  group('214: a Balita link with no post', () {
    testWidgets('opens nothing and throws nothing while the app runs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(onGenerateRoute: DeepLinks.routeFor, home: Scaffold(body: Text('Home'))),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      for (final link in ['/citizen/announcements', '/citizen/announcements?post=abc', '/citizen/announcements/']) {
        navigator.pushNamed(link);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: link);
        expect(find.text('Home'), findsOneWidget);
        expect(navigator.canPop(), isFalse, reason: '$link closes at once');
      }
    });

    test('a post link still opens its post', () {
      expect(DeepLinks.routeFor(const RouteSettings(name: '/citizen/announcements?post=42')), isA<MaterialPageRoute<void>>());
    });
  });
}
