import '../models/occasion_greeting.dart';
import 'api_client.dart';

/// Occasion-greeting pop-ups (2026-10-19). The server decides which one, if
/// any, is due for this resident - approval, its window, their barangay, and
/// how often it may show (once, once a day in Esperanza, or every time the
/// app opens) - so a phone's clock or a reinstall never brings back one that
/// is over or already seen.
class GreetingService {
  GreetingService._();

  /// The greeting to pop up now, or null - also when the server cannot be
  /// reached: a greeting is never worth an error in front of the resident.
  static Future<OccasionGreeting?> active() async {
    try {
      final res = await api.get('/citizen/greetings/active');
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
      await api.post('/citizen/greetings/$id/seen');
    } on ApiException {
      // Not recorded: it may show once more, which is harmless.
    }
  }
}
