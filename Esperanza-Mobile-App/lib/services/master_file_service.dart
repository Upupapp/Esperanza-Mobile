import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attachment.dart';
import '../models/master_file_document.dart';
import 'persistence_guard.dart';

/// Local, frontend-only "database" for the resident's Master File — same
/// persistence shape as ResidentProfileService/RequestsService: JSON to
/// SharedPreferences, keyed per citizen account. A document uploaded once
/// through any requirement uploader (see widgets/requirement_uploader.dart)
/// is saved here, so a later requirement asking for the same document type
/// — on the same service or a different one — can offer it for reuse
/// instead of forcing another upload.
class MasterFileService extends ChangeNotifier {
  static const _key = 'esperanza_master_file_documents';

  Map<String, List<MasterFileDocument>> _byAccount = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  MasterFileService() {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final decoded = await readJsonGuarded(prefs, _key);
      if (decoded is Map<String, dynamic>) {
        _byAccount = decodeEntriesGuarded(
          decoded,
          (docs) => decodeEachGuarded(
            docs as List,
            (d) => MasterFileDocument.fromJson(d),
            what: 'master file document',
          ),
          what: 'master file account',
        );
      }
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_byAccount.map((accountId, docs) => MapEntry(accountId, docs.map((d) => d.toJson()).toList()))),
    );
  }

  List<MasterFileDocument> documentsFor(String accountId) => List.unmodifiable(_byAccount[accountId] ?? const []);

  /// The resident's current document of [documentType], if any — at most
  /// one ever exists per (account, documentType), so there's never a list
  /// to choose from, only "reuse this" or "upload a new one" (see
  /// RequirementUploader).
  MasterFileDocument? findByType(String accountId, String documentType) {
    final docs = _byAccount[accountId];
    if (docs == null) return null;
    for (final d in docs) {
      if (d.documentType == documentType) return d;
    }
    return null;
  }

  /// Saves [attachment] as the resident's current document of
  /// [documentType] — replacing any prior entry of that same type (a newer
  /// upload supersedes the old one; see this model's own doc comment for
  /// why that never disturbs an already-submitted request). Never called
  /// for a reused document — reuse only ever copies an existing entry's
  /// `attachment` onto a new request locally, it doesn't touch this store.
  Future<MasterFileDocument> saveOrUpdate({
    required String accountId,
    required String documentType,
    required String label,
    required Attachment attachment,
    required String origin,
    String? serviceName,
  }) async {
    final existing = _byAccount[accountId] ?? [];
    final doc = MasterFileDocument(
      id: 'mfd-${DateTime.now().microsecondsSinceEpoch}',
      documentType: documentType,
      label: label,
      attachment: attachment,
      uploadedAt: DateTime.now(),
      origin: origin,
      serviceName: serviceName,
    );
    _byAccount[accountId] = [...existing.where((d) => d.documentType != documentType), doc];
    notifyListeners();
    await _persist();
    return doc;
  }
}
