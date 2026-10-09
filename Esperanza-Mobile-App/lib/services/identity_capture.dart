import 'package:didit_sdk/sdk_flutter.dart';

import '../models/id_verification.dart';
import 'api_client.dart';
import 'json_read.dart';

/// How the SDK ended, as far as the app is concerned. The OUTCOME of the
/// check is never taken from here: the server reads it from Didit.
enum DiditLaunchOutcome { completed, cancelled, failed }

class DiditLaunchResult {
  final DiditLaunchOutcome outcome;

  /// Why it failed (e.g. cameraAccessDenied, networkError), for the message.
  final String? error;

  const DiditLaunchResult(this.outcome, [this.error]);
}

/// Opens Didit's capture screen for a session token.
typedef DiditLauncher = Future<DiditLaunchResult> Function(String sessionToken);

/// Identity checks captured on Didit's own screen (owner ruling, 2026-10-09:
/// Didit's free tier covers its hosted flow only; esperanza-backend
/// HostedIdentityChecks).
///
/// 1. [mode] - the server says where the ID and selfie are captured
///    (GET /portal-settings `identity_capture`): `hosted` (Didit's screen,
///    after the account exists) or `own` (the app's ID and selfie steps).
/// 2. [verifyOnDidit] - POST /citizen/verification/session opens a session,
///    Didit's SDK runs the ID scan and face check, then
///    POST .../session/{id}/sync has the server READ the result from Didit.
///    Whatever the SDK says, the result shown is the server's.
class IdentityCapture {
  IdentityCapture._();

  /// Replaced in tests: the real one is native code.
  static DiditLauncher launcher = _sdkLauncher;

  static const hosted = 'hosted';
  static const own = 'own';

  /// The capture mode. Unknown (offline, an older server) is `own`: the
  /// app's own steps work against either server, Didit's screen does not.
  static Future<String> mode() async {
    try {
      final result = await api.get('/portal-settings');
      return JsonRead.string(result.map['identity_capture']) == hosted ? hosted : own;
    } on ApiException {
      return own;
    }
  }

  /// Opens Didit's screen and returns the server's view afterwards, or null
  /// when the resident closed Didit's screen before finishing (nothing to
  /// read). Throws [ApiException] when the session cannot be opened.
  static Future<({IdVerificationView? view, DiditLaunchResult launch})> verifyOnDidit() async {
    final opened = await api.post('/citizen/verification/session', body: {'platform': 'app'});
    final token = JsonRead.nonEmpty(opened.map['session_token']);
    final sessionId = JsonRead.nonEmpty(opened.map['session_id']);
    if (token == null || sessionId == null) {
      throw const ApiException(
        messageEn: 'Identity verification could not be started. Please try again.',
        messageFil: 'Hindi masimulan ang beripikasyon. Pakisubukang muli.',
      );
    }

    final launch = await launcher(token);
    if (launch.outcome == DiditLaunchOutcome.cancelled) {
      return (view: null, launch: launch);
    }
    // Completed - or failed mid-way, which Didit may still have recorded:
    // either way the server reads what Didit actually holds.
    final synced = await api.post('/citizen/verification/session/${ApiClient.segment(sessionId)}/sync');
    return (view: IdVerificationView.fromApi(synced.data), launch: launch);
  }
}

Future<DiditLaunchResult> _sdkLauncher(String token) async {
  final result = await DiditSdk.startVerification(
    token,
    config: const DiditConfig(languageCode: 'en', showCloseButton: true, closeOnComplete: true),
  );
  return switch (result) {
    VerificationCompleted() => const DiditLaunchResult(DiditLaunchOutcome.completed),
    VerificationCancelled() => const DiditLaunchResult(DiditLaunchOutcome.cancelled),
    VerificationFailed(:final error) => DiditLaunchResult(DiditLaunchOutcome.failed, error.type.name),
  };
}
