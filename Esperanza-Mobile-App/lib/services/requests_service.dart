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

  /// Defaults to true for real app usage (see
  /// _seedDemoStatusSimulationsIfNeeded's own doc comment) — tests that
  /// need a pristine/empty or precisely-countable request list pass false
  /// to opt out.
  final bool seedDemoData;

  List<ServiceRequest> get all => List.unmodifiable(_requests);

  List<ServiceRequest> byCategory(ServiceCategory category) =>
      _requests.where((r) => r.category == category).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  RequestsService({this.seedDemoData = true}) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).map((e) => ServiceRequest.fromJson(e)).toList();
      _requests.addAll(list);
    }
    if (seedDemoData) await _seedDemoStatusSimulationsIfNeeded();
    _loaded = true;
    notifyListeners();
  }

  /// Pre-made Dokyu/Tulong requests covering the three primary statuses
  /// (Pending Review, Approved, Rejected) so the client can see what each
  /// looks like — request list tile, request detail, and the matching
  /// notification (via the same statusHistory-derived feed every other
  /// request notification already comes from, see notification_feed.dart)
  /// — without submitting anything first. Seeded exactly once, guarded by
  /// [_demoSeedIds] already being present, so relaunching the app or a
  /// hot-reload never re-adds or duplicates them, and any requests the
  /// citizen has actually submitted are never touched. "Pending" in the
  /// task sense maps to this app's real, existing "Pending Review" status
  /// (see AppStatus) rather than inventing a new label — the universal
  /// status system's exact 14 names are shared verbatim with the Web
  /// Admin and must never gain a duplicate/ambiguous one.
  static const _demoSeedIds = [
    'demo-dokyu-barangay-clearance',
    'demo-dokyu-business-permit',
    'demo-dokyu-certificate-indigency',
    'demo-tulong-medical',
    'demo-tulong-financial',
    'demo-tulong-educational',
  ];

  Future<void> _seedDemoStatusSimulationsIfNeeded() async {
    if (_requests.any((r) => _demoSeedIds.contains(r.id))) return;

    const applicantId = 'ESP-RES-2024-1203'; // Marites Ferrer — verified, has Dokyu/Tulong access.
    const applicantName = 'Marites Ferrer';
    final now = DateTime.now();
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    ServiceRequest demo({
      required String id,
      required String refSuffix,
      required String typeName,
      required ServiceCategory category,
      required String office,
      required String expectedDays,
      required String purpose,
      required String finalStatus,
      required String actorRole,
      required String remarks,
    }) {
      final submittedAt = daysAgo(5);
      return ServiceRequest(
        id: id,
        referenceNumber: '${category == ServiceCategory.dokyu ? 'DR' : 'AR'}-${now.year}-DEMO$refSuffix',
        applicantId: applicantId,
        applicantName: applicantName,
        typeName: typeName,
        category: category,
        office: office,
        purpose: purpose,
        submittedAt: submittedAt,
        status: finalStatus,
        statusHistory: [
          StatusHistoryEntry(status: 'Submitted', at: submittedAt, actor: 'Citizen', remarks: 'Request submitted via mobile app.'),
          StatusHistoryEntry(status: finalStatus, at: daysAgo(1), actor: actorRole, remarks: remarks),
        ],
        attachments: const [],
        expectedDays: expectedDays,
      );
    }

    _requests.addAll([
      demo(
        id: 'demo-dokyu-barangay-clearance',
        refSuffix: '01',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        expectedDays: '1-2 working days',
        purpose: 'Proof of Residency',
        finalStatus: 'Approved',
        actorRole: 'Barangay Staff',
        remarks: 'Your Barangay Clearance request has been approved.',
      ),
      demo(
        id: 'demo-dokyu-business-permit',
        refSuffix: '02',
        typeName: 'Business Permit (New Application)',
        category: ServiceCategory.dokyu,
        office: 'BPLO',
        expectedDays: '7 working days',
        purpose: 'New business registration',
        finalStatus: 'Pending Review',
        actorRole: 'BPLO Staff',
        remarks: 'Your Business Permit request is still pending.',
      ),
      demo(
        id: 'demo-dokyu-certificate-indigency',
        refSuffix: '03',
        typeName: 'Certificate of Indigency',
        category: ServiceCategory.dokyu,
        office: 'MSWDO',
        expectedDays: '2-3 working days',
        purpose: 'Medical Assistance',
        finalStatus: 'Rejected',
        actorRole: 'MSWDO Staff',
        remarks: 'Your Certificate of Indigency request was rejected.',
      ),
      demo(
        id: 'demo-tulong-medical',
        refSuffix: '04',
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'MSWDO',
        expectedDays: '3-5 working days',
        purpose: 'Hospital bill assistance',
        finalStatus: 'Pending Review',
        actorRole: 'MSWDO Staff',
        remarks: 'Your Medical Assistance request is still pending.',
      ),
      demo(
        id: 'demo-tulong-financial',
        refSuffix: '05',
        typeName: 'Financial Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'MSWDO',
        expectedDays: '3-5 working days',
        purpose: 'Social case study assistance',
        finalStatus: 'Approved',
        actorRole: 'MSWDO Staff',
        remarks: 'Your Financial Assistance request has been approved.',
      ),
      demo(
        id: 'demo-tulong-educational',
        refSuffix: '06',
        typeName: 'Educational Assistance',
        category: ServiceCategory.tulong,
        office: "MSWDO / Mayor's Office",
        expectedDays: '10-15 working days',
        purpose: 'Tuition and allowance support',
        finalStatus: 'Rejected',
        actorRole: 'MSWDO Staff',
        remarks: 'Your Educational Assistance request was rejected.',
      ),
    ]);
    await _persist();
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
