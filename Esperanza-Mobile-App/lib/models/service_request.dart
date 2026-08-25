import 'attachment.dart';
import 'receipt.dart';

enum ServiceCategory { dokyu, tulong, sakunaIncident }

/// One entry in a request's audit trail — what the Web Admin's "Admin
/// Actions" produce and what the mobile app's "Mobile Reflection" reads.
/// See ESPERANZA_MOBILE_WEB_ALIGNMENT.md Section 3 (Flow Matrix).
class StatusHistoryEntry {
  final String status;
  final DateTime at;
  final String? remarks;
  final String actor; // 'Citizen' or an admin role label, e.g. 'MSWDO Staff'

  StatusHistoryEntry({
    required this.status,
    required this.at,
    this.remarks,
    required this.actor,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        'at': at.toIso8601String(),
        'remarks': remarks,
        'actor': actor,
      };

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) => StatusHistoryEntry(
        status: json['status'],
        at: DateTime.parse(json['at']),
        remarks: json['remarks'],
        actor: json['actor'],
      );
}

/// A citizen-submitted Dokyu (document) or Tulong (assistance) request.
/// Field names deliberately match the shape a future Laravel API resource
/// would return (id, referenceNumber, applicantId, type, category,
/// submittedAt, status, statusHistory, attachments, remarks, adminRemarks)
/// so swapping the mock DataService for real HTTP calls later only touches
/// the service layer, never these models or the screens that use them.
class ServiceRequest {
  final String id;
  final String referenceNumber;
  final String applicantId;
  final String applicantName;
  final String typeName;
  final ServiceCategory category;
  final String office;
  final String purpose;
  final DateTime submittedAt;
  String status;
  final List<StatusHistoryEntry> statusHistory;
  final List<Attachment> attachments;
  String? citizenRemarks;
  String? adminRemarks;

  /// Optional "what you can do about it" hint shown alongside [adminRemarks]
  /// when a request is Rejected (see RequestDetailScreen's Application
  /// Rejected panel) — null for every request that doesn't have a specific
  /// suggested next step, in which case the panel falls back to a generic
  /// "submit a new application" message built from [typeName] instead.
  /// Mutable (not final) for the same reason [adminRemarks] is — a stale
  /// seeded copy from before this field existed gets backfilled in place,
  /// see RequestsService._migrateEducationalRejectionReason.
  String? rejectionGuidance;

  /// Non-null exactly while [status] is 'Waiting Requirements' *because* an
  /// admin flagged one specific requirement as needing a new upload (see
  /// RequestsService.flagAdditionalDocuments) — distinct from the payment
  /// sub-steps, which also canonicalize to 'Waiting Requirements' but never
  /// set this field. Holds the exact requirement label (matches
  /// Attachment.documentTypeLabel) so RequestDetailScreen can show a
  /// re-upload control for that one requirement only. Cleared by
  /// RequestsService.resolveAdditionalDocuments once the resident resubmits.
  String? flaggedRequirementLabel;
  final String expectedDays;
  final Map<String, dynamic> formFields;

  /// Whether this service has a real fee (from the catalog item's own
  /// `fee` field — never invented here) — decides whether the milestone
  /// simulation includes payment steps at all. See
  /// docs on the milestone/payment simulation (frontend-only).
  final bool requiresPayment;

  /// The catalog item's own fee text (e.g. "₱50.00"), captured at
  /// submission time — same pattern as [office]/[expectedDays] already
  /// being a snapshot rather than a live re-lookup. Only meaningful when
  /// [requiresPayment] is true.
  final String fee;

  /// 'Onsite' / 'GCash' / 'Maya' once chosen at the Waiting for Payment
  /// milestone — simulation only, never a real transaction.
  String? paymentMethod;

  /// Generated once the milestone simulation reaches
  /// RequestMilestones.receiptGenerated — this request's own permanent
  /// receipt for the rest of the demo session. Never shared across
  /// requests; each one that gets paid generates and keeps its own.
  Receipt? receipt;

  ServiceRequest({
    required this.id,
    required this.referenceNumber,
    required this.applicantId,
    required this.applicantName,
    required this.typeName,
    required this.category,
    required this.office,
    required this.purpose,
    required this.submittedAt,
    required this.status,
    required this.statusHistory,
    required List<Attachment> attachments,
    this.citizenRemarks,
    this.adminRemarks,
    this.rejectionGuidance,
    this.flaggedRequirementLabel,
    required this.expectedDays,
    this.formFields = const {},
    this.requiresPayment = false,
    this.fee = '',
    this.paymentMethod,
    this.receipt,
  }) : attachments = List<Attachment>.of(attachments);

  Map<String, dynamic> toJson() => {
        'id': id,
        'referenceNumber': referenceNumber,
        'applicantId': applicantId,
        'applicantName': applicantName,
        'typeName': typeName,
        'category': category.name,
        'office': office,
        'purpose': purpose,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status,
        'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'citizenRemarks': citizenRemarks,
        'adminRemarks': adminRemarks,
        'rejectionGuidance': rejectionGuidance,
        'flaggedRequirementLabel': flaggedRequirementLabel,
        'expectedDays': expectedDays,
        'formFields': formFields,
        'requiresPayment': requiresPayment,
        'fee': fee,
        'paymentMethod': paymentMethod,
        'receipt': receipt?.toJson(),
      };

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
        id: json['id'],
        referenceNumber: json['referenceNumber'],
        applicantId: json['applicantId'],
        applicantName: json['applicantName'],
        typeName: json['typeName'],
        category: ServiceCategory.values.firstWhere((c) => c.name == json['category']),
        office: json['office'],
        purpose: json['purpose'],
        submittedAt: DateTime.parse(json['submittedAt']),
        status: json['status'],
        statusHistory: (json['statusHistory'] as List).map((e) => StatusHistoryEntry.fromJson(e)).toList(),
        attachments: (json['attachments'] as List).map((e) => Attachment.fromJson(e)).toList(),
        citizenRemarks: json['citizenRemarks'],
        adminRemarks: json['adminRemarks'],
        rejectionGuidance: json['rejectionGuidance'],
        flaggedRequirementLabel: json['flaggedRequirementLabel'],
        expectedDays: json['expectedDays'],
        formFields: Map<String, dynamic>.from(json['formFields'] ?? {}),
        // Defaults false/null so requests persisted before this field
        // existed still deserialize cleanly.
        requiresPayment: json['requiresPayment'] ?? false,
        fee: json['fee'] ?? '',
        paymentMethod: json['paymentMethod'],
        receipt: json['receipt'] != null ? Receipt.fromJson(json['receipt']) : null,
      );
}
