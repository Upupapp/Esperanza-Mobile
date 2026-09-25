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
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      return _handle(response);
    } on TimeoutException {
      throw const ApiException(retryable: true, messageEn: 'The request timed out.', messageFil: 'Nag-timeout ang kahilingan.');
    } on SocketException {
      throw const ApiException(retryable: true, messageEn: 'No internet connection.', messageFil: 'Walang koneksyon sa internet.');
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
      return _handle(response);
    } on TimeoutException {
      throw const ApiException(retryable: true, messageEn: 'The request timed out.', messageFil: 'Nag-timeout ang kahilingan.');
    } on SocketException {
      throw const ApiException(retryable: true, messageEn: 'No internet connection.', messageFil: 'Walang koneksyon sa internet.');
    } on http.ClientException {
      throw const ApiException(retryable: true, messageEn: 'Could not reach the server.', messageFil: 'Hindi maabot ang server.');
    }
  }

  ApiResult _handle(http.Response response) {
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
      return ApiResult(data: decoded?['data'], meta: decoded?['meta'] as Map<String, dynamic>?);
    }

    final error = decoded?['error'] as Map<String, dynamic>?;
    final message = error?['message'];
    final fieldsRaw = error?['fields'] as Map<String, dynamic>?;

    throw ApiException(
      status: response.statusCode,
      code: error?['code'] as String?,
      messageFil: message is Map ? message['fil'] as String? : (message is String ? message : null),
      messageEn: message is Map ? message['en'] as String? : (message is String ? message : null),
      fields: fieldsRaw == null
          ? const {}
          : fieldsRaw.map((k, v) => MapEntry(k, v is List ? v.map((e) => e.toString()).toList() : [v.toString()])),
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
