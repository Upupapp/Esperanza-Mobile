import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../models/catalog_item.dart';
import '../models/service_request.dart';
import 'service_form_specs.dart';

/// Dokyu + Tulong: catalog, submission and tracking, against the real
/// backend (production-readiness programme, 2026-09-25). Previously a
/// local, frontend-only "database" persisted to SharedPreferences,
/// simulating every status change itself -- the server is now the only
/// source of truth for a request's own state, so nothing here is persisted
/// locally anymore; [loadRequests] re-fetches on demand instead.
///
/// Two real backend gaps were found and deliberately left unconverted
/// rather than guessed at (see PRODUCTION_READINESS.md's mobile section):
/// there is no endpoint for a citizen to attach requirement files at
/// submission time (only after a specific requirement is flagged for
/// replacement, via [replaceRequirement]), and receipt issuance is
/// admin-only, so no citizen payment/receipt flow exists to wire up. The
/// wizard's old Payment Method and Requirements-at-creation steps were
/// removed rather than kept pointed at nothing.
class RequestsService extends ChangeNotifier {
  List<ServiceRequest> _requests = [];
  List<CatalogItem> _dokyuCatalog = [];
  List<CatalogItem> _tulongCatalog = [];
  bool _loaded = false;

  List<ServiceRequest> get all => List.unmodifiable(_requests);

  List<ServiceRequest> byCategory(ServiceCategory category) =>
      _requests.where((r) => r.category == category).toList()..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  List<CatalogItem> get dokyuCatalog => List.unmodifiable(_dokyuCatalog);
  List<CatalogItem> get tulongCatalog => List.unmodifiable(_tulongCatalog);

  bool get loaded => _loaded;

  /// GET /services?type=dokyu|tulong (CatalogController::serialize()) --
  /// [ServiceFormSpecs] augments each real item with its locally-authored
  /// wizard question set, looked up by the same `key`.
  Future<void> loadCatalog() async {
    final results = await Future.wait([
      api.get('/services', query: {'type': 'dokyu'}),
      api.get('/services', query: {'type': 'tulong'}),
    ]);
    _dokyuCatalog = _parseCatalog(results[0].list);
    _tulongCatalog = _parseCatalog(results[1].list);
    notifyListeners();
  }

  List<CatalogItem> _parseCatalog(List<dynamic> raw) => raw.map((e) {
    final json = e as Map<String, dynamic>;
    final key = json['key'] as String? ?? '';
    return CatalogItem.fromApi(
      json,
      formSpec: ServiceFormSpecs.formSpecFor(key),
      demoDefaults: ServiceFormSpecs.demoDefaultsFor(key),
      demoPurpose: ServiceFormSpecs.demoPurposeFor(key),
      icon: ServiceFormSpecs.iconFor(key),
    );
  }).toList();

  /// GET /citizen/requests (CitizenRequestController::index()) -- a thinner
  /// shape than [ServiceRequest] (ref/type/service/status/submitted only);
  /// call [detail] for everything else once a specific request is opened.
  Future<void> loadRequests() async {
    _loaded = false;
    // Deferred, not synchronous: a caller kicking this off from a
    // StatefulWidget's initState (see AsyncStateView) is still inside
    // Flutter's build phase at this point, and a synchronous notifyListeners
    // here throws ("setState() or markNeedsBuild() called during build")
    // the moment a Provider ancestor is still being built too.
    scheduleMicrotask(notifyListeners);
    try {
      final res = await api.get('/citizen/requests', query: {'per_page': 100});
      _requests = res.list.map((e) => _requestFromSummary(e as Map<String, dynamic>)).toList();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// GET /citizen/requests/{ref} -- office, decision remarks, real per-
  /// requirement status, real flagged-requirement reasons, and the real
  /// transition history (backend commit 12f5e95). Updates the matching row
  /// in [_requests] in place, so a detail screen already open on this
  /// request via [all]/[byCategory] sees the fuller record immediately.
  Future<ServiceRequest> loadDetail(String ref) async {
    final res = await api.get('/citizen/requests/$ref');
    final full = _requestFromDetail(res.map);
    final idx = _requests.indexWhere((r) => r.referenceNumber == ref);
    if (idx != -1) {
      _requests[idx] = full;
    } else {
      _requests.add(full);
    }
    notifyListeners();
    return full;
  }

  ServiceRequest _requestFromSummary(Map<String, dynamic> json) {
    final ref = json['ref'] as String? ?? '';
    return ServiceRequest(
      id: ref,
      referenceNumber: ref,
      applicantId: '',
      applicantName: '',
      typeName: json['service'] as String? ?? '',
      category: _categoryFromType(json['type'] as String?),
      office: '',
      purpose: '',
      submittedAt: DateTime.tryParse(json['submitted'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'Submitted',
      statusHistory: const [],
      attachments: const [],
      expectedDays: '',
    );
  }

  ServiceRequest _requestFromDetail(Map<String, dynamic> json) {
    final ref = json['ref'] as String? ?? '';
    final history = (json['history'] as List? ?? [])
        .map(
          (t) => StatusHistoryEntry(
            status: (t as Map<String, dynamic>)['to'] as String? ?? '',
            at: DateTime.tryParse(t['at'] as String? ?? '') ?? DateTime.now(),
            actor: (t['actor_name'] as String?) ?? (t['trigger'] as String?) ?? 'System',
            remarks: null,
          ),
        )
        .toList();
    final needsCorrection = (json['needs_correction'] as List? ?? [])
        .map(
          (q) => FlaggedRequirement(
            id: (q as Map<String, dynamic>)['key'] as String? ?? '',
            requirementLabel: q['label'] as String? ?? '',
            reason: (q['remarks'] as String?) ?? (q['reason'] as String?) ?? '',
            flaggedAt: history.isNotEmpty ? history.last.at : DateTime.now(),
          ),
        )
        .toList();
    return ServiceRequest(
      id: ref,
      referenceNumber: ref,
      applicantId: '',
      applicantName: '',
      typeName: json['service'] as String? ?? '',
      category: _categoryFromType(json['type'] as String?),
      office: json['office'] as String? ?? '',
      purpose: '',
      submittedAt: DateTime.tryParse(json['submitted'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'Submitted',
      statusHistory: history,
      attachments: const [],
      adminRemarks: json['decision_remarks'] as String?,
      flaggedRequirements: needsCorrection,
      expectedDays: '',
    )..canResubmit = json['can_resubmit'] as bool? ?? false;
  }

  ServiceCategory _categoryFromType(String? type) => switch (type) {
    'dokyu' => ServiceCategory.dokyu,
    'tulong' => ServiceCategory.tulong,
    'sakuna' => ServiceCategory.sakunaIncident,
    _ => ServiceCategory.unknown,
  };

  /// POST /citizen/requests (CitizenRequestController::store()) --
  /// service_key + form_data only. No attachments (no submission-time
  /// upload endpoint exists) and no fee_inputs (the wizard doesn't collect
  /// per_bracket/schedule fee inputs today, see catalog_item.dart's own fee
  /// doc comment) are sent.
  Future<ServiceRequest> submit({required String serviceKey, required Map<String, dynamic> formData}) async {
    final res = await api.post('/citizen/requests', body: {'service_key': serviceKey, 'form_data': formData});
    final request = _requestFromDetail(res.map);
    _requests.insert(0, request);
    notifyListeners();
    return request;
  }

  /// POST /citizen/requests/{ref}/resubmit (RequestLifecycle::
  /// citizenResubmit()) -- real guard: only once every flagged requirement
  /// is resolved. Lands on Resubmitted, not back at Under Verification --
  /// the old local simulation re-entered at Under Verification directly,
  /// which was never the real vocabulary (see PRODUCTION_READINESS.md).
  Future<ServiceRequest> resubmit(String ref) async {
    final res = await api.post('/citizen/requests/$ref/resubmit');
    final request = _requestFromDetail(res.map);
    final idx = _requests.indexWhere((r) => r.referenceNumber == ref);
    if (idx != -1) _requests[idx] = request;
    notifyListeners();
    return request;
  }

  /// POST /citizen/requests/{ref}/requirements/{key}/replace (multipart) --
  /// the one real file-upload endpoint that exists, but only once that
  /// specific requirement has been flagged (`FlaggedRequirement.id` is the
  /// requirement's own `key`, see [_requestFromDetail]). Calling this
  /// before a requirement is flagged fails with the server's own
  /// NOT_FLAGGED error, surfaced as an ordinary ApiException.
  Future<ServiceRequest> replaceRequirement(String ref, {required String requirementKey, required String filePath}) async {
    final res = await api.postMultipart(
      '/citizen/requests/$ref/requirements/$requirementKey/replace',
      filePath: filePath,
      fileField: 'file',
    );
    final request = _requestFromDetail(res.map);
    final idx = _requests.indexWhere((r) => r.referenceNumber == ref);
    if (idx != -1) _requests[idx] = request;
    notifyListeners();
    return request;
  }

  /// In-memory only now -- there is nothing left to erase from disk once
  /// requests stopped being persisted to SharedPreferences. Called on
  /// sign-out so a shared/family handset never shows the previous
  /// citizen's request list for even a moment before the next sign-in's
  /// own [loadRequests] replaces it.
  void clear() {
    _requests = [];
    _loaded = false;
    notifyListeners();
  }
}
