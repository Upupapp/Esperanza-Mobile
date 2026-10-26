import 'api_client.dart';
import 'json_read.dart';

/// An office's appointment schedule a resident can book (esperanza-backend
/// AppointmentsController::scheduleRow, scope round 2026-10-15).
class AppointmentSchedule {
  const AppointmentSchedule({
    required this.id,
    required this.place,
    required this.label,
    this.service,
    this.serviceKey,
    this.office,
    this.weekdays = const [],
    this.startTime,
    this.endTime,
    this.location,
    this.notes,
    this.bookDaysAhead = 14,
  });

  final int id;

  /// The office (or barangay hall) as residents know it.
  final String place;
  final String label;
  final String? service;

  /// The service this schedule is for, and its office: a request's booking
  /// picks the schedule that matches it, as on the website.
  final String? serviceKey;
  final String? office;

  /// ISO weekdays it is open, 1 = Monday.
  final List<int> weekdays;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? notes;

  /// How far ahead the office takes bookings, in days (`book_days_ahead`);
  /// 14 when it does not say, never more than 62, as on the website.
  final int bookDaysAhead;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// "Mon–Fri · 8:00 AM – 5:00 PM", or what part of it is known.
  String get openText {
    final sorted = [
      for (final d in weekdays)
        if (d >= 1 && d <= 7) d,
    ]..sort();
    final days = [for (final d in sorted) _days[d - 1]];
    final range = days.length > 2 && sorted.last - sorted.first == days.length - 1
        ? '${days.first}–${days.last}'
        : days.join(', ');
    final hours = startTime != null && endTime != null ? '${clock(startTime!)} – ${clock(endTime!)}' : '';
    return [range, hours].where((s) => s.isNotEmpty).join(' · ');
  }

  static AppointmentSchedule? fromApi(Map<String, dynamic> json) {
    final id = JsonRead.integer(json['id']);
    final place = JsonRead.nonEmpty(json['place']) ?? JsonRead.nonEmpty(json['office']);
    if (id == null || place == null) return null;
    return AppointmentSchedule(
      id: id,
      place: place,
      label: JsonRead.nonEmpty(json['label']) ?? place,
      service: JsonRead.nonEmpty(json['service']),
      serviceKey: JsonRead.nonEmpty(json['service_key']),
      office: JsonRead.nonEmpty(json['office']),
      weekdays: [for (final d in JsonRead.list(json['weekdays'])) ?JsonRead.integer(d)],
      startTime: JsonRead.nonEmpty(json['start_time']),
      endTime: JsonRead.nonEmpty(json['end_time']),
      location: JsonRead.nonEmpty(json['location']),
      notes: JsonRead.nonEmpty(json['notes']),
      bookDaysAhead: (JsonRead.integer(json['book_days_ahead']) ?? 14).clamp(1, 62),
    );
  }
}

/// One day of a schedule: closed (with why), or its bookable times.
class AppointmentDay {
  const AppointmentDay({required this.date, this.closedReason, this.slots = const []});

  final DateTime date;
  final String? closedReason;
  final List<AppointmentSlot> slots;

  bool get hasOpenSlot => closedReason == null && slots.any((s) => s.left > 0);

  static AppointmentDay? fromApi(Map<String, dynamic> json) {
    final date = JsonRead.date(json['date']);
    if (date == null) return null;
    return AppointmentDay(
      date: date,
      closedReason: JsonRead.nonEmpty(json['closed']),
      slots: JsonRead.rows(json['slots'], AppointmentSlot.fromApi),
    );
  }
}

class AppointmentSlot {
  const AppointmentSlot({required this.start, required this.end, required this.left});

  /// "HH:MM", Esperanza time.
  final String start;
  final String end;

  /// Places still free at this time.
  final int left;

  static AppointmentSlot? fromApi(Map<String, dynamic> json) {
    final start = JsonRead.nonEmpty(json['start']);
    final end = JsonRead.nonEmpty(json['end']);
    if (start == null || end == null) return null;
    return AppointmentSlot(start: start, end: end, left: JsonRead.integer(json['left']) ?? 0);
  }
}

/// A booked appointment. Its status is the appointment book's own closed set
/// (Booked, Confirmed, Completed, Cancelled, No Show), apart from a request's
/// status - never routed through AppStatus.
class Appointment {
  const Appointment({
    required this.ref,
    required this.status,
    required this.date,
    this.startTime,
    this.endTime,
    this.when,
    this.place,
    this.schedule,
    this.location,
    this.service,
    this.requestRef,
    this.purpose,
    this.cancelReason,
    this.cancelledBy,
    this.canCancel = false,
  });

  final String ref;
  final String status;
  final DateTime date;
  final String? startTime;
  final String? endTime;

  /// The server's own wording of the date and time.
  final String? when;
  final String? place;
  final String? schedule;
  final String? location;
  final String? service;
  final String? requestRef;
  final String? purpose;
  final String? cancelReason;
  final String? cancelledBy;
  final bool canCancel;

  static const statuses = ['Booked', 'Confirmed', 'Completed', 'Cancelled', 'No Show'];

  /// Booked or confirmed, and not yet past: a past booking that was never
  /// marked is history, not upcoming (as on the website).
  bool get upcoming {
    if (status != 'Booked' && status != 'Confirmed') return false;
    final now = DateTime.now();
    return !DateTime(date.year, date.month, date.day).isBefore(DateTime(now.year, now.month, now.day));
  }

  static Appointment? fromApi(Map<String, dynamic> json) {
    final ref = JsonRead.nonEmpty(json['ref']);
    final date = JsonRead.date(json['date']);
    final status = JsonRead.nonEmpty(json['status']);
    if (ref == null || date == null || status == null) return null;
    return Appointment(
      ref: ref,
      status: status,
      date: date,
      startTime: JsonRead.nonEmpty(json['start_time']),
      endTime: JsonRead.nonEmpty(json['end_time']),
      when: JsonRead.nonEmpty(json['when']),
      place: JsonRead.nonEmpty(json['place']) ?? JsonRead.nonEmpty(json['office']),
      schedule: JsonRead.nonEmpty(json['schedule']),
      location: JsonRead.nonEmpty(json['location']),
      service: JsonRead.nonEmpty(json['service']),
      requestRef: JsonRead.nonEmpty(json['request_ref']),
      purpose: JsonRead.nonEmpty(json['purpose']),
      cancelReason: JsonRead.nonEmpty(json['cancel_reason']),
      cancelledBy: JsonRead.nonEmpty(json['cancelled_by']),
      canCancel: JsonRead.boolean(json['can_cancel']) ?? false,
    );
  }
}

/// "14:30" → "2:30 PM".
String clock(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.first) ?? 0;
  final m = parts.length > 1 ? parts[1].padLeft(2, '0').substring(0, 2) : '00';
  final hour = h % 12 == 0 ? 12 : h % 12;
  return '$hour:$m ${h < 12 ? 'AM' : 'PM'}';
}

/// Booking a time with an office (esperanza-backend AppointmentsController,
/// scope round 2026-10-15): the schedules open to the resident, a schedule's
/// free times, booking, the resident's own appointments, and cancelling one.
class AppointmentsService {
  AppointmentsService._();

  /// The server's refusals, in words a resident can act on (the web
  /// portal's own wording, resources/js/scope-citizen.js).
  static const refusals = {
    'ACCOUNT_NOT_VERIFIED': 'Your account must be verified before you book an appointment.',
    'SLOT_FULL': 'That time was just taken. Please choose another time.',
    'ALREADY_BOOKED': 'You already have this time booked.',
    'TOO_MANY_APPOINTMENTS': 'You can hold up to three upcoming appointments. Cancel one first.',
    'NOT_YOUR_REQUEST': 'That request reference is not one of yours.',
    'SLOT_NOT_OFFERED': 'That time is no longer open for booking. Please choose another.',
    'NOT_CANCELLABLE': 'This appointment can no longer be cancelled.',
    'ALREADY_STARTED': 'The appointment time has passed, so it can no longer be cancelled.',
  };

  static String explain(ApiException e) => refusals[e.code] ?? e.message();

  static Future<List<AppointmentSchedule>> schedules() async {
    final res = await api.get('/citizen/appointments/schedules');
    return JsonRead.rows(res.data, AppointmentSchedule.fromApi);
  }

  /// The office's free times from today to its own booking window ahead
  /// (up to 62 days, as the website asks); without dates the server gave 14.
  static Future<List<AppointmentDay>> availability(int scheduleId, {int daysAhead = 14}) async {
    String day(int offset) {
      final d = DateTime.now().add(Duration(days: offset));
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    final res = await api.get(
      '/citizen/appointments/schedules/${ApiClient.segment(scheduleId)}/availability',
      query: {'from': day(0), 'to': day(daysAhead.clamp(1, 62))},
    );
    return JsonRead.rows(res.map['days'], AppointmentDay.fromApi);
  }

  static Future<List<Appointment>> mine() async {
    final res = await api.get('/citizen/appointments');
    return JsonRead.rows(res.data, Appointment.fromApi);
  }

  static Future<Appointment> book({
    required int scheduleId,
    required DateTime date,
    required String startTime,
    required String purpose,
    String? requestRef,
  }) async {
    final res = await api.post(
      '/citizen/appointments',
      body: {
        'schedule_id': scheduleId,
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'start_time': startTime,
        'purpose': purpose.trim(),
        'request_ref': ?requestRef,
      },
    );
    final booked = Appointment.fromApi(res.map);
    if (booked == null) {
      throw const ApiException(
        messageEn:
            'Your appointment was booked, but the reply could not be read. Pull down to refresh your appointments.',
        messageFil: 'Na-book ang iyong appointment, ngunit hindi mabasa ang sagot. Hilahin pababa para i-refresh.',
      );
    }
    return booked;
  }

  static Future<Appointment?> cancel(String ref, {String? reason}) async {
    final res = await api.post(
      '/citizen/appointments/${ApiClient.segment(ref)}/cancel',
      body: {if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim()},
    );
    return Appointment.fromApi(res.map);
  }
}
