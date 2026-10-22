/// An incident report's status in residents' words, the same the staff
/// Incidents tab and the website use (scope-citizen.js INCIDENT_STATUS):
/// the server's canonical names (Processing, Completed...) mean nothing to
/// someone waiting for help.
const _incidentStatusWords = {
  'Submitted': 'Reported',
  'Under Verification': 'Validated',
  'Assigned': 'Assigned',
  'Processing': 'Dispatched',
  'Completed': 'Resolved',
  'Archived': 'Closed',
};

String incidentStatusLabel(String status) => _incidentStatusWords[status] ?? status;

/// What happened to a report, by the staff action that did it
/// (IncidentLifecycle verbs), as the website's timeline says it.
const _incidentStepWords = {
  'report': 'You reported it',
  'validate': 'Report confirmed by the office',
  'assign': 'Responders assigned',
  'dispatch': 'Responders on the way',
  'escalate': 'Marked more serious',
  'resolve': 'Resolved',
  'close': 'Closed',
};

/// The words for a timeline row: by its verb when known, else its status.
String incidentStepLabel({String? verb, String? status}) =>
    _incidentStepWords[verb] ?? incidentStatusLabel(status ?? verb ?? '');
