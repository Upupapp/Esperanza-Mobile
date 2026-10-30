import '../services/json_read.dart';

/// Registering for an event (owner, 2026-10-30, round 2 item 6): the LGU
/// posts an event, residents register so the municipality has a record of
/// who attended, staff check them in by their code, and those who attended
/// get an e-certificate when the event gives one.
///
/// An event row's own `registration` block (GET /events and /events/{key},
/// esperanza-backend EventRows): whether residents can register, the
/// number of places, until when, and how many have registered so far.
class EventRegistrationInfo {
  const EventRegistrationInfo({required this.open, this.capacity, this.closesAt, this.count = 0, this.full = false});

  /// The LGU takes registrations for this event: the block's `enabled`
  /// (the server's own `open` means "a resident can register right now",
  /// false once full or closed, when this section still says why).
  final bool open;

  /// The most who can register; null when there is no limit.
  final int? capacity;

  /// When registration closes. Null means at the event's start, which the
  /// server decides (it answers REGISTRATION_CLOSED after that).
  final DateTime? closesAt;

  /// Residents registered so far (cancelled ones not counted).
  final int count;

  /// The server's own word that every place is taken.
  final bool full;

  /// Places still free, or null when there is no limit.
  int? get placesLeft {
    final c = capacity;
    return c == null ? null : (c - count).clamp(0, c);
  }

  bool get isFull => full || (capacity != null && count >= capacity!);

  /// Whether its closing time has passed by [now].
  bool closedBy(DateTime now) => closesAt != null && !now.isBefore(closesAt!);

  EventRegistrationInfo copyWith({int? count, bool? full}) => EventRegistrationInfo(
    open: open,
    capacity: capacity,
    closesAt: closesAt,
    count: count ?? this.count,
    full: full ?? this.full,
  );

  /// Null when the row has no block (an older server): the event then
  /// offers no registration.
  static EventRegistrationInfo? fromApi(Object? raw) {
    final m = JsonRead.map(raw);
    if (m == null) return null;
    final capacity = JsonRead.integer(m['capacity']);
    final count = JsonRead.integer(m['count']) ?? 0;
    return EventRegistrationInfo(
      open: JsonRead.boolean(m['enabled']) ?? JsonRead.boolean(m['open']) ?? false,
      capacity: capacity != null && capacity > 0 ? capacity : null,
      closesAt: JsonRead.date(m['closes_at']),
      count: count < 0 ? 0 : count,
      full: JsonRead.boolean(m['full']) ?? false,
    );
  }
}

/// The e-certificate issued to a resident who attended (an issued document,
/// control number `EVT-YYYY-NNNNNN`), checked at its verify URL like any
/// other document the LGU issues.
class EventCertificate {
  const EventCertificate({required this.verifyUrl, this.controlNumber});

  final String verifyUrl;
  final String? controlNumber;

  /// Null without a verify URL: there would be nothing to open.
  static EventCertificate? fromApi(Object? raw) {
    final m = JsonRead.map(raw);
    final url = m == null ? null : JsonRead.nonEmpty(m['verify_url']);
    if (url == null) return null;
    return EventCertificate(verifyUrl: url, controlNumber: JsonRead.nonEmpty(m!['control_number']));
  }
}

/// The resident's own registration for one event (GET
/// /citizen/event-registrations, and the reply to POST
/// /citizen/events/{key}/registration).
class EventRegistration {
  const EventRegistration({
    required this.eventKey,
    required this.code,
    this.registeredAt,
    this.cancelledAt,
    this.attended,
    this.certificate,
  });

  final String eventKey;

  /// Eight characters (A-Z, 2-9) that staff check the resident in by.
  final String code;
  final DateTime? registeredAt;
  final DateTime? cancelledAt;

  /// Null until the LGU records attendance; then whether they came.
  final bool? attended;

  /// Set once the LGU has issued this resident's certificate.
  final EventCertificate? certificate;

  /// Not cancelled. A cancelled registration is kept by the server (it is
  /// reused if the resident registers again) but holds no place.
  bool get active => cancelledAt == null;

  /// The code as it is shown and read out, `ABCD-EFGH`.
  String get displayCode => formatRegistrationCode(code);

  /// [eventKey] stands in when the row does not name its event (the reply
  /// to registering for one).
  static EventRegistration? fromApi(Map<String, dynamic> json, {String? eventKey}) {
    final key = JsonRead.nonEmpty(json['event_key']) ?? eventKey;
    final code = JsonRead.nonEmpty(json['code']);
    if (key == null || code == null) return null;
    return EventRegistration(
      eventKey: key,
      code: code,
      registeredAt: JsonRead.date(json['registered_at']),
      cancelledAt: JsonRead.date(json['cancelled_at']),
      attended: JsonRead.boolean(json['attended']),
      certificate: EventCertificate.fromApi(json['certificate']),
    );
  }
}

/// `ABCD-EFGH` from `abcdefgh` or `ABCD-EFGH`; a code of another length is
/// shown as it came.
String formatRegistrationCode(String code) {
  final raw = code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  return raw.length == 8 ? '${raw.substring(0, 4)}-${raw.substring(4)}' : code.trim().toUpperCase();
}
