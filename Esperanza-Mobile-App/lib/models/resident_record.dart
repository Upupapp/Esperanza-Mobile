import '../services/json_read.dart';
import 'service_request.dart';

/// One Dokyu or Tulong on the resident's record: GET /citizen/records
/// (esperanza-backend CitizenRequestController::records(), 2026-10-13).
///
/// Either recorded by an office ([fromOffice]: imported from the office's own
/// files, or encoded at its counter) or filed by the resident on the portal or
/// in this app. An office's record is read only - it has no detail endpoint
/// and nothing to act on - while a filed one opens as any of the resident's
/// requests does.
class ResidentRecord {
  const ResidentRecord({
    required this.ref,
    required this.category,
    required this.service,
    required this.status,
    required this.fromOffice,
    this.office,
    this.date,
    this.amount,
    this.purpose,
    this.reference,
    this.imported = false,
  });

  final String ref;
  final ServiceCategory category;
  final String service;
  final String status;
  final String? office;
  final DateTime? date;

  /// What was released (or approved) for an assistance, or paid for a
  /// document, as the backend gives it: a number or a decimal string.
  final Object? amount;
  final String? purpose;

  /// The office's own number for it (a control or OR number), if any.
  final String? reference;
  final bool fromOffice;
  final bool imported;

  /// Null for a row this build cannot place (no ref, or not Dokyu/Tulong).
  static ResidentRecord? fromApi(Map<String, dynamic> json) {
    final ref = JsonRead.nonEmpty(json['ref']);
    final category = switch (JsonRead.string(json['type'])) {
      'dokyu' => ServiceCategory.dokyu,
      'tulong' => ServiceCategory.tulong,
      _ => null,
    };
    if (ref == null || category == null) return null;
    return ResidentRecord(
      ref: ref,
      category: category,
      service: JsonRead.nonEmpty(json['service']) ?? (category == ServiceCategory.tulong ? 'Tulong' : 'Dokyu'),
      status: JsonRead.nonEmpty(json['status']) ?? '',
      office: JsonRead.nonEmpty(json['office']),
      date: JsonRead.date(json['date']),
      amount: _amount(json['amount']),
      purpose: JsonRead.nonEmpty(json['purpose']),
      reference: JsonRead.nonEmpty(json['reference']),
      fromOffice: JsonRead.boolean(json['from_office']) ?? false,
      imported: JsonRead.boolean(json['imported']) ?? false,
    );
  }

  static Object? _amount(Object? v) {
    if (v is num) return v;
    final s = JsonRead.nonEmpty(v);
    return s == null || double.tryParse(s) == null ? null : s;
  }

  double? get amountValue => amount is num ? (amount as num).toDouble() : double.tryParse('${amount ?? ''}');

  /// Who it came from, as the resident reads it.
  String get source => fromOffice ? 'Recorded by ${office ?? 'the office'}' : 'Filed by you';
}
