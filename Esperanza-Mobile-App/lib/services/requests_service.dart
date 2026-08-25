import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/attachment.dart';
import '../models/receipt.dart';
import '../models/request_milestones.dart';
import '../models/service_request.dart';
import '../theme/app_status.dart';

/// Local, frontend-only "database" for Dokyu + Tulong requests. Persists to
/// SharedPreferences as JSON so submissions survive app restarts during the
/// demo. This is intentionally the ONLY place that touches storage for
/// requests — screens call submit()/advanceStatus() and never read/write
/// SharedPreferences directly, so swapping this for real HTTP calls later
/// (once the backend developer builds the API — see MISSING Web Admin
/// processes in ESPERANZA_MOBILE_WEB_ALIGNMENT.md) only touches this file.
class RequestsService extends ChangeNotifier {
  static const _key = 'esperanza_service_requests';

  /// The verified demo resident's current identity — see
  /// _seedDemoStatusSimulationsIfNeeded and _migrateStaleDemoIdentity,
  /// which both reference these rather than duplicating the literals.
  static const _demoApplicantId = 'ESP-RES-2024-1044';
  static const _demoApplicantName = 'Cristy Bonghanoy';

  /// The demo identity these six seeded requests were originally created
  /// under, before the Marites-Ferrer-to-Cristy-Bonghanoy correction — see
  /// _migrateStaleDemoIdentity's own doc comment.
  static const _staleDemoApplicantId = 'ESP-RES-2024-1203';
  static const _staleDemoApplicantName = 'Marites Ferrer';

  final List<ServiceRequest> _requests = [];
  bool _loaded = false;

  /// Defaults to true for real app usage (see
  /// _seedDemoStatusSimulationsIfNeeded's own doc comment) — tests that
  /// need a pristine/empty or precisely-countable request list pass false
  /// to opt out.
  ///
  /// As of the live-demo cleanup, the real running app (see main.dart)
  /// passes false here — Dokyu/Tulong start clean, with nothing pre-
  /// submitted, so a client demo isn't showing fake completed history
  /// before the presenter has done anything. Every existing test keeps
  /// passing its own explicit value (mostly true) exactly as before, so
  /// this default only changes behavior for the one real construction site.
  final bool seedDemoData;

  /// True only for the real running app (see main.dart) — permanently
  /// strips the retired Dokyu/Tulong demo-status-simulation and paid-
  /// transaction seed records (see [_demoSeedIds]/[_paidTransactionSeedIds])
  /// from whatever's already persisted in SharedPreferences, once. Removing
  /// them from the seeding functions alone only affects a fresh install; a
  /// browser/device that already ran an earlier build with seeding on has
  /// these nine specific records permanently saved locally.
  ///
  /// Left false (the default) for every test — several deliberately
  /// construct their own [ServiceRequest] fixtures that reuse these exact
  /// literal ids on purpose (e.g. rejected_application_panel_test.dart's
  /// Tulong-eligibility-while-blocked scenario), and those must never be
  /// swept up by this cleanup, which only ever targets the real seeded
  /// records this app itself used to create.
  final bool retireLegacyDemoRequestSeeds;

  List<ServiceRequest> get all => List.unmodifiable(_requests);

  List<ServiceRequest> byCategory(ServiceCategory category) =>
      _requests.where((r) => r.category == category).toList()..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  RequestsService({this.seedDemoData = true, this.retireLegacyDemoRequestSeeds = false}) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).map((e) => ServiceRequest.fromJson(e)).toList();
      _requests.addAll(list);
    }
    if (retireLegacyDemoRequestSeeds && _removeRetiredDemoRequestSeeds()) await _persist();
    if (_migrateStaleDemoIdentity()) await _persist();
    if (_migrateEducationalRejectionReason()) await _persist();
    if (_migrateSeniorCitizenIdCategory()) await _persist();
    if (seedDemoData) {
      await _seedDemoStatusSimulationsIfNeeded();
      await _seedPaidTransactionDemoIfNeeded();
    }
    _loaded = true;
    notifyListeners();
  }

  /// Removes exactly the nine known Dokyu/Tulong demo seed ids (see
  /// [_demoSeedIds]/[_paidTransactionSeedIds]) from whatever's already
  /// persisted — never a citizen's own genuinely-submitted request, which
  /// is always assigned a `req-<timestamp>` id (see [submit]) and can never
  /// collide with one of these literal seed ids. Idempotent: once these
  /// nine ids are gone from local storage, later launches simply find
  /// nothing left to remove.
  bool _removeRetiredDemoRequestSeeds() {
    final before = _requests.length;
    _requests.removeWhere((r) => _demoSeedIds.contains(r.id) || _paidTransactionSeedIds.contains(r.id));
    return _requests.length != before;
  }

  /// A browser that already had the six demo requests seeded before the
  /// Marites-Ferrer-to-Cristy-Bonghanoy identity correction has them
  /// permanently persisted under the old applicant id/name —
  /// _seedDemoStatusSimulationsIfNeeded's own "already present, skip" guard
  /// means a source-code fix alone never reaches an existing browser's
  /// saved copy. Corrects only the affected demo-seeded requests in place
  /// (and any receipt already generated for one of them), preserving every
  /// other field — a citizen's own genuinely-submitted requests are never
  /// touched, since they were never sourced from these stale constants.
  bool _migrateStaleDemoIdentity() {
    var changed = false;
    for (var i = 0; i < _requests.length; i++) {
      final r = _requests[i];
      if (!_demoSeedIds.contains(r.id) || r.applicantId != _staleDemoApplicantId) continue;
      final receipt = r.receipt;
      _requests[i] = ServiceRequest(
        id: r.id,
        referenceNumber: r.referenceNumber,
        applicantId: _demoApplicantId,
        applicantName: _demoApplicantName,
        typeName: r.typeName,
        category: r.category,
        office: r.office,
        purpose: r.purpose,
        submittedAt: r.submittedAt,
        status: r.status,
        statusHistory: r.statusHistory,
        attachments: r.attachments,
        citizenRemarks: r.citizenRemarks,
        adminRemarks: r.adminRemarks,
        expectedDays: r.expectedDays,
        formFields: r.formFields,
        requiresPayment: r.requiresPayment,
        fee: r.fee,
        paymentMethod: r.paymentMethod,
        receipt: receipt != null && receipt.residentName == _staleDemoApplicantName
            ? Receipt(
                type: receipt.type,
                amount: receipt.amount,
                referenceNumber: receipt.referenceNumber,
                dateTime: receipt.dateTime,
                residentName: _demoApplicantName,
                serviceName: receipt.serviceName,
                requestReferenceNumber: receipt.requestReferenceNumber,
              )
            : receipt,
      );
      changed = true;
    }
    return changed;
  }

  /// Senior Citizen ID Application (OSCA Membership) moved from Tulong to
  /// Dokyu — it's an ID/membership registration, not an assistance/benefit
  /// program (see mock_catalog.dart's dokyu_senior_citizen_id doc comment
  /// for why, and how it differs from the genuinely-Tulong Social Pension
  /// item). A device that already has a resident's own real Senior Citizen
  /// ID request persisted under the old Tulong category gets it corrected
  /// here, in place — reference number, attachments, status/history, and
  /// every other field carry over completely unchanged; only [category]
  /// itself moves to Dokyu, so My Requests / Request Detail / Track This
  /// Request keep working exactly as before, now consistently filed
  /// alongside the service's own new location. Matched by [typeName]
  /// rather than an id, since — unlike the demo-seed migrations above —
  /// this must also catch a citizen's own genuinely-submitted request, not
  /// just a seeded one.
  static const _seniorCitizenIdTypeName = 'Senior Citizen ID Application (OSCA Membership)';

  bool _migrateSeniorCitizenIdCategory() {
    var changed = false;
    for (var i = 0; i < _requests.length; i++) {
      final r = _requests[i];
      if (r.typeName != _seniorCitizenIdTypeName || r.category != ServiceCategory.tulong) continue;
      _requests[i] = ServiceRequest(
        id: r.id,
        referenceNumber: r.referenceNumber,
        applicantId: r.applicantId,
        applicantName: r.applicantName,
        typeName: r.typeName,
        category: ServiceCategory.dokyu,
        office: r.office,
        purpose: r.purpose,
        submittedAt: r.submittedAt,
        status: r.status,
        statusHistory: r.statusHistory,
        attachments: r.attachments,
        citizenRemarks: r.citizenRemarks,
        adminRemarks: r.adminRemarks,
        rejectionGuidance: r.rejectionGuidance,
        expectedDays: r.expectedDays,
        formFields: r.formFields,
        requiresPayment: r.requiresPayment,
        fee: r.fee,
        paymentMethod: r.paymentMethod,
        receipt: r.receipt,
      );
      changed = true;
    }
    return changed;
  }

  /// A browser that already had the seeded Educational Assistance demo
  /// request persisted before its rejection reason/guidance placeholder was
  /// added (see _seedDemoStatusSimulationsIfNeeded) has it saved with
  /// adminRemarks/rejectionGuidance still null — the seeding function's own
  /// "already present, skip" guard means a source-code fix alone never
  /// reaches that already-persisted copy, same reasoning as
  /// _migrateStaleDemoIdentity above. Backfills both fields (and the
  /// matching statusHistory entry's own remarks) in place; a citizen's own
  /// genuinely-submitted/rejected request is never touched, since this only
  /// ever matches the one specific seeded id.
  bool _migrateEducationalRejectionReason() {
    const reason = 'Submitted school enrollment document could not be verified for the current academic term. '
        'Please submit an updated Certificate of Enrollment or Registration issued by the school.';
    const guidance = 'Upload an updated school document and submit a new Educational Assistance application.';

    final index = _requests.indexWhere((r) => r.id == 'demo-tulong-educational');
    if (index == -1) return false;
    final r = _requests[index];
    if (r.adminRemarks != null && r.rejectionGuidance != null) return false;

    r.adminRemarks = reason;
    r.rejectionGuidance = guidance;
    final lastIndex = r.statusHistory.length - 1;
    if (lastIndex >= 0 && r.statusHistory[lastIndex].status == 'Rejected') {
      r.statusHistory[lastIndex] = StatusHistoryEntry(
        status: 'Rejected',
        at: r.statusHistory[lastIndex].at,
        actor: r.statusHistory[lastIndex].actor,
        remarks: reason,
      );
    }
    return true;
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

    const applicantId = _demoApplicantId; // Cristy Bonghanoy — verified, has Dokyu/Tulong access.
    const applicantName = _demoApplicantName;
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
      bool requiresPayment = false,
      String fee = '',
      // Only ever set for a seeded Rejected demo request — mirrors what
      // RequestsService.rejectDemo() itself sets for a live-rejected one
      // (adminRemarks == the same text as the rejection statusHistory
      // entry's own remarks), so RequestDetailScreen's Application Rejected
      // panel renders identically either way. rejectionGuidance is the
      // panel's optional "what you can do" line — see ServiceRequest's own
      // doc comment for its fallback when left null.
      String? adminRemarks,
      String? rejectionGuidance,
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
          StatusHistoryEntry(
            status: 'Submitted',
            at: submittedAt,
            actor: 'Citizen',
            remarks: 'Request submitted via mobile app.',
          ),
          StatusHistoryEntry(status: finalStatus, at: daysAgo(1), actor: actorRole, remarks: remarks),
        ],
        attachments: const [],
        expectedDays: expectedDays,
        requiresPayment: requiresPayment,
        fee: fee,
        adminRemarks: adminRemarks,
        rejectionGuidance: rejectionGuidance,
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
        requiresPayment: true, // ₱50.00 — see mock_catalog.dart's dokyu_barangay_clearance fee
        fee: '₱50.00',
      ),
      demo(
        id: 'demo-dokyu-business-permit',
        refSuffix: '02',
        typeName: 'Business Permit (New Application)',
        category: ServiceCategory.dokyu,
        office: 'Business Permits and Licensing Office',
        expectedDays: '7 working days',
        purpose: 'New business registration',
        finalStatus: 'Pending Review',
        actorRole: 'Business Permits and Licensing Office Staff',
        remarks: 'Your Business Permit request is still pending.',
        requiresPayment: true, // ₱500.00 and up — see dokyu_business_new fee
        fee: '₱500.00 and up (based on capital)',
      ),
      demo(
        id: 'demo-dokyu-certificate-indigency',
        refSuffix: '03',
        typeName: 'Certificate of Indigency',
        category: ServiceCategory.dokyu,
        office: 'Municipal Social Welfare and Development Office',
        expectedDays: '2-3 working days',
        purpose: 'Medical Assistance',
        finalStatus: 'Rejected',
        actorRole: 'Municipal Social Welfare and Development Office Staff',
        remarks: 'Your Certificate of Indigency request was rejected.',
        // Free — see dokyu_indigency fee; requiresPayment left false.
      ),
      demo(
        id: 'demo-tulong-medical',
        refSuffix: '04',
        typeName: 'Medical Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        expectedDays: '3-5 working days',
        purpose: 'Hospital bill assistance',
        finalStatus: 'Pending Review',
        actorRole: 'Municipal Social Welfare and Development Office Staff',
        remarks: 'Your Medical Assistance request is still pending.',
        // Free — see tulong_medical fee; requiresPayment left false.
      ),
      demo(
        id: 'demo-tulong-financial',
        refSuffix: '05',
        typeName: 'Financial Assistance (AICS)',
        category: ServiceCategory.tulong,
        office: 'Municipal Social Welfare and Development Office',
        expectedDays: '3-5 working days',
        purpose: 'Social case study assistance',
        finalStatus: 'Approved',
        actorRole: 'Municipal Social Welfare and Development Office Staff',
        remarks: 'Your Financial Assistance request has been approved.',
        // Free — see tulong_financial fee; requiresPayment left false.
      ),
      demo(
        id: 'demo-tulong-educational',
        refSuffix: '06',
        typeName: 'Educational Assistance',
        category: ServiceCategory.tulong,
        office: 'Office of the Municipal Mayor',
        expectedDays: '10-15 working days',
        purpose: 'Tuition and allowance support',
        finalStatus: 'Rejected',
        actorRole: 'Office of the Municipal Mayor Staff',
        // Placeholder rejection reason for demonstration purposes only —
        // see RequestDetailScreen's Application Rejected panel, which reads
        // this straight from adminRemarks (same value as this status
        // entry's own remarks, matching how a live Reject (Demo) already
        // sets both).
        remarks: 'Submitted school enrollment document could not be verified for the current academic term. '
            'Please submit an updated Certificate of Enrollment or Registration issued by the school.',
        adminRemarks: 'Submitted school enrollment document could not be verified for the current academic term. '
            'Please submit an updated Certificate of Enrollment or Registration issued by the school.',
        rejectionGuidance: 'Upload an updated school document and submit a new Educational Assistance application.',
        // Free — see tulong_educational fee; requiresPayment left false.
      ),
    ]);
    await _persist();
  }

  /// Three already-Paid demo requests (one per payment method) so the
  /// Transactions screen has real content to demonstrate immediately,
  /// without having to manually walk a request through the payment flow
  /// first. Same request+receipt architecture as a genuinely-simulated
  /// payment (see advanceMilestone/_generateReceipt) — Transactions has no
  /// separate data source, so these appear there exactly the same way a
  /// live-paid request would. Seeded exactly once, guarded by
  /// [_paidTransactionSeedIds] already being present (same pattern as
  /// [_seedDemoStatusSimulationsIfNeeded]) — a browser that already has
  /// these ids never gets them re-added or duplicated, and an existing
  /// browser that predates this seed (and so doesn't have these ids yet)
  /// receives them on its next load with no manual storage-clearing
  /// needed. Services/fees are real catalog entries, never invented — see
  /// each entry's own comment for its catalog key.
  static const _paidTransactionSeedIds = [
    'demo-paid-dokyu-residency-gcash',
    'demo-paid-dokyu-rpt-maya',
    'demo-paid-tulong-pension-onsite',
  ];

  Future<void> _seedPaidTransactionDemoIfNeeded() async {
    if (_requests.any((r) => _paidTransactionSeedIds.contains(r.id))) return;

    final now = DateTime.now();
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    ServiceRequest paid({
      required String id,
      required String refSuffix,
      required String typeName,
      required ServiceCategory category,
      required String office,
      required String expectedDays,
      required String purpose,
      required String fee,
      required int submittedDaysAgo,
      required int paidDaysAgo,
      required String paymentMethod,
      required ReceiptType receiptType,
      required String receiptRefDigits,
    }) {
      final submittedAt = daysAgo(submittedDaysAgo);
      final paidAt = daysAgo(paidDaysAgo);
      final referenceNumber = '${category == ServiceCategory.dokyu ? 'DR' : 'AR'}-${now.year}-DEMO$refSuffix';
      final receiptPrefix = switch (receiptType) {
        ReceiptType.gcash => 'GC',
        ReceiptType.maya => 'MY',
        ReceiptType.onsite => 'OR',
      };
      return ServiceRequest(
        id: id,
        referenceNumber: referenceNumber,
        applicantId: _demoApplicantId,
        applicantName: _demoApplicantName,
        typeName: typeName,
        category: category,
        office: office,
        purpose: purpose,
        submittedAt: submittedAt,
        status: RequestMilestones.canonicalStatusFor(RequestMilestones.paid).label,
        statusHistory: [
          StatusHistoryEntry(
            status: RequestMilestones.submitted,
            at: submittedAt,
            actor: 'Citizen',
            remarks: 'Request submitted via mobile app.',
          ),
          StatusHistoryEntry(
            status: RequestMilestones.paid,
            at: paidAt,
            actor: 'Demo Simulation',
            remarks: 'Payment confirmed.',
          ),
        ],
        attachments: const [],
        expectedDays: expectedDays,
        requiresPayment: true,
        fee: fee,
        paymentMethod: paymentMethod,
        receipt: Receipt(
          type: receiptType,
          amount: fee,
          referenceNumber: '$receiptPrefix-$receiptRefDigits',
          dateTime: paidAt,
          residentName: _demoApplicantName,
          serviceName: typeName,
          requestReferenceNumber: referenceNumber,
        ),
      );
    }

    _requests.addAll([
      paid(
        id: 'demo-paid-dokyu-residency-gcash',
        refSuffix: '07',
        typeName: 'Certificate of Residency', // mock_catalog.dart: dokyu_residency
        category: ServiceCategory.dokyu,
        office: 'Civil Registrar',
        expectedDays: '1-2 working days',
        purpose: 'Proof of Residency',
        fee: '₱50.00', // dokyu_residency's own configured fee
        submittedDaysAgo: 10,
        paidDaysAgo: 9,
        paymentMethod: 'GCash',
        receiptType: ReceiptType.gcash,
        receiptRefDigits: '5820147736',
      ),
      paid(
        id: 'demo-paid-dokyu-rpt-maya',
        refSuffix: '08',
        typeName: 'Real Property Tax Clearance', // mock_catalog.dart: dokyu_rpt
        category: ServiceCategory.dokyu,
        office: "Treasurer's Office",
        expectedDays: 'Same day',
        purpose: 'Loan requirement',
        fee: '₱100.00', // dokyu_rpt's own configured fee
        submittedDaysAgo: 8,
        paidDaysAgo: 7,
        paymentMethod: 'Maya',
        receiptType: ReceiptType.maya,
        receiptRefDigits: '3391208465',
      ),
      paid(
        id: 'demo-paid-tulong-pension-onsite',
        refSuffix: '09',
        typeName: 'Social Pension (Indigent Senior Citizen)', // mock_catalog.dart: tulong_pension
        category: ServiceCategory.tulong,
        office: 'Office for Senior Citizens Affairs',
        expectedDays: '5-7 working days',
        purpose: 'Quarterly pension release processing',
        fee: '₱100.00', // tulong_pension's own configured processing fee (distinct from its ₱1,000/month assistance amount)
        submittedDaysAgo: 5,
        paidDaysAgo: 4,
        paymentMethod: 'Onsite',
        receiptType: ReceiptType.onsite,
        receiptRefDigits: '7714902938',
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
    bool requiresPayment = false,
    String fee = '',
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
        StatusHistoryEntry(
          status: 'Submitted',
          at: now,
          actor: 'Citizen',
          remarks: 'Request submitted via mobile app.',
        ),
      ],
      attachments: attachments,
      expectedDays: expectedDays,
      formFields: formFields,
      requiresPayment: requiresPayment,
      fee: fee,
    );
    _requests.add(request);
    await _persist();
    notifyListeners();
    return request;
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

  /// Whether [requestId] can still advance (i.e. hasn't reached the end of
  /// its milestone sequence, and isn't Rejected/Cancelled) — drives the
  /// demo-only "Next Demo Step" control's enabled state.
  bool canAdvance(String requestId) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    final sequence = RequestMilestones.sequenceFor(requiresPayment: request.requiresPayment);
    final currentIndex = sequence.indexOf(request.statusHistory.last.status);
    return currentIndex != -1 && currentIndex < sequence.length - 1;
  }

  /// The milestone this request would move to if advanced right now, or
  /// null if it's already at the end (or off the normal sequence, e.g.
  /// Rejected/Cancelled).
  String? nextMilestone(String requestId) {
    final request = _requests.firstWhere((r) => r.id == requestId);
    final sequence = RequestMilestones.sequenceFor(requiresPayment: request.requiresPayment);
    final currentIndex = sequence.indexOf(request.statusHistory.last.status);
    if (currentIndex == -1 || currentIndex >= sequence.length - 1) return null;
    return sequence[currentIndex + 1];
  }

  /// DEMO-ONLY: manually advances [requestId] to its next milestone (see
  /// [RequestMilestones]) — this is a frontend simulation control, not
  /// something a real citizen ever sees; a real deployment's status
  /// changes would come from the Web Admin / backend instead. No-op if
  /// already at the end of the sequence. [paymentMethod], when provided,
  /// is recorded on the request (used when the Waiting for Payment
  /// milestone is being left behind, i.e. the citizen just chose one).
  Future<void> advanceMilestone(String requestId, {String? paymentMethod}) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    final next = nextMilestone(requestId);
    if (next == null) return;
    if (paymentMethod != null) request.paymentMethod = paymentMethod;
    if (next == RequestMilestones.receiptGenerated) {
      request.receipt = _generateReceipt(request);
    }
    request.status = RequestMilestones.canonicalStatusFor(next).label;
    request.statusHistory.add(
      StatusHistoryEntry(
        status: next,
        at: DateTime.now(),
        actor: 'Demo Simulation',
        remarks: _demoRemarksFor(next, request),
      ),
    );
    await _persist();
    notifyListeners();
  }

  String? _demoRemarksFor(String milestone, ServiceRequest request) {
    final method = request.paymentMethod;
    switch (milestone) {
      case RequestMilestones.waitingForPayment:
        return 'Please settle the required fee to continue processing.';
      case RequestMilestones.paymentMethodSelected:
        return method == 'Onsite'
            ? 'Payment to be completed at Municipal Office.'
            : 'Payment method selected: $method (Demo / Simulation).';
      case RequestMilestones.paymentProcessing:
        return method == 'Onsite'
            ? 'Awaiting confirmation of onsite payment.'
            : 'Verifying payment (Demo / Simulation).';
      case RequestMilestones.receiptGenerated:
        return 'Receipt generated. Tap "View Receipt" below to see it.';
      case RequestMilestones.paid:
        return 'Payment confirmed.';
      case RequestMilestones.readyForRelease:
        return request.category == ServiceCategory.dokyu
            ? 'Your document is ready for pickup at the issuing office.'
            : 'Your request is ready for release.';
      case RequestMilestones.completed:
        return 'Request completed.';
      default:
        return null;
    }
  }

  static final _receiptRandom = Random();

  /// Builds this request's own receipt, generating local/demo-only
  /// transaction values — never a real gateway's reference number, never a
  /// value copied from a visual reference screenshot. Uses the request's
  /// own catalog fee/applicant/type/reference number, exactly as
  /// submitted, never an invented amount.
  Receipt _generateReceipt(ServiceRequest request) {
    final type = switch (request.paymentMethod) {
      'GCash' => ReceiptType.gcash,
      'Maya' => ReceiptType.maya,
      _ => ReceiptType.onsite,
    };
    final prefix = switch (type) {
      ReceiptType.gcash => 'GC',
      ReceiptType.maya => 'MY',
      ReceiptType.onsite => 'OR',
    };
    final digits = List.generate(10, (_) => _receiptRandom.nextInt(10)).join();
    return Receipt(
      type: type,
      amount: request.fee,
      referenceNumber: '$prefix-$digits',
      dateTime: DateTime.now(),
      residentName: request.applicantName,
      serviceName: request.typeName,
      requestReferenceNumber: request.referenceNumber,
    );
  }

  /// DEMO-ONLY: branches [requestId] straight to Rejected with [reason] —
  /// a placeholder for what would eventually be an admin-provided reason
  /// from the Web Admin, not a real rejection decision made here.
  Future<void> rejectDemo(String requestId, {required String reason}) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = RequestMilestones.canonicalStatusFor(RequestMilestones.rejected).label;
    request.adminRemarks = reason;
    request.statusHistory.add(
      StatusHistoryEntry(status: RequestMilestones.rejected, at: DateTime.now(), actor: 'Demo Simulation', remarks: reason),
    );
    await _persist();
    notifyListeners();
  }
}
