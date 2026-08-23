/// A generated receipt for one paid request — FRONTEND SIMULATION ONLY,
/// see [ReceiptType]'s own doc comment. Generated once, at the moment a
/// request's milestone simulation reaches [RequestMilestones.
/// receiptGenerated] (see RequestsService.advanceMilestone), and then
/// persisted on that request's own [Receipt] field for the rest of the
/// demo session — each request keeps its own, independent of any other
/// request's receipt.
enum ReceiptType { gcash, maya, onsite }

class Receipt {
  final ReceiptType type;

  /// The catalog item's own fee text (e.g. "₱50.00") — never a value
  /// copied from a visual reference screenshot.
  final String amount;

  /// A generated demo transaction/reference number — local only, never a
  /// real payment gateway's identifier.
  final String referenceNumber;

  final DateTime dateTime;
  final String residentName;
  final String serviceName;

  /// The request's own reference number (e.g. "DOC-2026-001"), shown on
  /// the receipt alongside the transaction reference above.
  final String requestReferenceNumber;

  const Receipt({
    required this.type,
    required this.amount,
    required this.referenceNumber,
    required this.dateTime,
    required this.residentName,
    required this.serviceName,
    required this.requestReferenceNumber,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'amount': amount,
        'referenceNumber': referenceNumber,
        'dateTime': dateTime.toIso8601String(),
        'residentName': residentName,
        'serviceName': serviceName,
        'requestReferenceNumber': requestReferenceNumber,
      };

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        type: ReceiptType.values.firstWhere((t) => t.name == json['type']),
        amount: json['amount'],
        referenceNumber: json['referenceNumber'],
        dateTime: DateTime.parse(json['dateTime']),
        residentName: json['residentName'],
        serviceName: json['serviceName'],
        requestReferenceNumber: json['requestReferenceNumber'],
      );
}
