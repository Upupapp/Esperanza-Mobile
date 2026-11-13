import 'dart:io';

import 'package:esperanza_mobile/services/message_language.dart';
import 'package:esperanza_mobile/widgets/registry_match_note.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixes found while mapping the residents and MDRRMO flows for the office
// guides (2026-11-13).
void main() {
  tearDown(() => MessageLanguage.filipino.value = false);

  test('the registry notes follow the chosen language, as on the website', () {
    MessageLanguage.filipino.value = true;
    expect(RegistryMatchNote.atSignUp, startsWith('Nakita ka namin sa talaan ng iyong barangay.'));
    expect(RegistryMatchNote.onProfile, startsWith('May tala ka na sa talaan ng iyong barangay.'));
    MessageLanguage.filipino.value = false;
    expect(RegistryMatchNote.atSignUp, startsWith("We found you in your barangay's registry."));
  });

  test('sign-up asks to verify the email in the chosen language, not only in Filipino', () {
    final register = File('lib/screens/auth/register_screen.dart').readAsStringSync();
    expect(register, contains("if (!_emailVerified) return tr('Please verify your email before continuing.');"));
    expect(register, isNot(contains("return 'Paki-verify muna")));
  });

  test('an incident report says it came from the app', () {
    final service = File('lib/services/requests_service.dart').readAsStringSync();
    expect(service, contains("'channel': 'app',"));
  });

  test('incidents are reported, not requested, on a page named as in the menu', () {
    final list = File('lib/screens/shared/request_list_screen.dart').readAsStringSync();
    expect(list, contains("label: widget.category == ServiceCategory.sakunaIncident ? tr('Report an Incident') : 'New Request',"));
    expect(list, contains("tr('You have not reported an incident yet.')"));
    expect(File('lib/screens/sakuna/sakuna_screen.dart').readAsStringSync(), contains("title: Text(tr('Emergency'))"));
  });
}
