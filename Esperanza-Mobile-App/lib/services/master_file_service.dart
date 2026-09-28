import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'json_read.dart';
import 'persistence_recovery.dart';
import '../models/attachment.dart';
import '../models/master_file_document.dart';

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
      final raw = prefs.getString(_key);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _byAccount = PersistenceRecovery.decodeEntries(
          map,
          (docs) => PersistenceRecovery.decodeEach(
            docs as List,
            (d) => MasterFileDocument.fromJson(d),
            what: 'master file document',
          ),
          what: 'master file account',
        );
      }
    } catch (error) {
      // A payload persisted by an earlier build can fail to decode after a
      // model or enum changes shape. Before this guard that throw escaped an
      // un-awaited future started in the constructor, so notifyListeners()
      // never fired and AuthGate spun on the splash forever - recoverable
      // only by clearing app data. Discard the unreadable state instead; the
      // migrations here already exist for exactly this class of change.
      _byAccount = {};
      await PersistenceRecovery.discardUnreadable(
        service: 'MasterFileService',
        keys: const [_key],
        error: error,
      );
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Erases [accountId]'s stored Master File documents from memory and from
  /// disk. Called on sign-out.
  Future<void> forgetAccount(String accountId) async {
    _byAccount.remove(accountId);
    await _persist();
    notifyListeners();
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
    var doc = MasterFileDocument(
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

    // Also keep it in the resident's Papeles wallet on the server, so it
    // survives a new phone. The local entry stands if the upload fails
    // (offline): reuse on this device still works, and the next save retries.
    final path = attachment.localPath;
    if (path != null && path.isNotEmpty) {
      try {
        final res = await api.postMultipart(
          '/citizen/papeles',
          filePath: path,
          fileField: 'file',
          fields: {'name': label, 'type': documentType, 'category': origin},
        );
        final remoteId = JsonRead.integer(res.map['id']);
        if (remoteId != null) {
          doc = MasterFileDocument(
            id: 'pap-$remoteId',
            documentType: documentType,
            label: label,
            attachment: attachment,
            uploadedAt: doc.uploadedAt,
            origin: origin,
            serviceName: serviceName,
          );
          _byAccount[accountId] = [...(_byAccount[accountId] ?? []).where((d) => d.documentType != documentType), doc];
          notifyListeners();
          await _persist();
        }
      } on ApiException {
        // See above.
      }
    }
    return doc;
  }

  /// GET /citizen/papeles -- the resident's document wallet on the server
  /// (esperanza-backend CitizenPortalController::papeles()). Server rows are
  /// authoritative; a local-only entry survives only for a document type the
  /// server does not hold yet (an upload that has not gone through).
  Future<void> syncFromServer(String accountId) async {
    final rows = await api.getAllPages('/citizen/papeles', query: {'per_page': 100}, maxPages: 5);
    final server = JsonRead.rows(rows, _fromPapeles);
    final serverTypes = server.map((d) => d.documentType).toSet();
    final local = (_byAccount[accountId] ?? const <MasterFileDocument>[])
        .where((d) => !d.id.startsWith('pap-') && !serverTypes.contains(d.documentType));
    // Keep the on-device file of a server row we uploaded from here, so it
    // can still be reused for a replacement upload.
    final localByType = {for (final d in _byAccount[accountId] ?? const <MasterFileDocument>[]) d.documentType: d};
    final merged = server.map((d) {
      final mine = localByType[d.documentType];
      if (mine == null || mine.attachment.localPath == null) return d;
      return MasterFileDocument(
        id: d.id,
        documentType: d.documentType,
        label: d.label,
        attachment: mine.attachment,
        uploadedAt: d.uploadedAt,
        origin: d.origin,
        serviceName: mine.serviceName,
      );
    });
    _byAccount[accountId] = [...merged, ...local];
    notifyListeners();
    await _persist();
  }

  /// A short-lived signed link to a server copy (GET .../{id}/download).
  Future<String?> downloadUrl(MasterFileDocument doc) async {
    final id = _remoteId(doc);
    if (id == null) return null;
    final res = await api.get('/citizen/papeles/$id/download');
    return JsonRead.nonEmpty(res.map['url']);
  }

  /// Archive, never delete: Papeles has no delete path by rule
  /// (POST .../{id}/archive). A local-only entry is simply dropped.
  Future<void> archive(String accountId, MasterFileDocument doc) async {
    final id = _remoteId(doc);
    if (id != null) await api.post('/citizen/papeles/$id/archive');
    _byAccount[accountId] = [...(_byAccount[accountId] ?? []).where((d) => d.id != doc.id)];
    notifyListeners();
    await _persist();
  }

  static int? _remoteId(MasterFileDocument doc) =>
      doc.id.startsWith('pap-') ? int.tryParse(doc.id.substring(4)) : null;

  /// papelesRow(): id/name/type/category/file_type/status/uploaded_at/bytes.
  static MasterFileDocument? _fromPapeles(Map<String, dynamic> json) {
    final id = JsonRead.integer(json['id']);
    if (id == null) return null;
    final name = JsonRead.nonEmpty(json['name']) ?? 'Document';
    final type = JsonRead.nonEmpty(json['type']) ?? name;
    final fileType = JsonRead.nonEmpty(json['file_type']) ?? '';
    final uploaded = JsonRead.date(json['uploaded_at'])?.toLocal() ?? DateTime.now();
    return MasterFileDocument(
      id: 'pap-$id',
      documentType: type,
      label: name,
      attachment: Attachment(
        id: 'pap-$id',
        fileName: fileType.isEmpty ? name : '$name.$fileType',
        category: AttachmentCategoryX.fromExtension(fileType),
        sizeBytes: JsonRead.integer(json['bytes']) ?? 0,
        addedAt: uploaded,
        documentTypeLabel: name,
      ),
      uploadedAt: uploaded,
      origin: JsonRead.nonEmpty(json['category']) ?? 'Papeles',
    );
  }
}
