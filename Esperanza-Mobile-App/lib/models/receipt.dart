/// A generated receipt for one Dokyu request — FRONTEND SIMULATION ONLY,
/// see [ReceiptType]'s own doc comment. Generated once, synchronously,
/// the moment RequestsService.submit() creates the request — payment (when
/// the service has a real fee) happens during the application flow itself,
/// before the request exists, never as a later tracking milestone — and
/// then persisted on that request's own [Receipt] field for the rest of
/// the demo session. Tulong requests never get one (assistance
/// applications have no receipt concept).
enum ReceiptType {
  gcash,
  maya,
  onsite,

  /// A Free Dokyu service — still generates a formality/claim-stub
  /// receipt (so "Documents Uploaded"/Transactions/View Receipt keep
  /// working uniformly for every Dokyu request), but never with an
  /// invented monetary amount.
  free,
}

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
        type: ReceiptType.values.firstWhere((t) => t.name == json['type'], orElse: () => ReceiptType.onsite),
        amount: json['amount'],
        referenceNumber: json['referenceNumber'],
        dateTime: DateTime.parse(json['dateTime']),
        residentName: json['residentName'],
        serviceName: json['serviceName'],
        requestReferenceNumber: json['requestReferenceNumber'],
      );
}
