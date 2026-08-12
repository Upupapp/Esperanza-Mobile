import 'attachment.dart';

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
  final String expectedDays;
  final Map<String, dynamic> formFields;

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
    required this.attachments,
    this.citizenRemarks,
    this.adminRemarks,
    required this.expectedDays,
    this.formFields = const {},
  });

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
        'expectedDays': expectedDays,
        'formFields': formFields,
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
        expectedDays: json['expectedDays'],
        formFields: Map<String, dynamic>.from(json['formFields'] ?? {}),
      );
}
