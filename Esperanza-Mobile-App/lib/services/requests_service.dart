import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attachment.dart';
import '../models/service_request.dart';

/// Local, frontend-only "database" for Dokyu + Tulong requests. Persists to
/// SharedPreferences as JSON so submissions survive app restarts during the
/// demo. This is intentionally the ONLY place that touches storage for
/// requests — screens call submit()/advanceStatus() and never read/write
/// SharedPreferences directly, so swapping this for real HTTP calls later
/// (once the backend developer builds the API — see MISSING Web Admin
/// processes in ESPERANZA_MOBILE_WEB_ALIGNMENT.md) only touches this file.
class RequestsService extends ChangeNotifier {
  static const _key = 'esperanza_service_requests';

  final List<ServiceRequest> _requests = [];
  bool _loaded = false;

  List<ServiceRequest> get all => List.unmodifiable(_requests);

  List<ServiceRequest> byCategory(ServiceCategory category) =>
      _requests.where((r) => r.category == category).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  RequestsService() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).map((e) => ServiceRequest.fromJson(e)).toList();
      _requests.addAll(list);
    }
    _loaded = true;
    notifyListeners();
  }

  bool get loaded => _loaded;

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_requests.map((r) => r.toJson()).toList()));
  }

  String _generateReference(ServiceCategory category) {
    final prefix = switch (category) {
      ServiceCategory.dokyu => 'DR',
      ServiceCategory.tulong => 'AR',
      ServiceCategory.sakunaIncident => 'IR',
    };
    final year = DateTime.now().year;
    final seq = (_requests.where((r) => r.category == category).length + 1).toString().padLeft(4, '0');
    return '$prefix-$year-$seq';
  }

  /// Citizen submits a new request — the mobile-side half of the "Mobile
  /// Action -> Web Admin Destination" flow documented per-process in the
  /// alignment doc. Starts at "Submitted"; a citizen-only initial status
  /// history entry is recorded immediately.
  Future<ServiceRequest> submit({
    required String applicantId,
    required String applicantName,
    required String typeName,
    required ServiceCategory category,
    required String office,
    required String purpose,
    required String expectedDays,
    required List<Attachment> attachments,
    Map<String, dynamic> formFields = const {},
  }) async {
    final now = DateTime.now();
    final request = ServiceRequest(
      id: 'req-${now.microsecondsSinceEpoch}',
      referenceNumber: _generateReference(category),
      applicantId: applicantId,
      applicantName: applicantName,
      typeName: typeName,
      category: category,
      office: office,
      purpose: purpose,
      submittedAt: now,
      status: 'Submitted',
      statusHistory: [
        StatusHistoryEntry(status: 'Submitted', at: now, actor: 'Citizen', remarks: 'Request submitted via mobile app.'),
      ],
      attachments: attachments,
      expectedDays: expectedDays,
      formFields: formFields,
    );
    _requests.add(request);
    await _persist();
    notifyListeners();
    return request;
  }

  /// DEMO-ONLY: simulates what a Web Admin staff member would do on the
  /// admin side (Review -> Approve/Reject/Request Additional Requirements
  /// -> Release), so the full citizen <-> admin loop can be seen end-to-end
  /// inside this frontend-only build even though no real Web Admin
  /// connection exists yet. Screens must clearly label this as a demo
  /// control, never presented as if a real admin acted.
  Future<void> simulateAdminUpdate(
    String requestId, {
    required String newStatus,
    required String actorRole,
    String? remarks,
  }) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = newStatus;
    request.adminRemarks = remarks;
    request.statusHistory.add(
      StatusHistoryEntry(status: newStatus, at: DateTime.now(), actor: actorRole, remarks: remarks),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> cancel(String requestId) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = 'Cancelled';
    request.statusHistory.add(
      StatusHistoryEntry(status: 'Cancelled', at: DateTime.now(), actor: 'Citizen', remarks: 'Cancelled by citizen.'),
    );
    await _persist();
    notifyListeners();
  }
}
