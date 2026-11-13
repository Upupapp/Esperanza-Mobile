import 'dart:io';

import 'package:esperanza_mobile/models/incident_status.dart';
import 'package:esperanza_mobile/services/message_language.dart';
import 'package:flutter_test/flutter_test.dart';

// Incident words follow the chosen language, as the website's do: they stayed
// English in Filipino mode, and the notification list showed the server's raw
// status ("Under Verification") for a report (2026-11-13).
void main() {
  tearDown(() => MessageLanguage.filipino.value = false);

  test('incident statuses and steps in Filipino and in English', () {
    MessageLanguage.filipino.value = true;
    expect(incidentStatusLabel('Under Verification'), 'Nakumpirma');
    expect(incidentStatusLabel('Processing'), 'Papunta na ang tutugon');
    expect(incidentStepLabel(verb: 'report'), 'Iniulat mo');
    MessageLanguage.filipino.value = false;
    expect(incidentStatusLabel('Under Verification'), 'Validated');
    expect(incidentStatusLabel('Processing'), 'Dispatched');
    expect(incidentStatusLabel('Something new'), 'Something new');
  });

  test('a Sakuna notice shows the incident words, not the raw status', () {
    final screen = File('lib/screens/notifications/notifications_screen.dart').readAsStringSync();
    expect(screen, contains("if (label == null || n.category == 'sakuna') return null;"));
    expect(screen, contains("n.category == 'sakuna' && n.status != null ? incidentStatusLabel(n.status!) : n.kind.badgeLabel"));
  });

  test('the alert button and the event reminder are translated', () {
    expect(File('lib/widgets/sakuna_alerts_ui.dart').readAsStringSync(), contains("Text(tr('Open Sakuna'))"));
    final event = File('lib/screens/events/event_detail_screen.dart').readAsStringSync();
    expect(event, contains("tr('Remind me a day before')"));
    expect(event, contains("tr('Reminder turned off.')"));
  });
}
