// Live updates (2026-11-15). While the app is open it reads the server's
// change counters - /live/changes.json, beside the API - every second, and
// each screen reloads its own data, quietly and only while it shows, when a
// topic it shows moves. These hold the reading (what is a change, what is no
// news, one read at a time, nothing in the background), the screens' side (a
// tab on show, a hidden tab, a page under another, no loader on a reload),
// the shell's (the bell on every tab, the app's lifecycle) and the services'
// quiet reloads.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/home/root_shell.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/live_updates.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_theme.dart';
import 'package:esperanza_mobile/widgets/async_state_view.dart';
import 'package:esperanza_mobile/widgets/live_refresh.dart';

import 'support/fake_api.dart';

/// A server whose live file a test rewrites as it goes: [body] null answers
/// 404, a String is sent as it is (an error page), [drop] fails the
/// connection, and [hold] keeps the answer back until it completes.
class _Server {
  Object? body = {
    'v': 1,
    't': {'requests': 1},
  };
  int status = 200;
  bool drop = false;
  Completer<void>? hold;
  final reads = <http.BaseRequest>[];

  late final ApiClient client = ApiClient(
    baseUrl: 'https://esperanza.example/api/v1',
    httpClient: MockClient((request) async {
      reads.add(request);
      final wait = hold;
      if (wait != null) await wait.future;
      if (drop) throw http.ClientException('Connection closed', request.url);
      final answer = body;
      if (answer == null) return http.Response('Not Found', 404);
      return http.Response(answer is String ? answer : jsonEncode(answer), status);
    }),
  );
}

/// Reads [server] as the app does, and lists the topics it was told moved.
(LiveUpdates, List<Set<String>>) _watch(_Server server) {
  final live = LiveUpdates(client: server.client);
  final told = <Set<String>>[];
  live.addListener(() => told.add(live.lastMoved));
  return (live, told);
}

Future<void> _closePopups(WidgetTester tester) async {
  final close = find.byIcon(Icons.close_rounded);
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// The shell, signed in as the verified demo resident, on a server that
/// keeps the live file. Returns how often each path was read (GET).
Future<Map<String, int>> _pumpSignedInShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final gets = <String, int>{};
  FakeApi.installFull((r) {
    if (r.method != 'GET') throw const FakeApiError();
    gets.update(r.path, (n) => n + 1, ifAbsent: () => 1);
    if (const {'/citizen/notifications', '/citizen/requests', '/citizen/records', '/services'}.contains(r.path)) {
      return <dynamic>[];
    }
    throw const FakeApiError();
  });
  FakeApi.liveFile = {
    'v': 1,
    't': {'notifications': 1, 'requests': 1},
  };
  final session = CitizenSessionService();
  await session.login(MockCatalog.demoAccounts.last);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: RootShell.withKey()),
    ),
  );
  await tester.pumpAndSettle();
  await _closePopups(tester);
  return gets;
}

void main() {
  tearDown(FakeApi.restore);

  group('reading the counters', () {
    test('the file sits on the API origin, without the /api/v1 path', () {
      ApiClient client(String base) =>
          ApiClient(baseUrl: base, httpClient: MockClient((_) async => http.Response('', 404)));
      expect(client('https://esperanza.139-162-51-165.sslip.io/api/v1').origin.toString(), 'https://esperanza.139-162-51-165.sslip.io');
      expect(client('http://10.0.2.2:8000/api/v1').origin.toString(), 'http://10.0.2.2:8000');
    });

    testWidgets('it reads at once, then every second, with no sign-in header', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final server = _Server();
      await server.client.setToken('a-signed-in-token');
      final (live, _) = _watch(server);
      live.start();
      await tester.pump();
      expect(server.reads, hasLength(1), reason: 'the first read is at once');
      final read = server.reads.single;
      expect(read.method, 'GET');
      expect(read.url.toString(), 'https://esperanza.example/live/changes.json');
      expect(read.headers.keys.map((k) => k.toLowerCase()), isNot(contains('authorization')));

      await tester.pump(const Duration(seconds: 3));
      expect(server.reads, hasLength(4));
      live.dispose();
    });

    testWidgets('the first read is the baseline, and the same v is no news', (tester) async {
      final server = _Server()
        ..body = {
          'v': 7,
          't': {'requests': 3, 'balita': 2},
        };
      final (live, told) = _watch(server);
      live.start();
      await tester.pump(const Duration(seconds: 5));
      expect(server.reads, hasLength(6));
      expect(told, isEmpty);
      expect(live.answering, isTrue);
      live.dispose();
    });

    testWidgets('a topic that moves is told, with only the topics that moved', (tester) async {
      final server = _Server()
        ..body = {
          'v': 1,
          't': {'requests': 1, 'balita': 1},
        };
      final (live, told) = _watch(server);
      live.start();
      await tester.pump();

      server.body = {
        'v': 2,
        't': {'requests': 2, 'balita': 1},
      };
      await tester.pump(const Duration(seconds: 1));
      expect(told, [
        {'requests'},
      ]);
      expect(live.stamp(['requests']), 1);
      expect(live.stamp(['balita']), 0);

      // A topic the file never counted before is a move too.
      server.body = {
        'v': 3,
        't': {'requests': 2, 'balita': 1, 'sakuna': 1},
      };
      await tester.pump(const Duration(seconds: 1));
      expect(told.last, {'sakuna'});

      server.body = {
        'v': 4,
        't': {'requests': 3, 'balita': 2, 'sakuna': 1},
      };
      await tester.pump(const Duration(seconds: 1));
      expect(told.last, {'requests', 'balita'});
      expect(told, hasLength(3));
      expect(live.stamp(['requests', 'balita', 'sakuna']), 4);
      live.dispose();
    });

    testWidgets('a missing file, an error, a dropped connection or a stray body is no news, and reading goes on', (
      tester,
    ) async {
      final server = _Server();
      final (live, told) = _watch(server);
      live.start();
      await tester.pump();
      expect(live.answering, isTrue);

      final noNews = <void Function()>[
        () => server.body = null, // 404: a server without the file
        () => server
          ..body = '<html>502 Bad Gateway</html>'
          ..status = 502,
        () => server
          ..body = 'not json'
          ..status = 200,
        () => server.body = {'data': <Object>[]}, // an API answer, not the counters
        () => server.body = {
          'v': 'nine',
          't': {'requests': 9},
        },
        () => server.body = {'v': 9, 't': 'requests'},
        () => server
          ..body = {
            'v': 9,
            't': {'requests': 9},
          }
          ..drop = true,
      ];
      for (final next in noNews) {
        next();
        await tester.pump(const Duration(seconds: 1));
        expect(live.answering, isFalse);
      }
      expect(told, isEmpty);
      expect(server.reads, hasLength(1 + noNews.length), reason: 'it kept reading every second');

      server
        ..drop = false
        ..body = {
          'v': 2,
          't': {'requests': 2},
        };
      await tester.pump(const Duration(seconds: 1));
      expect(told, [
        {'requests'},
      ], reason: 'compared with the last good read');
      expect(live.answering, isTrue);
      live.dispose();
    });

    testWidgets('one read at a time: a slow answer is waited for, a lost one given up after 5 seconds', (tester) async {
      final server = _Server();
      final (live, _) = _watch(server);
      live.start();
      await tester.pump();
      expect(server.reads, hasLength(1));

      final slow = Completer<void>();
      server.hold = slow;
      await tester.pump(const Duration(seconds: 1));
      expect(server.reads, hasLength(2));
      await tester.pump(const Duration(seconds: 3));
      expect(server.reads, hasLength(2), reason: 'no second read while one is under way');
      server.hold = null;
      slow.complete();
      await tester.pump(const Duration(seconds: 1));
      expect(server.reads, hasLength(3));

      final lost = Completer<void>();
      server.hold = lost;
      await tester.pump(const Duration(seconds: 1));
      expect(server.reads, hasLength(4));
      server.hold = null;
      await tester.pump(const Duration(seconds: 4));
      expect(server.reads, hasLength(4));
      await tester.pump(const Duration(seconds: 2));
      expect(server.reads.length, greaterThan(4), reason: 'given up after 5 seconds, it read again');
      lost.complete();
      live.dispose();
    });

    testWidgets('stopped, it reads nothing; started again, it reads at once and tells what moved meanwhile', (
      tester,
    ) async {
      final server = _Server()
        ..body = {
          'v': 1,
          't': {'requests': 1, 'notifications': 4},
        };
      final (live, told) = _watch(server);
      live.start();
      await tester.pump();
      live.stop();
      expect(live.running, isFalse);

      server.body = {
        'v': 3,
        't': {'requests': 1, 'notifications': 6},
      };
      await tester.pump(const Duration(seconds: 30));
      expect(server.reads, hasLength(1), reason: 'nothing is read in the background');
      expect(told, isEmpty);

      live.start();
      await tester.pump();
      expect(server.reads, hasLength(2), reason: 'back in the foreground, it reads at once');
      expect(told, [
        {'notifications'},
      ]);
      live.dispose();
    });

    testWidgets('a read under way when the app goes to the background is dropped, and told on return', (tester) async {
      final server = _Server()
        ..body = {
          'v': 1,
          't': {'balita': 1},
        };
      final (live, told) = _watch(server);
      live.start();
      await tester.pump();

      final slow = Completer<void>();
      server
        ..hold = slow
        ..body = {
          'v': 2,
          't': {'balita': 2},
        };
      await tester.pump(const Duration(seconds: 1));
      live.stop();
      server.hold = null;
      slow.complete();
      await tester.pump();
      expect(told, isEmpty, reason: 'nothing is told in the background');

      live.start();
      await tester.pump();
      expect(told, [
        {'balita'},
      ]);

      // Away and back while a read is under way: the dropped read is made
      // again at once, not a second later, and still one at a time.
      final again = Completer<void>();
      server.hold = again;
      await tester.pump(const Duration(seconds: 1));
      final reads = server.reads.length;
      live
        ..stop()
        ..start();
      expect(server.reads, hasLength(reads));
      server.hold = null;
      again.complete();
      await tester.pump();
      expect(server.reads, hasLength(reads + 1));
      live.dispose();
    });

    testWidgets('after a sign-out the next first read is a new baseline', (tester) async {
      final server = _Server();
      final (live, told) = _watch(server);
      live.start();
      await tester.pump();
      live.reset();
      server.body = {
        'v': 5,
        't': {'requests': 5},
      };
      live.start();
      await tester.pump();
      expect(told, isEmpty);
      expect(live.answering, isTrue);
      live.dispose();
    });
  });

  group('screens follow their topics while they show', () {
    testWidgets('the tab on show reloads at once; a hidden one once, when it shows again', (tester) async {
      final server = _Server()
        ..body = {
          'v': 1,
          't': {'requests': 1, 'balita': 1},
        };
      final live = LiveUpdates.instance = LiveUpdates(client: server.client);
      final reloads = <String, List<Set<String>>>{'home': [], 'dokyu': []};
      Widget tab(String name, Set<String> topics) =>
          LiveRefresh(topics: topics, onChange: (moved) async => reloads[name]!.add(moved), child: Text(name));
      final index = ValueNotifier(0);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<int>(
            valueListenable: index,
            builder: (context, i, _) => IndexedStack(
              index: i,
              children: [
                tab('home', const {'requests', 'balita'}),
                tab('dokyu', const {'requests'}),
              ],
            ),
          ),
        ),
      );
      live.start();
      await tester.pump();

      for (var v = 2; v <= 4; v++) {
        server.body = {
          'v': v,
          't': {'requests': v, 'balita': 1},
        };
        await tester.pump(const Duration(seconds: 1));
      }
      expect(reloads['home'], [
        {'requests'},
        {'requests'},
        {'requests'},
      ]);
      expect(reloads['dokyu'], isEmpty, reason: 'a hidden tab reads nothing');

      index.value = 1;
      await tester.pump();
      expect(reloads['dokyu'], [
        {'requests'},
      ], reason: 'once when it shows, however often it moved');

      server.body = {
        'v': 5,
        't': {'requests': 4, 'balita': 2},
      };
      await tester.pump(const Duration(seconds: 1));
      expect(reloads['dokyu'], hasLength(1), reason: 'Balita is not its topic');
      expect(reloads['home'], hasLength(3), reason: 'Home is hidden now');

      index.value = 0;
      await tester.pump();
      expect(reloads['home']!.last, {'balita'});
      live.stop();
    });

    testWidgets('a page with another page over it waits until it is on top again', (tester) async {
      final server = _Server();
      final live = LiveUpdates.instance = LiveUpdates(client: server.client);
      final reloads = <Set<String>>[];
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: LiveRefresh(
            topics: const {'requests'},
            onChange: (moved) async => reloads.add(moved),
            child: const Text('the request'),
          ),
        ),
      );
      live.start();
      await tester.pump();

      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('a page over it')));
      await tester.pumpAndSettle();
      server.body = {
        'v': 2,
        't': {'requests': 2},
      };
      await tester.pump(const Duration(seconds: 1));
      expect(reloads, isEmpty, reason: 'covered: nothing is read');

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(reloads, [
        {'requests'},
      ], reason: 'on top again: read once');
      live.stop();
    });

    testWidgets('a live AsyncStateView swaps new data in without its loader, and keeps it when a reload fails', (
      tester,
    ) async {
      final server = _Server();
      final live = LiveUpdates.instance = LiveUpdates(client: server.client);
      var version = 1;
      var fail = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<int>(
              liveTopics: const {'sakuna'},
              loader: () async {
                if (fail) throw const ApiException(messageEn: 'No internet connection.');
                return version;
              },
              builder: (context, data, reload) => Text('centres v$data'),
            ),
          ),
        ),
      );
      live.start();
      await tester.pumpAndSettle();
      expect(find.text('centres v1'), findsOneWidget);

      version = 2;
      server.body = {
        'v': 2,
        't': {'requests': 1, 'sakuna': 1},
      };
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('centres v1'), findsOneWidget, reason: 'what is shown stays while it reloads, no loader');
      await tester.pump();
      expect(find.text('centres v2'), findsOneWidget);

      fail = true;
      server.body = {
        'v': 3,
        't': {'requests': 1, 'sakuna': 2},
      };
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('centres v2'), findsOneWidget, reason: 'a failed reload keeps what is shown');
      expect(find.text('Something went wrong'), findsNothing);

      // The change it missed is read again at the next change, whatever moved.
      fail = false;
      version = 4;
      server.body = {
        'v': 4,
        't': {'requests': 2, 'sakuna': 2},
      };
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('centres v4'), findsOneWidget);
      live.stop();
    });
  });

  group('the shell', () {
    testWidgets('the bell follows notifications on every tab; a hidden Home catches up when it shows', (tester) async {
      final gets = await _pumpSignedInShell(tester);
      final shell = tester.element(find.byType(RootShell));
      final bell = gets['/citizen/notifications'] ?? 0;
      final requests = gets['/citizen/requests'] ?? 0;

      FakeApi.liveFile = {
        'v': 2,
        't': {'notifications': 2, 'requests': 1},
      };
      await tester.pump(const Duration(seconds: 1));
      expect(gets['/citizen/notifications'], bell + 1, reason: 'on Home');

      RootShell.jumpTo(shell, 1); // Balita
      await tester.pumpAndSettle();
      await _closePopups(tester);
      FakeApi.liveFile = {
        'v': 3,
        't': {'notifications': 3, 'requests': 2},
      };
      await tester.pump(const Duration(seconds: 1));
      expect(gets['/citizen/notifications'], bell + 2, reason: 'on Balita too: the bell is on every tab');
      expect(gets['/citizen/requests'] ?? 0, requests, reason: 'Home, Dokyu and Tulong are not showing');

      RootShell.jumpTo(shell, 0);
      await tester.pumpAndSettle();
      expect(gets['/citizen/requests'], requests + 1, reason: 'Home reads them once it shows');
    });

    testWidgets('the shell reads while the app is open, and nothing in the background', (tester) async {
      await _pumpSignedInShell(tester);
      final open = FakeApi.liveReads;
      await tester.pump(const Duration(seconds: 3));
      expect(FakeApi.liveReads, open + 3);

      for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      final away = FakeApi.liveReads;
      await tester.pump(const Duration(seconds: 30));
      expect(FakeApi.liveReads, away, reason: 'nothing is read in the background');

      for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(FakeApi.liveReads, away + 1, reason: 'back in the foreground, it reads at once');
    });
  });

  group('quiet reloads', () {
    test('requests reload with no loading state on the way, and a failure keeps the list', () async {
      SharedPreferences.setMockInitialValues({});
      var fail = false;
      var refs = ['DOK-2026-00001'];
      FakeApi.installFull((r) {
        if (fail) throw const FakeApiError(status: 503, code: 'UNAVAILABLE');
        return [
          for (final ref in refs)
            {
              'ref': ref,
              'type': 'dokyu',
              'service': 'Barangay Clearance (Synthetic)',
              'status': 'Submitted',
              'submitted': '2026-11-01T00:00:00Z',
            },
        ];
      });
      final service = RequestsService();
      await service.loadRequests();
      final loadedWhenTold = <bool>[];
      service.addListener(() => loadedWhenTold.add(service.loaded));

      refs = ['DOK-2026-00001', 'DOK-2026-00002'];
      await service.refreshRequests();
      expect(service.all.map((r) => r.referenceNumber), ['DOK-2026-00001', 'DOK-2026-00002']);
      expect(loadedWhenTold, everyElement(isTrue), reason: 'never "not loaded" on the way: no loader');

      fail = true;
      await expectLater(service.refreshRequests(), throwsA(isA<ApiException>()));
      expect(service.all, hasLength(2), reason: 'a failure keeps the list');

      // Signed out while one was under way: the old list does not come back.
      fail = false;
      final pending = service.refreshRequests();
      service.clear();
      await pending;
      expect(service.all, isEmpty);
      service.dispose();
    });

    test('Balita reads its first page again and keeps the pages loaded below it', () async {
      // 45 posts, newest first, 20 a page; post n was published n hours into the year.
      var posts = [for (var id = 45; id >= 1; id--) id];
      final likes = <int, int>{};
      Map<String, dynamic> row(int id) => {
        'id': id,
        'body': 'Post $id',
        'published_at': DateTime.utc(2026, 1, 1).add(Duration(hours: id)).toIso8601String(),
        'likes': likes[id] ?? 0,
      };
      api = ApiClient(
        baseUrl: 'https://test.invalid',
        httpClient: MockClient((request) async {
          final page = int.parse(request.url.queryParameters['page'] ?? '1');
          final rows = posts.skip((page - 1) * 20).take(20).map(row).toList();
          final meta = {'page': page, 'last_page': (posts.length / 20).ceil()};
          return http.Response(jsonEncode({'data': rows, 'meta': meta}), 200);
        }),
      );
      final balita = BalitaService();
      await balita.loadFeed();
      await balita.loadMore();
      expect(balita.posts, hasLength(40));

      // A new post, a like on another, and one taken down from the first page.
      posts = [46, ...posts.where((id) => id != 44)];
      likes[45] = 7;
      await balita.refreshFeed();

      final ids = balita.posts.map((p) => p.id).toList();
      expect(ids.first, 'ann-46', reason: 'the new post comes in at the top');
      expect(ids, isNot(contains('ann-44')), reason: 'taken down');
      expect(balita.posts.firstWhere((p) => p.id == 'ann-45').likes, 7);
      expect(ids, contains('ann-6'), reason: 'the second page stays loaded');
      expect(ids, hasLength(40));
      expect(ids.toSet(), hasLength(ids.length), reason: 'each post once');
      expect(balita.hasMore, isTrue);
      balita.dispose();
    });
  });
}
