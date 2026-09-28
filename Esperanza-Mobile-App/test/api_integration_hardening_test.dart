// Pins the integration fixes for the endpoints mobile calls on the real
// backend: auth, Dokyu/Tulong requests, Balita, and the public info reads
// (events, directory, hotlines, evacuation centers).
//
// Each group names the failure it guards against. All traffic goes through
// package:http's MockClient -- nothing here reaches the network.
import 'dart:convert';
import 'dart:io';

import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/models/access_level.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/json_read.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/utils/phone_dial.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

const _base = 'https://test.invalid';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// Installs a client whose [handler] sees the raw request, so a test can
/// answer with `meta`, a non-envelope error body, or a specific status.
List<http.BaseRequest> _install(Future<http.Response> Function(http.Request r) handler) {
  final seen = <http.BaseRequest>[];
  api = ApiClient(
    httpClient: MockClient((r) {
      seen.add(r);
      return handler(r);
    }),
    baseUrl: _base,
  );
  return seen;
}

CitizenAccount _account({String status = 'Pending Review'}) => CitizenAccount(
  id: 'ESP-TEST-0001',
  firstName: 'Testa',
  lastName: 'Sintetiko',
  email: 'testa@example.invalid',
  mobile: '',
  barangay: 'Poblacion',
  purok: '',
  address: '',
  birthdate: '',
  sex: '',
  civilStatus: '',
  occupation: '',
  profileCompleteness: 0,
  status: status,
);

Map<String, dynamic> _profile({String status = 'Approved'}) => {
  'account_no': 'ESP-TEST-0001',
  'first_name': 'Testa',
  'last_name': 'Sintetiko',
  'status': status,
  'profile_completeness': '80',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  group('ApiClient error envelope', () {
    test("reads Laravel's default {message, errors} body, not only {error: …}", () async {
      _install(
        (_) async => _json({
          'message': 'The email field is required.',
          'errors': {
            'email': ['The email field is required.'],
          },
        }, 422),
      );
      await expectLater(
        api.post('/auth/citizen/register'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isValidation, 'isValidation', isTrue)
              .having((e) => e.message(), 'message', 'The email field is required.')
              .having((e) => e.fields['email'], 'fields.email', ['The email field is required.']),
        ),
      );
    });

    test('a non-map meta does not throw a TypeError on success', () async {
      _install((_) async => _json({'data': [], 'meta': []}));
      final res = await api.get('/events');
      expect(res.meta, isNull);
      expect(res.list, isEmpty);
    });

    test('a numeric error code still surfaces as a string', () async {
      _install((_) async => _json({'error': {'code': 42, 'message': 'x'}}, 400));
      await expectLater(api.get('/x'), throwsA(isA<ApiException>().having((e) => e.code, 'code', '42')));
    });
  });

  group('ApiClient session expiry', () {
    test('a 401 on a signed-in endpoint notifies listeners', () async {
      var fired = 0;
      void listener() => fired++;
      ApiClient.addSessionExpiredListener(listener);
      addTearDown(() => ApiClient.removeSessionExpiredListener(listener));
      _install((_) async => _json({'message': 'Unauthenticated.'}, 401));

      await expectLater(api.get('/citizen/requests'), throwsA(isA<ApiException>()));
      expect(fired, 1);
    });

    test('a 401 on /auth/* is a wrong password, not an expired session', () async {
      var fired = 0;
      void listener() => fired++;
      ApiClient.addSessionExpiredListener(listener);
      addTearDown(() => ApiClient.removeSessionExpiredListener(listener));
      _install((_) async => _json({'message': 'Invalid credentials.'}, 401));

      await expectLater(api.post('/auth/citizen/login'), throwsA(isA<ApiException>()));
      expect(fired, 0);
    });
  });

  group('ApiClient pagination', () {
    test('getAllPages follows meta.last_page to the end', () async {
      final seen = _install((r) async {
        final page = int.parse(r.url.queryParameters['page'] ?? '1');
        return _json({
          'data': [
            {'n': page},
          ],
          'meta': {'current_page': page, 'last_page': 3},
        });
      });
      final rows = await api.getAllPages('/citizen/requests', query: {'per_page': 1});
      expect(rows.map((r) => (r as Map)['n']), [1, 2, 3]);
      expect(seen, hasLength(3));
      expect(seen.first.url.queryParameters.containsKey('page'), isFalse);
    });

    test('an unpaginated endpoint is fetched once', () async {
      final seen = _install((_) async => _json({'data': [1, 2]}));
      expect(await api.getAllPages('/hotlines'), [1, 2]);
      expect(seen, hasLength(1));
    });

    test('maxPages bounds a server that never reports the end', () async {
      final seen = _install(
        (r) async => _json({
          'data': [0],
          'meta': {'current_page': int.parse(r.url.queryParameters['page'] ?? '1'), 'last_page': 999},
        }),
      );
      await api.getAllPages('/events', maxPages: 4);
      expect(seen, hasLength(4));
    });
  });

  test('multipart uploads go through the injected client, not a fresh one', () async {
    final dir = await Directory.systemTemp.createTemp('esp_upload');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/id.jpg')..writeAsBytesSync([1, 2, 3]);
    final seen = _install((_) async => _json({'data': {'ok': true}}));

    final res = await api.postMultipart('/community-posts', filePath: file.path, fileField: 'image');
    expect(res.map['ok'], isTrue);
    expect(seen.single.url.path, '/community-posts');
  });

  test('path segments are encoded', () {
    expect(ApiClient.segment('DR 2026/0001'), 'DR%202026%2F0001');
  });

  group('JsonRead', () {
    test('coerces the shapes a Laravel resource realistically sends', () {
      expect(JsonRead.integer('12'), 12);
      expect(JsonRead.integer(3.0), 3);
      expect(JsonRead.integer('abc'), isNull);
      expect(JsonRead.boolean(1), isTrue);
      expect(JsonRead.boolean('false'), isFalse);
      expect(JsonRead.string(7), '7');
      expect(JsonRead.nonEmpty('  '), isNull);
      expect(JsonRead.strings(['a', 1, null, {}]), ['a', '1']);
    });

    test('rows skips a malformed row instead of failing the list', () {
      final parsed = JsonRead.rows<int>([
        {'id': 1},
        'not a map',
        {'id': 'x'},
        {'id': 3},
      ], (r) => JsonRead.integer(r['id']) ?? (throw const FormatException()));
      expect(parsed, [1, 3]);
    });

    test('mediaUrl resolves relative paths against the API origin', () {
      const base = 'https://api.example.invalid/api/v1';
      expect(JsonRead.mediaUrl('/storage/a.jpg', baseUrl: base), 'https://api.example.invalid/storage/a.jpg');
      expect(JsonRead.mediaUrl('storage/a.jpg', baseUrl: base), 'https://api.example.invalid/storage/a.jpg');
      expect(JsonRead.mediaUrl('https://cdn.invalid/a.jpg', baseUrl: base), 'https://cdn.invalid/a.jpg');
      expect(JsonRead.mediaUrl('', baseUrl: base), isNull);
    });
  });

  group('dialUri', () {
    test('dials only the first number, as digits', () {
      expect(dialUri('(056) 123-4567')?.toString(), 'tel:0561234567');
      expect(dialUri('0917 123 4567 / 0998 765 4321')?.toString(), 'tel:09171234567');
      expect(dialUri('Globe: +63 917-123-4567')?.toString(), 'tel:+639171234567');
      expect(dialUri('911')?.toString(), 'tel:911');
    });

    test('no number means no call button', () {
      expect(dialUri('To follow'), isNull);
      expect(dialUri(''), isNull);
      expect(dialUri(null), isNull);
    });
  });

  group('CitizenSessionService', () {
    Future<CitizenSessionService> restored(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final session = CitizenSessionService();
      addTearDown(session.dispose);
      await pumpEventQueue(times: 50);
      return session;
    }

    test('a warm start re-reads the profile, so an LGU verification takes effect', () async {
      _install((r) async => r.url.path == '/citizen/profile' ? _json({'data': _profile()}) : _json({}, 404));
      final session = await restored({
        'esperanza_citizen_session': jsonEncode(_account().toJson()),
        'esperanza_api_token': 't0k3n',
      });
      expect(session.account?.status, 'Approved');
      expect(session.accessLevel, AccessLevel.verified);
      expect(session.account?.profileCompleteness, 80);
    });

    test('a warm start offline keeps the cached session', () async {
      api = ApiClient(httpClient: MockClient((_) async => throw http.ClientException('offline')), baseUrl: _base);
      final session = await restored({
        'esperanza_citizen_session': jsonEncode(_account().toJson()),
        'esperanza_api_token': 't0k3n',
      });
      expect(session.isSignedIn, isTrue);
      expect(session.account?.status, 'Pending Review');
    });

    test('a revoked token signs the citizen out locally', () async {
      _install((_) async => _json({'message': 'Unauthenticated.'}, 401));
      final session = await restored({
        'esperanza_citizen_session': jsonEncode(_account().toJson()),
        'esperanza_api_token': 'revoked',
      });
      expect(session.isSignedIn, isFalse);
      expect(await api.getToken(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('esperanza_citizen_session'), isNull);
    });

    test('a login response without a token fails as an ApiException and signs nobody in', () async {
      final seen = _install((_) async => _json({'data': {}}));
      final session = await restored({});
      await expectLater(session.loginWithCredentials('a@b.c', 'pw'), throwsA(isA<ApiException>()));
      expect(session.isSignedIn, isFalse);
      // Never went on to call /citizen/profile unauthenticated.
      expect(seen.map((r) => r.url.path), ['/auth/citizen/login']);
    });

    test('a token whose profile cannot load is dropped', () async {
      _install(
        (r) async => r.url.path == '/auth/citizen/login'
            ? _json({'data': {'token': 'abc'}})
            : _json({'error': {'code': 'SERVER', 'message': 'boom'}}, 500),
      );
      final session = await restored({});
      await expectLater(session.loginWithCredentials('a@b.c', 'pw'), throwsA(isA<ApiException>()));
      expect(await api.getToken(), isNull);
    });

    test('login then profile with numeric/loose fields signs in', () async {
      _install(
        (r) async => r.url.path == '/auth/citizen/login'
            ? _json({'data': {'token': 'abc'}})
            : _json({'data': _profile(status: 'Verified')}),
      );
      final session = await restored({});
      await session.loginWithCredentials('a@b.c', 'pw');
      expect(session.account?.id, 'ESP-TEST-0001');
      expect(session.accessLevel, AccessLevel.verified);
    });

    test('verify-code with no token is an ApiException, not a TypeError', () async {
      _install((_) async => _json({'data': {}}));
      final session = await restored({});
      await expectLater(session.verifyEmailCode(email: 'a@b.c', code: '123456'), throwsA(isA<ApiException>()));
    });
  });

  group('RequestsService', () {
    test('loads every page of requests and skips unreadable rows', () async {
      _install((r) async {
        final page = int.parse(r.url.queryParameters['page'] ?? '1');
        return _json({
          'data': page == 1
              ? [
                  {'ref': 'DR-2026-0001', 'type': 'dokyu', 'service': 'Cedula', 'status': 'Submitted', 'submitted': '2026-09-01T00:00:00Z'},
                  {'ref': null, 'status': 'Submitted'},
                  'garbage',
                ]
              : [
                  {'ref': 'AR-2026-0002', 'type': 'tulong', 'service': 'Burial', 'status': 'Approved'},
                ],
          'meta': {'current_page': page, 'last_page': 2},
        });
      });
      final service = RequestsService();
      addTearDown(service.dispose);
      await service.loadRequests();
      expect(service.all.map((r) => r.referenceNumber), ['DR-2026-0001', 'AR-2026-0002']);
    });

    test('detail keeps transition remarks and encodes the reference', () async {
      final seen = _install(
        (_) async => _json({
          'data': {
            'ref': 'DR 1',
            'type': 'dokyu',
            'status': 'Under Review',
            'history': [
              {'to': 'Submitted', 'at': '2026-09-01T00:00:00Z'},
              {'to': 'Under Review', 'at': '2026-09-02T00:00:00Z', 'actor_name': 'MCR Staff', 'remarks': 'Bring the original.'},
              {'at': '2026-09-03T00:00:00Z'},
            ],
            'needs_correction': [
              {'key': 'valid_id', 'label': 'Valid ID', 'remarks': 'Blurry'},
              {'label': 'No key'},
            ],
            'can_resubmit': 1,
          },
        }),
      );
      final service = RequestsService();
      addTearDown(service.dispose);
      final r = await service.loadDetail('DR 1');
      expect(seen.single.url.toString(), '$_base/citizen/requests/DR%201');
      expect(r.statusHistory.map((h) => h.status), ['Submitted', 'Under Review']);
      expect(r.statusHistory.last.remarks, 'Bring the original.');
      expect(r.flaggedRequirements.map((f) => f.id), ['valid_id']);
      expect(r.canResubmit, isTrue);
    });

    test('a submit reply without a reference is an error, not a blank row', () async {
      _install((_) async => _json({'data': {}}, 201));
      final service = RequestsService();
      addTearDown(service.dispose);
      await expectLater(service.submit(serviceKey: 'cedula', formData: {}), throwsA(isA<ApiException>()));
      expect(service.all, isEmpty);
    });

    test('a catalog entry without a fee reads as a dash, never Free', () async {
      _install(
        (_) async => _json({
          'data': [
            {'key': 'cedula', 'name': 'Cedula', 'fee': {'display': '₱50.00'}},
            {'key': 'mystery', 'name': 'Mystery'},
            {'name': 'No key'},
          ],
        }),
      );
      final service = RequestsService();
      addTearDown(service.dispose);
      await service.loadCatalog();
      expect(service.dokyuCatalog.map((c) => c.key), ['cedula', 'mystery']);
      expect(service.dokyuCatalog.map((c) => c.fee), ['₱50.00', '—']);
    });

    test('an expired session clears the in-memory request list', () async {
      _install(
        (r) async => _json({
          'data': [
            {'ref': 'DR-1', 'type': 'dokyu', 'status': 'Submitted'},
          ],
        }),
      );
      final service = RequestsService();
      addTearDown(service.dispose);
      await service.loadRequests();
      expect(service.all, hasLength(1));

      _install((_) async => _json({'message': 'Unauthenticated.'}, 401));
      await expectLater(service.loadRequests(), throwsA(isA<ApiException>()));
      expect(service.all, isEmpty);
    });
  });

  group('BalitaService', () {
    Map<String, dynamic> ann(Object id, {bool liked = false}) => {
      'id': id,
      'body': 'Announcement $id',
      'published_at': '2026-09-0${id}T00:00:00Z',
      'likes': '3',
      'liked_by_me': liked,
      'image_url': '/storage/a$id.jpg',
    };

    test('a failing community feed still shows the announcements', () async {
      _install(
        (r) async => r.url.path == '/announcements'
            ? _json({
                'data': [ann(1), ann('2')],
              })
            : _json({'error': {'code': 'CAPABILITY_DENIED', 'message': 'no'}}, 403),
      );
      final balita = BalitaService();
      addTearDown(balita.dispose);
      await balita.loadFeed(signedIn: true);
      expect(balita.posts.map((p) => p.remoteId), [2, 1]);
      expect(balita.communityUnavailable, isTrue);
    });

    test('announcements keep liked_by_me and absolute image URLs', () async {
      _install(
        (_) async => _json({
          'data': [ann(1, liked: true)],
        }),
      );
      final balita = BalitaService();
      addTearDown(balita.dispose);
      await balita.loadFeed(signedIn: false);
      final post = balita.posts.single;
      expect(post.likedByMe, isTrue);
      expect(post.likes, 3);
      expect(post.imageUrl, 'https://test.invalid/storage/a1.jpg');
    });

    test("a post still in moderation is shown only to its author", () async {
      _install(
        (r) async => r.url.path == '/announcements'
            ? _json({'data': []})
            : _json({
                'data': [
                  {'id': 1, 'body': 'mine', 'visible': false, 'mine': true, 'status': 'Pending Review'},
                  {'id': 2, 'body': 'theirs', 'visible': false, 'mine': false},
                  {'id': 3, 'body': 'public', 'visible': true},
                  {'body': 'no id'},
                ],
              }),
      );
      final balita = BalitaService();
      addTearDown(balita.dispose);
      await balita.loadFeed(signedIn: true);
      expect(balita.posts.map((p) => p.body), unorderedEquals(['mine', 'public']));
      expect(balita.communityUnavailable, isFalse);
    });

    test('a second like tap while the first is in flight is ignored', () async {
      var calls = 0;
      _install((_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return _json({'data': {'liked': true, 'likes': 4}});
      });
      final balita = BalitaService();
      addTearDown(balita.dispose);
      final post = Announcement.fromAnnouncementApi(ann(1));
      await Future.wait([balita.toggleLike(post), balita.toggleLike(post)]);
      expect(calls, 1);
      expect(post.likedByMe, isTrue);
      expect(post.likes, 4);
    });

    test('a created post is in the live list the feed renders', () async {
      _install((_) async => _json({'data': {'id': '9', 'body': 'Hello', 'mine': true, 'status': 'Pending Review'}}, 201));
      final balita = BalitaService();
      addTearDown(balita.dispose);
      await balita.createPost(body: 'Hello', category: 'General');
      expect(balita.posts.single.remoteId, 9);
    });
  });

  group('EventItem', () {
    test('calendar order: upcoming soonest first, then past, then undated', () {
      EventItem e(String title, String? date) => EventItem.fromApi({'title': title, 'date': date});
      final ordered = EventItem.inCalendarOrder([
        e('past-old', '2026-01-01'),
        e('undated', null),
        e('later', '2026-12-01'),
        e('today', '2026-09-28'),
        e('past-recent', '2026-09-01'),
      ], now: DateTime(2026, 9, 28, 18));
      expect(ordered.map((x) => x.title), ['today', 'later', 'past-recent', 'past-old', 'undated']);
    });

    test('title falls back to name', () {
      expect(EventItem.fromApi({'title': '  ', 'name': 'Fiesta'}).title, 'Fiesta');
    });
  });
}
