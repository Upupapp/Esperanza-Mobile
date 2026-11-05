import '../services/json_read.dart';

/// Where a certificate came from: a group session (Pre-Marriage
/// Orientation/Counseling and the like, as applicant or as partner) or an
/// event the resident attended.
enum CertificateSource { session, event }

/// One row of GET /citizen/certificates (owner, 2026-11-05, sheet item 9):
/// every certificate the resident holds, newest first (esperanza-backend
/// WelfareSessionsController::certificates, from Sessions::certificatesFor
/// and EventRegistrations::certificatesFor). Also an event registration's
/// own `certificate` block, which carries the same `document`.
class ResidentCertificate {
  const ResidentCertificate({
    required this.controlNumber,
    required this.source,
    this.title,
    this.issuedOn,
    this.eventKey,
    this.eventTitle,
    this.date,
    this.venue,
    this.verifyUrl,
    this.serial,
    this.holderNames = const [],
    this.revoked = false,
    this.revokedReason,
    this.fieldValues = const {},
  });

  /// The issued document's control number: what a `?certificate=` link names.
  final String controlNumber;
  final CertificateSource source;

  /// The certificate's own title (`cert_title`); null when the row has none.
  final String? title;
  final DateTime? issuedOn;
  final String? eventKey;
  final String? eventTitle;

  /// The session's or the event's day, and where it was held.
  final DateTime? date;
  final String? venue;

  /// The certificate's verify page, printed on it as a QR code.
  final String? verifyUrl;

  /// The verification code (the document's serial).
  final String? serial;
  final List<String> holderNames;

  /// The office withdrew it: drawn with REVOKED across it, as on the website.
  final bool revoked;
  final String? revokedReason;

  /// What the certificate prints, frozen when it was issued (the document's
  /// `field_values`): its body, office and signatories.
  final Map<String, dynamic> fieldValues;

  bool get isEvent => source == CertificateSource.event;

  /// Null without a control number: nothing to name or open it by.
  /// [isEventBlock]: an event registration's block, which names no source.
  static ResidentCertificate? fromApi(Map<String, dynamic> json, {bool isEventBlock = false}) {
    final control = JsonRead.nonEmpty(json['control_number']);
    if (control == null) return null;
    final document = JsonRead.map(json['document']);
    final fields = JsonRead.map(document?['field_values']) ?? const <String, dynamic>{};
    final eventKey = JsonRead.nonEmpty(json['event_key']) ?? JsonRead.nonEmpty(fields['event_key']);
    final isEvent = isEventBlock || JsonRead.nonEmpty(json['source']) == 'event' || eventKey != null;
    final place = JsonRead.map(isEvent ? json['event'] : json['session']);
    // The holders, as the website reads them: the row's names, else the
    // document's, else its applicant line.
    var holders = _names(json['holder_names']);
    if (holders.isEmpty) holders = _names(fields['holder_names']);
    if (holders.isEmpty) holders = _names(fields['applicant']);
    return ResidentCertificate(
      controlNumber: control,
      source: isEvent ? CertificateSource.event : CertificateSource.session,
      title: JsonRead.nonEmpty(json['title']) ?? JsonRead.nonEmpty(fields['cert_title']),
      issuedOn: JsonRead.date(json['issued_on']) ?? JsonRead.date(document?['issued_on']),
      eventKey: eventKey,
      eventTitle: isEvent ? JsonRead.nonEmpty(place?['title']) ?? JsonRead.nonEmpty(fields['cert_subtitle']) : null,
      date: JsonRead.date(place?['date']) ??
          JsonRead.date(isEvent ? fields['event_date'] : fields['session_date']),
      venue: JsonRead.nonEmpty(place?['venue']) ?? JsonRead.nonEmpty(fields['venue']),
      verifyUrl: JsonRead.nonEmpty(json['verify_url']) ?? JsonRead.nonEmpty(document?['verify_url']),
      serial: JsonRead.nonEmpty(document?['serial']) ?? JsonRead.nonEmpty(json['verification_code']),
      holderNames: holders,
      revoked: JsonRead.boolean(document?['revoked']) ?? JsonRead.boolean(json['revoked']) ?? false,
      revokedReason: JsonRead.nonEmpty(document?['revoked_reason']),
      fieldValues: fields,
    );
  }

  /// A name list, a single name, or `{name: ...}` rows, trimmed.
  static List<String> _names(Object? v) {
    final items = v is List ? v : (v == null ? const [] : [v]);
    return [
      for (final x in items)
        if ((JsonRead.map(x) != null ? JsonRead.string(JsonRead.map(x)!['name']) : JsonRead.string(x))?.trim()
            case final String name when name.isNotEmpty)
          name,
    ];
  }
}
