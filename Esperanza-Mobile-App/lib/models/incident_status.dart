import '../l10n/tr.dart';

/// An incident report's status in residents' words, the same the staff
/// Incidents tab and the website use (scope-citizen.js INCIDENT_STATUS):
/// the server's canonical names (Processing, Completed...) mean nothing to
/// someone waiting for help. In the chosen language: the words stayed
/// English in Filipino mode while the website said "Nakumpirma" (2026-11-13).
String incidentStatusLabel(String status) => switch (status) {
  'Submitted' => tr('Reported'),
  'Under Verification' => tr('Validated'),
  'Assigned' => tr('Assigned'),
  'Processing' => tr('Dispatched'),
  'Completed' => tr('Resolved'),
  'Archived' => tr('Closed'),
  _ => status,
};

/// What happened to a report, by the staff action that did it
/// (IncidentLifecycle verbs), as the website's timeline says it.
String? _incidentStepWords(String? verb) => switch (verb) {
  'report' => tr('You reported it'),
  'validate' => tr('Report confirmed by the office'),
  'assign' => tr('Responders assigned'),
  'dispatch' => tr('Responders on the way'),
  'escalate' => tr('Marked more serious'),
  'resolve' => tr('Resolved'),
  'close' => tr('Closed'),
  _ => null,
};

/// The words for a timeline row: by its verb when known, else its status.
String incidentStepLabel({String? verb, String? status}) =>
    _incidentStepWords(verb) ?? incidentStatusLabel(status ?? verb ?? '');
