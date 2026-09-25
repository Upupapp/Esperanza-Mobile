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

class FakeApi {
  FakeApi._();

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
    // No /api/v1 prefix here on purpose: screens call api.get('/sakuna/centers')
    // etc. with paths that already assume the real baseUrl's /api/v1 is part
    // of it. If this fake baseUrl repeated that prefix, request.url.path
    // would come back as '/api/v1/sakuna/centers' and never match a
    // handler written to check for the plain '/sakuna/centers' a screen
    // actually asked for.
    return ApiClient(httpClient: client, baseUrl: 'https://test.invalid');
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

  /// Puts the suite back on [_defaultFake] -- not the real network client,
  /// which no test in this suite should ever be able to reach at all.
  /// Call from `tearDown` after any test that used [install].
  static void restore() => api = _defaultFake;
}
