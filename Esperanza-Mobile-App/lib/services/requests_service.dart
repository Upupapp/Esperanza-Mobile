import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'json_read.dart';
import '../models/attachment.dart';
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

  /// Citizen-reported Sakuna incidents. A separate backend resource
  /// (GET/POST /citizen/incidents, `INC-YYYY-#####` refs) with no detail,
  /// resubmit or requirement endpoints, so it is kept apart from
  /// [_requests] and only merged for display.
  List<ServiceRequest> _incidents = [];

  List<ServiceRequest> get all => List.unmodifiable([..._requests, ..._incidents]);

  List<ServiceRequest> byCategory(ServiceCategory category) =>
      all.where((r) => r.category == category).toList()..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  List<CatalogItem> get dokyuCatalog => List.unmodifiable(_dokyuCatalog);
  List<CatalogItem> get tulongCatalog => List.unmodifiable(_tulongCatalog);

  bool get loaded => _loaded;

  RequestsService() {
    ApiClient.addSessionExpiredListener(clear);
  }

  @override
  void dispose() {
    ApiClient.removeSessionExpiredListener(clear);
    super.dispose();
  }

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

  List<CatalogItem> _parseCatalog(List<dynamic> raw) => JsonRead.rows(raw, (json) {
    final key = JsonRead.nonEmpty(json['key']);
    // A service with no key cannot be submitted (POST /citizen/requests
    // takes service_key), so it is not offered at all.
    if (key == null) return null;
    return CatalogItem.fromApi(
      json,
      formSpec: ServiceFormSpecs.formSpecFor(key),
      demoDefaults: ServiceFormSpecs.demoDefaultsFor(key),
      demoPurpose: ServiceFormSpecs.demoPurposeFor(key),
      icon: ServiceFormSpecs.iconFor(key),
    );
  });

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
      final rows = await api.getAllPages('/citizen/requests', query: {'per_page': 100});
      _requests = JsonRead.rows(rows, (json) => JsonRead.nonEmpty(json['ref']) == null ? null : _requestFromSummary(json));
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
    // B-052: GET /citizen/incidents/{ref} now exists -- description, sitio
    // and a real timeline, not just the list row. Still routed off the ref
    // prefix rather than a server round-trip: an INC- ref was never going
    // to resolve against /citizen/requests/{ref} anyway.
    if (ref.startsWith('INC-')) {
      final res = await api.get('/citizen/incidents/${ApiClient.segment(ref)}');
      final full = _incidentDetailFrom(res.map);
      final idx = _incidents.indexWhere((i) => i.referenceNumber == ref);
      if (idx != -1) {
        _incidents[idx] = full;
      } else {
        _incidents.add(full);
      }
      notifyListeners();
      return full;
    }
    final res = await api.get('/citizen/requests/${ApiClient.segment(ref)}');
    _requireRef(res);
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

  /// GET /citizen/incidents (CitizenRequestController::incidents()) -- the
  /// citizen's own reports, newest first.
  Future<void> loadIncidents() async {
    final rows = await api.getAllPages('/citizen/incidents', query: {'per_page': 100});
    _incidents = JsonRead.rows(rows, (json) => JsonRead.nonEmpty(json['ref']) == null ? null : _incidentFrom(json));
    notifyListeners();
  }

  /// POST /citizen/incidents (CitizenRequestController::reportIncident()).
  /// Open to unverified citizens by design. [clientUuid] makes a retry after
  /// a dropped connection return the incident already filed (200) instead of
  /// filing a second one (201), so the caller must reuse it across retries of
  /// the same report. [barangay] must be one of the backend's canonical
  /// barangays (validated with `exists:barangays,name`).
  Future<ServiceRequest> reportIncident({
    required String type,
    required String title,
    required String severity,
    required String barangay,
    String? sitio,
    String? description,
    required String clientUuid,
  }) async {
    final res = await api.post(
      '/citizen/incidents',
      body: {
        'type': type,
        'title': title,
        'severity': severity,
        'barangay': barangay,
        if (sitio != null && sitio.trim().isNotEmpty) 'sitio': sitio.trim(),
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        'client_uuid': clientUuid,
      },
    );
    _requireRef(res);
    final incident = _incidentFrom(res.map);
    _incidents = [incident, ..._incidents.where((i) => i.referenceNumber != incident.referenceNumber)];
    notifyListeners();
    return incident;
  }

  /// B-052: GET /citizen/incidents/{ref}'s fuller shape -- adds description,
  /// sitio and a real timeline on top of what [_incidentFrom] reads from the
  /// list row. The timeline is already citizen-safe server-side (verb and
  /// when, never the staff note or who acted), so no field here needs
  /// hiding; 'actor' is a fixed label because the server does not send one.
  ServiceRequest _incidentDetailFrom(Map<String, dynamic> json) {
    final base = _incidentFrom(json);
    final severity = JsonRead.nonEmpty(json['severity']);
    final description = JsonRead.nonEmpty(json['description']);
    final sitio = JsonRead.nonEmpty(json['sitio']);
    final timeline = JsonRead.list(json['timeline']);
    return ServiceRequest(
      id: base.id,
      referenceNumber: base.referenceNumber,
      applicantId: base.applicantId,
      applicantName: base.applicantName,
      typeName: base.typeName,
      category: base.category,
      // Reuses the slot the type name's own subtitle already renders
      // (RequestDetailScreen shows `request.office` right under the title),
      // rather than adding a new one just for this category.
      office: [
        JsonRead.nonEmpty(json['barangay']),
        if (sitio != null) 'Sitio $sitio',
      ].whereType<String>().join(' · '),
      // RequestDetailScreen renders this as the incident's one free-text
      // block (see its `usesMilestones` branch) -- severity stays visible
      // here too, not only in the list row's own copy, which this replaces.
      purpose: [
        if (severity != null) 'Severity: $severity',
        description,
      ].whereType<String>().join('\n\n'),
      submittedAt: base.submittedAt,
      status: base.status,
      statusHistory: JsonRead.rows(timeline, (row) {
        final status = JsonRead.nonEmpty(row['status']);
        final at = JsonRead.date(row['at']);
        if (status == null || at == null) return null;
        return StatusHistoryEntry(status: status, at: at, actor: 'Esperanza LGU');
      }),
      attachments: const [],
      expectedDays: base.expectedDays,
    );
  }

  /// incident(): ref/title/type/severity/barangay/status/source/reported.
  /// Statuses are the canonical vocabulary (IncidentLifecycle: Submitted,
  /// Under Verification, Assigned, Processing, Completed, Archived).
  ServiceRequest _incidentFrom(Map<String, dynamic> json) {
    final ref = JsonRead.nonEmpty(json['ref']) ?? '';
    final severity = JsonRead.nonEmpty(json['severity']);
    final barangay = JsonRead.nonEmpty(json['barangay']);
    return ServiceRequest(
      id: ref,
      referenceNumber: ref,
      applicantId: '',
      applicantName: '',
      typeName: JsonRead.nonEmpty(json['type']) ?? JsonRead.nonEmpty(json['title']) ?? 'Incident',
      category: ServiceCategory.sakunaIncident,
      office: '',
      purpose: [
        JsonRead.nonEmpty(json['title']),
        if (severity != null) 'Severity: $severity',
        if (barangay != null) 'Barangay $barangay',
      ].whereType<String>().join(' · '),
      submittedAt: JsonRead.date(json['reported']) ?? DateTime.now(),
      status: JsonRead.nonEmpty(json['status']) ?? 'Submitted',
      statusHistory: const [],
      attachments: const [],
      expectedDays: '',
    );
  }

  /// A 2xx whose body carries no reference number is not a request the
  /// citizen can track, open, or resubmit -- surfaced as an error rather
  /// than inserted as a blank row that every later call would 404 on.
  void _requireRef(ApiResult res) {
    if (JsonRead.nonEmpty(res.map['ref']) == null) {
      throw const ApiException(
        messageEn: 'The server response was incomplete. Please refresh and try again.',
        messageFil: 'Kulang ang tugon ng server. I-refresh at subukang muli.',
      );
    }
  }

  ServiceRequest _requestFromSummary(Map<String, dynamic> json) {
    final ref = JsonRead.nonEmpty(json['ref']) ?? '';
    return ServiceRequest(
      id: ref,
      referenceNumber: ref,
      applicantId: '',
      applicantName: '',
      typeName: JsonRead.string(json['service']) ?? '',
      category: _categoryFromType(JsonRead.string(json['type'])),
      office: JsonRead.string(json['office']) ?? '',
      purpose: '',
      submittedAt: JsonRead.date(json['submitted']) ?? DateTime.now(),
      status: JsonRead.nonEmpty(json['status']) ?? 'Submitted',
      statusHistory: const [],
      attachments: const [],
      expectedDays: '',
    );
  }

  ServiceRequest _requestFromDetail(Map<String, dynamic> json) {
    final ref = JsonRead.nonEmpty(json['ref']) ?? '';
    final recorded = JsonRead.rows(json['history'], (t) {
      final to = JsonRead.nonEmpty(t['to']);
      if (to == null) return null;
      return StatusHistoryEntry(
        status: to,
        at: JsonRead.date(t['at']) ?? DateTime.now(),
        actor: JsonRead.nonEmpty(t['actor_name']) ?? JsonRead.nonEmpty(t['trigger']) ?? 'System',
        // The history rows carry no remarks (CitizenRequestController::
        // detail(): from/to/trigger/actor_name/at); the clerk's words arrive
        // as decision_remarks and per-requirement remarks instead.
        remarks: null,
      );
    });
    // Filing is not a transition on the server (a request is created
    // Submitted), so the history starts at the first change: a new request
    // read "No history recorded yet", and the correction and rejection views
    // began at Initial Screening. The filing step comes from the request.
    final filedAt = JsonRead.date(json['submitted']);
    final history = [
      if (filedAt != null && !recorded.any((h) => h.status == 'Submitted'))
        StatusHistoryEntry(status: 'Submitted', at: filedAt, actor: 'Citizen'),
      ...recorded,
    ];
    final needsCorrection = JsonRead.rows(json['needs_correction'], (q) {
      final key = JsonRead.nonEmpty(q['key']);
      // The key addresses the replace endpoint; without it there is nothing
      // the citizen could upload against.
      if (key == null) return null;
      final at = history.isNotEmpty ? history.last.at : DateTime.now();
      return FlaggedRequirement(
        id: key,
        requirementLabel: JsonRead.string(q['label']) ?? key,
        reason: JsonRead.nonEmpty(q['remarks']) ?? JsonRead.nonEmpty(q['reason']) ?? '',
        flaggedAt: at,
        // Already replaced while the request still waits on the resident: it
        // stays on the list (with Resubmit) and reads as done. Before the
        // server said so, the list emptied and the app lost its Resubmit.
        resolvedAt: JsonRead.boolean(q['resolved']) == true ? at : null,
      );
    });
    // Each requirement's file as the server holds it, so the detail shows what
    // was actually attached (it showed nothing: attachments was always empty).
    final files = JsonRead.rows(json['requirements'], (q) {
      final file = JsonRead.map(q['file']);
      final name = file == null ? null : JsonRead.nonEmpty(file['name']);
      if (file == null || name == null) return null;
      return Attachment(
        id: JsonRead.nonEmpty(q['key']) ?? name,
        fileName: name,
        category: AttachmentCategoryX.fromExtension(name.contains('.') ? name.split('.').last : ''),
        sizeBytes: JsonRead.integer(file['bytes']) ?? 0,
        remoteUrl: JsonRead.nonEmpty(file['url']),
        addedAt: JsonRead.date(file['uploaded_at']) ?? DateTime.now(),
        documentTypeLabel: JsonRead.string(q['label']) ?? name,
      );
    });
    final attachable = JsonRead.rows(json['requirements'], (q) {
      final key = JsonRead.nonEmpty(q['key']);
      if (key == null || JsonRead.boolean(q['attachable']) != true) return null;
      return PendingRequirement(key: key, label: JsonRead.string(q['label']) ?? key);
    });
    final missingRequired = JsonRead.rows(json['missing_required'], (q) {
      final key = JsonRead.nonEmpty(q['key']);
      if (key == null) return null;
      return PendingRequirement(key: key, label: JsonRead.string(q['label']) ?? key);
    });
    return ServiceRequest(
      id: ref,
      referenceNumber: ref,
      applicantId: '',
      applicantName: '',
      typeName: JsonRead.string(json['service']) ?? '',
      category: _categoryFromType(JsonRead.string(json['type'])),
      office: JsonRead.string(json['office']) ?? '',
      purpose: '',
      submittedAt: JsonRead.date(json['submitted']) ?? DateTime.now(),
      status: JsonRead.nonEmpty(json['status']) ?? 'Submitted',
      statusHistory: history,
      attachments: files,
      adminRemarks: JsonRead.nonEmpty(json['decision_remarks']),
      flaggedRequirements: needsCorrection,
      expectedDays: '',
    )
      ..canResubmit = JsonRead.boolean(json['can_resubmit']) ?? false
      ..attachableRequirements = attachable
      ..missingRequired = missingRequired
      ..assistance = _assistanceFrom(JsonRead.map(json['assistance']), JsonRead.nonEmpty(json['office']))
      ..payment = _paymentFrom(JsonRead.map(json['payment']));
  }

  /// A detail's `payment` (DescribesPayment): amount, status, receipt_no.
  RequestPayment? _paymentFrom(Map<String, dynamic>? json) {
    if (json == null) return null;
    final amount = num.tryParse('${json['amount']}')?.toDouble() ?? 0;
    return RequestPayment(
      amount: amount,
      status: JsonRead.nonEmpty(json['status']) ?? 'Pending Review',
      receiptNo: JsonRead.nonEmpty(json['receipt_no']),
    );
  }

  /// A Tulong detail's `assistance` (CitizenRequestController::detail()).
  TulongAssistance? _assistanceFrom(Map<String, dynamic>? json, String? office) {
    if (json == null) return null;
    return TulongAssistance(
      approvedAmount: JsonRead.nonEmpty(json['approved_amount']),
      releasedAmount: JsonRead.nonEmpty(json['released_amount']),
      releaseReference: JsonRead.nonEmpty(json['release_reference']),
      releasedAt: JsonRead.date(json['released_at']),
      office: office,
    );
  }

  ServiceCategory _categoryFromType(String? type) => switch (type) {
    'dokyu' => ServiceCategory.dokyu,
    'tulong' => ServiceCategory.tulong,
    'sakuna' => ServiceCategory.sakunaIncident,
    _ => ServiceCategory.unknown,
  };

  /// POST /citizen/requests (CitizenRequestController::store()) --
  /// service_key + form_data, plus `fee_inputs` when the service's fee is
  /// assessed on a declared amount ([CatalogItem.feeInputs]; the server
  /// refuses the filing without them). No attachments: no submission-time
  /// upload endpoint exists.
  Future<ServiceRequest> submit({
    required String serviceKey,
    required Map<String, dynamic> formData,
    Map<String, num> feeInputs = const {},
  }) async {
    final res = await api.post(
      '/citizen/requests',
      body: {'service_key': serviceKey, 'form_data': formData, if (feeInputs.isNotEmpty) 'fee_inputs': feeInputs},
    );
    _requireRef(res);
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
    final res = await api.post('/citizen/requests/${ApiClient.segment(ref)}/resubmit');
    _requireRef(res);
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
  Future<ServiceRequest> replaceRequirement(String ref, {required String requirementKey, required String filePath}) =>
      _uploadRequirement(ref, requirementKey, filePath, 'replace');

  /// POST /citizen/requests/{ref}/requirements/{key}/attach (multipart) --
  /// the document for a requirement the office has not decided yet, while the
  /// request is Submitted, Under Verification, Under Review or Resubmitted
  /// ([PendingRequirement]). Attaching again keeps the earlier file in that
  /// requirement's history; a decided requirement is refused (409), and is
  /// corrected through [replaceRequirement] once flagged.
  Future<ServiceRequest> attachRequirement(String ref, {required String requirementKey, required String filePath}) =>
      _uploadRequirement(ref, requirementKey, filePath, 'attach');

  Future<ServiceRequest> _uploadRequirement(String ref, String requirementKey, String filePath, String action) async {
    final res = await api.postMultipart(
      '/citizen/requests/${ApiClient.segment(ref)}/requirements/${ApiClient.segment(requirementKey)}/$action',
      filePath: filePath,
      fileField: 'file',
    );
    _requireRef(res);
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
    _incidents = [];
    _loaded = false;
    notifyListeners();
  }
}
