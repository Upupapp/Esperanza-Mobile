import '../services/json_read.dart';

/// Where and how to claim a request that is ready (owner, 2026-10-15;
/// esperanza-backend CitizenRequestController::pickup). Present only while
/// the request waits to be claimed: Mark to Release, or Ready for Release.
class RequestPickup {
  const RequestPickup({
    this.office,
    this.officeContact,
    this.officeHours,
    this.officeHoursFil,
    this.readySince,
    this.feeDue,
    this.bring = const [],
  });

  final String? office;
  final String? officeContact;
  final String? officeHours;
  final String? officeHoursFil;
  final DateTime? readySince;

  /// A fee still to pay before it is released, in pesos.
  final double? feeDue;

  /// What to bring, as the server's keys: valid_id, reference_number, fee.
  final List<String> bring;

  static RequestPickup? fromApi(Map<String, dynamic>? json) {
    if (json == null) return null;
    return RequestPickup(
      office: JsonRead.nonEmpty(json['office']),
      officeContact: JsonRead.nonEmpty(json['office_contact']),
      officeHours: JsonRead.nonEmpty(json['office_hours']),
      officeHoursFil: JsonRead.nonEmpty(json['office_hours_fil']),
      readySince: JsonRead.date(json['ready_since']),
      feeDue: num.tryParse('${json['fee_due']}')?.toDouble(),
      bring: JsonRead.strings(json['bring']),
    );
  }
}

/// A document issued for a request (esperanza-backend IssuanceService::
/// describe): its control number, dates and verification link, whether it was
/// revoked, and the scan of the signed, sealed paper - the resident's digital
/// copy (owner, 2026-10-15). The paper stays the official document.
class IssuedDocumentInfo {
  const IssuedDocumentInfo({
    required this.controlNumber,
    this.serial,
    this.verifyUrl,
    this.issuedOn,
    this.validUntil,
    this.expired = false,
    this.isReprint = false,
    this.reprintNumber = 0,
    this.revoked = false,
    this.revokedAt,
    this.revokedReason,
    this.hasScan = false,
    this.scanUrl,
  });

  final String controlNumber;
  final String? serial;
  final String? verifyUrl;
  final DateTime? issuedOn;
  final DateTime? validUntil;
  final bool expired;
  final bool isReprint;
  final int reprintNumber;
  final bool revoked;
  final DateTime? revokedAt;
  final String? revokedReason;
  final bool hasScan;

  /// A short-lived signed link to the scan; null once revoked.
  final String? scanUrl;

  bool get isPdf => (scanUrl ?? '').toLowerCase().split('?').first.endsWith('.pdf');

  static IssuedDocumentInfo? fromApi(Map<String, dynamic> json) {
    final control = JsonRead.nonEmpty(json['control_number']);
    if (control == null) return null;
    return IssuedDocumentInfo(
      controlNumber: control,
      serial: JsonRead.nonEmpty(json['serial']),
      verifyUrl: JsonRead.nonEmpty(json['verify_url']),
      issuedOn: JsonRead.date(json['issued_on']),
      validUntil: JsonRead.date(json['valid_until']),
      expired: JsonRead.boolean(json['expired']) ?? false,
      isReprint: JsonRead.boolean(json['is_reprint']) ?? false,
      reprintNumber: JsonRead.integer(json['reprint_number']) ?? 0,
      revoked: JsonRead.boolean(json['revoked']) ?? false,
      revokedAt: JsonRead.date(json['revoked_at']),
      revokedReason: JsonRead.nonEmpty(json['revoked_reason']),
      hasScan: JsonRead.boolean(json['has_scan']) ?? false,
      scanUrl: JsonRead.mediaUrl(json['scan_url']),
    );
  }
}
