import '../models/document_preview.dart';
import 'api_client.dart';
import 'json_read.dart';

/// What staff set for each document in Settings > Templates (title, the
/// subtitle once edited, a note), from GET /document-templates, the same the
/// website's docTemplates store reads. Loaded once; if the server cannot be
/// reached the documents keep their built-in titles, as on the website.
class DocumentTemplatesService {
  DocumentTemplatesService._();

  static Map<String, DocumentTemplate>? _all;
  static Future<Map<String, DocumentTemplate>>? _loading;

  static Future<Map<String, DocumentTemplate>> load() {
    if (_all != null) return Future.value(_all);
    return _loading ??= () async {
      try {
        final res = await api.get('/document-templates');
        final out = <String, DocumentTemplate>{};
        for (final row in JsonRead.rows(res.list, (r) => r)) {
          final key = JsonRead.nonEmpty(row['doc_key']);
          if (key == null) continue;
          out[key] = DocumentTemplate(
            title: JsonRead.nonEmpty(row['cert_title']),
            subtitle: JsonRead.string(row['cert_subtitle']),
            note: JsonRead.nonEmpty(row['note']),
            version: JsonRead.integer(row['version']) ?? 1,
          );
        }
        return _all = out;
      } catch (_) {
        return const <String, DocumentTemplate>{};
      } finally {
        _loading = null;
      }
    }();
  }

  /// Tests only.
  static void reset() {
    _all = null;
    _loading = null;
  }
}
