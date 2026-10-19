import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// The two ways a resident tells the LGU how it went (parity with the
/// website, 2026-10-15): a rating of a finished request (POST
/// /citizen/surveys, ReportController::submitSurvey - once per request) and
/// "Was this helpful?" on a help article (POST /citizen/help/feedback).
///
/// What this phone already answered is remembered on it, as the website
/// remembers it in the browser, so the same question is not asked twice.
class FeedbackService {
  FeedbackService._();

  static const _surveysKey = 'esperanza_surveys';
  static const _helpKey = 'esperanza_help_votes';

  /// The 1-5 scale's words, as on the website.
  static const ratingLabels = {1: 'Very poor', 2: 'Poor', 3: 'Fair', 4: 'Good', 5: 'Excellent'};

  static Future<Map<String, dynamic>> _read(String key) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      final decoded = raw == null ? null : jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<void> _put(String key, String id, Object value) async {
    try {
      final map = await _read(key);
      map[id] = value;
      await (await SharedPreferences.getInstance()).setString(key, jsonEncode(map));
    } catch (_) {
      // Only a convenience: at worst the question is asked again.
    }
  }

  /// Whether this request's survey was answered or skipped on this phone.
  static Future<bool> surveySettled(String ref) async => (await _read(_surveysKey)).containsKey(ref);

  static Future<void> skipSurvey(String ref) => _put(_surveysKey, ref, 'skipped');

  /// Sends the rating. Already answered (from another device), or not yet
  /// finished: settled quietly, nothing to show. Any other failure throws.
  static Future<void> rate(String ref, int rating, String comment) async {
    try {
      await api.post(
        '/citizen/surveys',
        body: {'ref': ref, 'rating': rating, 'comment': comment.trim().isEmpty ? null : comment.trim()},
      );
      await _put(_surveysKey, ref, 'sent');
    } on ApiException catch (e) {
      if (e.code == 'ALREADY_SUBMITTED' || e.status == 409) {
        await _put(_surveysKey, ref, 'already');
        return;
      }
      if (e.code == 'REQUEST_NOT_FINISHED') return;
      rethrow;
    }
  }

  /// This phone's earlier answer to "Was this helpful?" for [item], if any.
  static Future<bool?> helpVote(String docKey, String item) async {
    final v = (await _read(_helpKey))['$docKey|$item'];
    return v is bool ? v : null;
  }

  /// Records the answer; the server keeps one per resident and item, so a
  /// change of mind replaces it.
  static Future<void> voteHelp(String docKey, String item, bool helpful) async {
    await api.post('/citizen/help/feedback', body: {'doc_key': docKey, 'item': item, 'helpful': helpful});
    await _put(_helpKey, '$docKey|$item', helpful);
  }
}
