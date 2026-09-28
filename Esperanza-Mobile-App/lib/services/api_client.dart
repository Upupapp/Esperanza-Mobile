import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The one HTTP client (production-readiness programme, 2026-09-25).
///
/// Mirrors the Web Admin's `resources/js/api/client.js` on purpose: the same
/// base-URL-at-build-time convention, the same one-error-envelope shape, the
/// same bearer-token-in-a-header auth, and the same reason for existing —
/// before this there was no HTTP client dependency in this app at all (see
/// CLAUDE.md, "no HTTP client dependency at all"). Auth, requests,
/// notifications and profile were simulated and persisted only to
/// `shared_preferences`.
///
/// Base URL: `API_BASE_URL`, passed with `--dart-define=API_BASE_URL=...` at
/// build time. Defaults to the backend's staging deployment on the shared
/// LGU IDS Linode so a plain `flutter run` / `flutter build` talks to
/// something real. Point it at `http://10.0.2.2:8000/api/v1` for an Android
/// emulator hitting `php artisan serve` on the host machine, or
/// `http://127.0.0.1:8000/api/v1` for an iOS simulator.
const String _defaultBaseUrl = 'https://esperanza.139-162-51-165.sslip.io/api/v1';

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

/// One error, one shape, everywhere a request can fail. Mirrors the web
/// client's `ApiError` (resources/js/api/errors.js) field for field, so the
/// same backend contract (`{"error":{"code","message":{"fil","en"},"fields"}}`)
/// is interpreted identically on both clients.
class ApiException implements Exception {
  final int? status;
  final String? code;
  final String? messageFil;
  final String? messageEn;
  final Map<String, List<String>> fields;
  final bool retryable;

  const ApiException({
    this.status,
    this.code,
    this.messageFil,
    this.messageEn,
    this.fields = const {},
    this.retryable = false,
  });

  bool get isValidation => status == 422;
  bool get isAuth => status == 401;
  bool get isForbidden => status == 403;

  /// English first — the app defaults to Filipino for citizen-facing copy
  /// (see CLAUDE.md), but callers pick the locale; this is the fallback
  /// chain when neither language came back.
  String message({bool filipino = true}) {
    final primary = filipino ? messageFil : messageEn;
    return primary ?? messageEn ?? messageFil ?? 'Something went wrong. Please try again.';
  }

  @override
  String toString() => 'ApiException($status, $code, ${message()})';
}

/// One JSON envelope in, `data` (+ `meta` when paginated) out. Every
/// endpoint in the contract wraps its payload as `{"data": ..., "meta"?}` or
/// `{"error": {...}}` — see esperanza-backend's `App\Http\ApiResponse`.
class ApiResult {
  final dynamic data;
  final Map<String, dynamic>? meta;

  const ApiResult({required this.data, this.meta});

  List<dynamic> get list => data is List ? data as List<dynamic> : const [];
  Map<String, dynamic> get map => data is Map<String, dynamic> ? data as Map<String, dynamic> : const {};
}

class ApiClient {
  ApiClient({http.Client? httpClient, this.baseUrl = apiBaseUrl}) : _http = httpClient ?? http.Client();

  /// Called when a signed-in request comes back 401: the server has revoked
  /// or expired the bearer token, so every later call will fail the same way.
  /// Without this the app kept the cached account, looked signed in, and
  /// showed an error on every screen until the citizen found Sign Out.
  ///
  /// Static, not per-instance, because [api] is swapped for a fake in tests
  /// and the listeners (CitizenSessionService, RequestsService, BalitaService)
  /// register once at construction.
  static final List<void Function()> _sessionExpiredListeners = [];

  static void addSessionExpiredListener(void Function() listener) => _sessionExpiredListeners.add(listener);

  static void removeSessionExpiredListener(void Function() listener) => _sessionExpiredListeners.remove(listener);

  /// Encodes one path segment (a reference number, a requirement key) so a
  /// value containing `/`, `?`, `#` or a space addresses the resource it
  /// names instead of a different route.
  static String segment(Object value) => Uri.encodeComponent(value.toString());

  final http.Client _http;
  final String baseUrl;

  static const _tokenKey = 'esperanza_api_token';

  String? _cachedToken;

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_tokenKey);
    } catch (_) {
      // Storage unavailable — the request just goes unauthenticated and the
      // server rejects it, same reasoning as the web client's own catch.
    }
    return _cachedToken;
  }

  Future<void> setToken(String? token) async {
    _cachedToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_tokenKey, token);
      }
    } catch (_) {
      // As above: a failed write here does not stop the token working for
      // the rest of this process's lifetime, only across restarts.
    }
  }

  Future<ApiResult> get(String path, {Map<String, dynamic>? query}) => _send('GET', path, query: query);

  Future<ApiResult> post(String path, {Map<String, dynamic>? body}) => _send('POST', path, body: body);

  Future<ApiResult> put(String path, {Map<String, dynamic>? body}) => _send('PUT', path, body: body);

  Future<ApiResult> delete(String path) => _send('DELETE', path);

  /// Follows a paginated collection to its end. A single `per_page` request
  /// silently truncated anything past the first page -- a citizen's 101st
  /// request simply never appeared. Reads Laravel's paginator `meta`
  /// (`App\Http\ApiResponse::page()`: `page`/`last_page`, with Laravel's own
  /// `current_page` also accepted); an endpoint that is not paginated returns
  /// no `meta` and is fetched exactly once. [maxPages] bounds a misbehaving
  /// server.
  Future<List<dynamic>> getAllPages(String path, {Map<String, dynamic>? query, int maxPages = 20}) async {
    final rows = <dynamic>[];
    var page = 1;
    while (true) {
      final res = await get(path, query: {...?query, if (page > 1) 'page': page});
      rows.addAll(res.list);
      final meta = res.meta;
      if (meta == null) break;
      final current = _intOf(meta['page']) ?? _intOf(meta['current_page']) ?? page;
      final last = _intOf(meta['last_page']);
      if (last == null || current >= last || res.list.isEmpty || page >= maxPages) break;
      page = current + 1;
    }
    return rows;
  }

  static int? _intOf(Object? v) => v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

  /// Multipart upload — real ID/requirement/attachment uploads (the app's
  /// `image_picker`/`file_picker` results), matching the backend's
  /// `App\Domain\Storage\UploadService`. `filePath` is a local path from
  /// either picker plugin.
  Future<ApiResult> postMultipart(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _headers(json: false));
    if (fields != null) request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    try {
      // Longer than a JSON call: a phone photo on a rural mobile connection
      // routinely takes more than 30s to upload.
      final streamed = await _http.send(request).timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);
      return _handle(response, path: path);
    } on TimeoutException {
      throw const ApiException(retryable: true, messageEn: 'The upload timed out.', messageFil: 'Nag-timeout ang pag-upload.');
    } on SocketException {
      throw const ApiException(retryable: true, messageEn: 'No internet connection.', messageFil: 'Walang koneksyon sa internet.');
    } on http.ClientException {
      throw const ApiException(retryable: true, messageEn: 'Could not reach the server.', messageFil: 'Hindi maabot ang server.');
    }
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final token = await getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<ApiResult> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      final params = query.map((k, v) => MapEntry(k, v?.toString() ?? ''))..removeWhere((k, v) => v.isEmpty);
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...params});
    }

    final headers = await _headers();

    try {
      final http.Response response;
      final encoded = body != null ? jsonEncode(body) : null;
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
        case 'POST':
          response = await _http.post(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 15));
        case 'PUT':
          response = await _http.put(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 15));
        case 'DELETE':
          response = await _http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
        default:
          throw ArgumentError('Unsupported method: $method');
      }
      return _handle(response, path: path);
    } on TimeoutException {
      throw const ApiException(retryable: true, messageEn: 'The request timed out.', messageFil: 'Nag-timeout ang kahilingan.');
    } on SocketException {
      throw const ApiException(retryable: true, messageEn: 'No internet connection.', messageFil: 'Walang koneksyon sa internet.');
    } on http.ClientException {
      throw const ApiException(retryable: true, messageEn: 'Could not reach the server.', messageFil: 'Hindi maabot ang server.');
    }
  }

  ApiResult _handle(http.Response response, {required String path}) {
    Map<String, dynamic>? decoded;
    if (response.body.isNotEmpty) {
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) decoded = parsed;
      } catch (_) {
        // A non-JSON body (an HTML 5xx page from in front of the app, a
        // proxy timeout page) falls through to the generic error below
        // rather than throwing a second, less useful exception.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final meta = decoded?['meta'];
      return ApiResult(data: decoded?['data'], meta: meta is Map<String, dynamic> ? meta : null);
    }

    // The envelope is `{"error": {...}}`, but anything that answers before
    // the app's own exception handler does -- Laravel's default 401/404/405/
    // 419/429 renderers, a validation failure outside the envelope -- replies
    // `{"message": "...", "errors": {...}}`. Reading both keeps the server's
    // own message on screen instead of the generic fallback.
    final errorRaw = decoded?['error'];
    final error = errorRaw is Map<String, dynamic> ? errorRaw : null;
    final message = error?['message'] ?? (errorRaw is String ? errorRaw : decoded?['message']);
    final fieldsRaw = error?['fields'] ?? decoded?['errors'];

    if (response.statusCode == 401 && !path.startsWith('/auth/')) {
      // Not for /auth/*: a 401 there is a wrong password or code, not an
      // expired session.
      for (final listener in List.of(_sessionExpiredListeners)) {
        listener();
      }
    }

    throw ApiException(
      status: response.statusCode,
      code: error?['code']?.toString(),
      messageFil: message is Map ? message['fil']?.toString() : (message is String ? message : null),
      messageEn: message is Map ? message['en']?.toString() : (message is String ? message : null),
      fields: fieldsRaw is Map
          ? fieldsRaw.map((k, v) => MapEntry(k.toString(), v is List ? v.map((e) => e.toString()).toList() : [v.toString()]))
          : const {},
      retryable: response.statusCode >= 500 || response.statusCode == 429,
    );
  }
}

/// One shared instance, exactly like the web client's default export — every
/// service in this app calls this rather than constructing its own.
///
/// Mutable (not `final`) so widget tests can swap in an [ApiClient] built on
/// `package:http/testing.dart`'s `MockClient` instead of hitting the real
/// network, then restore the real instance in `tearDown` — see
/// `test/support/fake_api.dart`. Production code never reassigns this.
ApiClient api = ApiClient();
