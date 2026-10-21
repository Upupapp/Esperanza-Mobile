import '../models/occasion_greeting.dart';
import 'api_client.dart';

/// Occasion pop-ups (2026-10-19; their own server feature since 2026-10-21).
/// The server decides which one, if any, is due for this resident - its
/// audience, its window, how often it may show (once, once a day in
/// Esperanza, or every time the app opens), whether it was put away, and the
/// resident's birthday - so a phone's clock or a reinstall never brings back
/// one that is over or already seen.
class GreetingService {
  GreetingService._();

  static String _path(int id, String action) => '/citizen/popups/${ApiClient.segment(id)}/$action';

  /// The pop-up to show now, or null - also when the server cannot be
  /// reached: a greeting is never worth an error in front of the resident.
  static Future<OccasionGreeting?> active() async {
    try {
      final res = await api.get('/citizen/popups/active');
      final data = res.data;
      return data is Map<String, dynamic> ? OccasionGreeting.fromApi(data) : null;
    } on ApiException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Records that [id] was shown, so its frequency is kept. Sent when it is
  /// shown rather than when it is closed, as the website does: an app closed
  /// with the pop-up still open has still shown it.
  static Future<void> markSeen(int id) async {
    try {
      await api.post(_path(id, 'seen'));
    } on ApiException {
      // Not recorded (or already over): it may show once more, which is harmless.
    }
  }

  /// "Huwag nang ipakita": [id] is not shown again this occurrence.
  static Future<void> dismiss(int id) async {
    try {
      await api.post(_path(id, 'dismiss'));
    } on ApiException {
      // Not recorded: it may show again, and can be put away again.
    }
  }
}
