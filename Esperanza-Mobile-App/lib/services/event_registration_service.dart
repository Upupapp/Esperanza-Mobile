import '../models/event_registration.dart';
import 'api_client.dart';
import 'json_read.dart';

/// Registering for an event (round 2, 2026-10-30), the same routes the
/// website's citizen Events page uses (esperanza-backend
/// CitizenEventController):
///
///   GET    /citizen/event-registrations          the resident's registrations
///   POST   /citizen/events/{key}/registration    register (409 EVENT_FULL,
///                                                422 REGISTRATION_CLOSED)
///   DELETE /citizen/events/{key}/registration    cancel
///
/// Registering also turns on the event's day-before reminder on the server;
/// cancelling leaves the reminder as it is. A refusal is shown in the
/// server's own words ([ApiException.message]).
class EventRegistrationService {
  EventRegistrationService._();

  static const eventFull = 'EVENT_FULL';
  static const registrationClosed = 'REGISTRATION_CLOSED';

  static String _path(String eventKey) => '/citizen/events/${ApiClient.segment(eventKey)}/registration';

  /// Every registration of this resident, cancelled ones included.
  static Future<List<EventRegistration>> mine() async {
    final rows = await api.getAllPages('/citizen/event-registrations');
    return JsonRead.rows(rows, EventRegistration.fromApi);
  }

  /// This resident's registration for [eventKey] that still holds a place,
  /// or null.
  static Future<EventRegistration?> forEvent(String eventKey) async {
    for (final r in await mine()) {
      if (r.eventKey == eventKey && r.active) return r;
    }
    return null;
  }

  static Future<EventRegistration> register(String eventKey) async {
    final res = await api.post(_path(eventKey));
    final registered = EventRegistration.fromApi(res.map, eventKey: eventKey);
    if (registered != null && registered.active) return registered;
    // Registered, but the reply did not carry it: read it back.
    final again = await forEvent(eventKey);
    if (again != null) return again;
    throw const ApiException(
      messageEn: 'You may be registered, but the reply could not be read. Open the event again to check.',
      messageFil: 'Maaaring nakarehistro ka na, ngunit hindi mabasa ang sagot. Buksan muli ang kaganapan para matiyak.',
    );
  }

  static Future<void> cancel(String eventKey) async {
    await api.delete(_path(eventKey));
  }

  /// The event's registration as it stands now (GET /events/{key}): how
  /// many places are left after someone else registered or cancelled.
  static Future<EventRegistrationInfo?> summary(String eventKey) async {
    final res = await api.get('/events/${ApiClient.segment(eventKey)}');
    return EventRegistrationInfo.fromApi(res.map['registration']);
  }
}
