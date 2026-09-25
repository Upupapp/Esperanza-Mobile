// Swaps the global `api` singleton (services/api_client.dart) for one
// backed by package:http/testing.dart's MockClient, so widget tests that
// exercise a real-API-backed screen never touch the network. Screens
// stopped reading MockCatalog and started calling `api.get(...)` directly
// starting with the Directory/Sakuna conversions (production-readiness
// programme, 2026-09-25); every screen converted the same way afterward
// needs the same test-side seam.
//
// A `flutter test` run has a real Dart VM with real socket access -- there
// is nothing that stops `api.get(...)` from actually reaching the live
// staging server if nothing here intervenes. test/flutter_test_config.dart
// installs the safe default (below) once for the whole suite before any
// test runs, so a test that forgets to set up its own fake response still
// gets a clean, local ApiException instead of a real, slow, flaky network
// call to a server this suite has no business depending on.
import 'dart:convert';

import 'package:esperanza_mobile/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Thrown by a [FakeApi.install] handler to produce a real error envelope
/// instead of a 200 -- `code`/`status` mirror what ApiClient._handle()
/// actually parses, so ApiException.isValidation/isForbidden etc. still
/// work the same way a widget's real error-handling code expects.
class FakeApiError implements Exception {
  const FakeApiError({this.status = 404, this.code = 'NOT_FOUND', this.messageEn = 'Not found', this.messageFil = 'Hindi natagpuan'});

  final int status;
  final String code;
  final String messageEn;
  final String messageFil;
}

/// A request as seen by an [FakeApi.installFull] handler -- everything a
/// POST/PUT-driven screen (submitting a request, resubmitting, replacing a
/// flagged requirement) needs to branch on that a plain GET never did:
/// which HTTP method, and the decoded JSON body. [body] is null for a GET/
/// DELETE, and for a multipart request (package:http's simple [MockClient]
/// hands the handler the request's raw encoded bytes as [http.Request.body]
/// rather than parsed fields, so multipart requests are matched on
/// [method]/[path] only -- no test in this suite has needed to assert on a
/// multipart request's own field values).
class FakeApiRequest {
  const FakeApiRequest({required this.method, required this.path, required this.query, this.body});

  final String method;
  final String path;
  final Map<String, String> query;
  final Map<String, dynamic>? body;
}

class FakeApi {
  FakeApi._();

  // No /api/v1 prefix here on purpose: screens call api.get('/sakuna/centers')
  // etc. with paths that already assume the real baseUrl's /api/v1 is part
  // of it. If this fake baseUrl repeated that prefix, request.url.path
  // would come back as '/api/v1/sakuna/centers' and never match a
  // handler written to check for the plain '/sakuna/centers' a screen
  // actually asked for.
  static const _fakeBaseUrl = 'https://test.invalid';

  static ApiClient _build(dynamic Function(String path, Map<String, String> query) handler) {
    final client = MockClient((request) async {
      try {
        final data = handler(request.url.path, request.url.queryParameters);
        return http.Response(jsonEncode({'data': data}), 200, headers: {'content-type': 'application/json'});
      } on FakeApiError catch (e) {
        return http.Response(
          jsonEncode({
            'error': {
              'code': e.code,
              'message': {'en': e.messageEn, 'fil': e.messageFil},
            },
          }),
          e.status,
          headers: {'content-type': 'application/json'},
        );
      }
    });
    return ApiClient(httpClient: client, baseUrl: _fakeBaseUrl);
  }

  static ApiClient _buildFull(dynamic Function(FakeApiRequest request) handler) {
    final client = MockClient((request) async {
      try {
        Map<String, dynamic>? body;
        if (request.body.isNotEmpty) {
          try {
            final decoded = jsonDecode(request.body);
            if (decoded is Map<String, dynamic>) body = decoded;
          } catch (_) {
            // Multipart (or otherwise non-JSON) body -- see FakeApiRequest's
            // own doc comment. Left null rather than thrown, so a handler
            // that only cares about method/path still works unmodified.
          }
        }
        final data = handler(
          FakeApiRequest(method: request.method, path: request.url.path, query: request.url.queryParameters, body: body),
        );
        return http.Response(jsonEncode({'data': data}), 200, headers: {'content-type': 'application/json'});
      } on FakeApiError catch (e) {
        return http.Response(
          jsonEncode({
            'error': {
              'code': e.code,
              'message': {'en': e.messageEn, 'fil': e.messageFil},
            },
          }),
          e.status,
          headers: {'content-type': 'application/json'},
        );
      }
    });
    return ApiClient(httpClient: client, baseUrl: _fakeBaseUrl);
  }

  static final ApiClient _defaultFake = _build(
    (path, query) => throw const FakeApiError(
      messageEn: 'This test did not configure a fake response for this request.',
      messageFil: 'Walang nakatakdang tugon para sa hilinging ito sa pagsusuring ito.',
    ),
  );

  /// Called once by flutter_test_config.dart, before any test in the suite
  /// runs. Every request that isn't given its own [install]'d handler
  /// fails with a plain, local [FakeApiError] -- visible to a widget as an
  /// ordinary network-error state, never a real socket connection.
  static void installDefault() => api = _defaultFake;

  /// [handler] receives the request path with the base URL stripped (e.g.
  /// `/directory`, `/sakuna/centers`) and the parsed query parameters, and
  /// returns whatever belongs at the response envelope's `data` key -- a
  /// `List` for a collection endpoint, a `Map` for a single resource.
  static void install(dynamic Function(String path, Map<String, String> query) handler) {
    api = _build(handler);
  }

  /// Same as [install], but for a screen that submits, resubmits, or
  /// replaces something -- [handler] gets the HTTP method and decoded JSON
  /// body too (see [FakeApiRequest]), so it can branch on more than just
  /// path/query. `RequestsService.submit`/`resubmit`/`replaceRequirement`
  /// are the callers this exists for.
  static void installFull(dynamic Function(FakeApiRequest request) handler) {
    api = _buildFull(handler);
  }

  /// Puts the suite back on [_defaultFake] -- not the real network client,
  /// which no test in this suite should ever be able to reach at all.
  /// Call from `tearDown` after any test that used [install].
  static void restore() => api = _defaultFake;
}
