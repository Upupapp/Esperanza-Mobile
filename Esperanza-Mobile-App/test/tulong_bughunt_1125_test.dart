// Tulong bug hunt, 25 Nov 2026 (owner: "you may fix them"): a completed
// session, counseling or referral case is a service done, not "assistance
// received" (C4), and a closed case does not ask to replace a document (C8).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/l10n/filipino_text.dart';
import 'package:esperanza_mobile/models/service_request.dart';

void main() {
  test('a session, counseling or referral case is a service kind', () {
    for (final kind in ['session', 'counseling', 'referral']) {
      expect(TulongAssistance(processingKind: kind).isServiceKind, isTrue, reason: kind);
    }
    expect(const TulongAssistance(processingKind: 'cash').isServiceKind, isFalse);
    expect(const TulongAssistance().isServiceKind, isFalse);
  });

  test('the parser reads the kind and the card names a finished service', () {
    final parser = File('lib/services/requests_service.dart').readAsStringSync();
    expect(parser, contains("processingKind: JsonRead.nonEmpty(json['processing_kind']),"));
    final screen = File('lib/screens/shared/request_detail_screen.dart').readAsStringSync();
    expect(screen, contains("TulongStatus.completed => assistance.isServiceKind ? tr('The service is complete') : tr('Assistance received'),"));
    expect(filipinoText['The service is complete'], 'Natapos na ang serbisyo');
  });

  test('only a replaceable rejected document asks to be replaced below', () {
    final screen = File('lib/screens/shared/request_detail_screen.dart').readAsStringSync();
    expect(screen, contains('final rejected = rows.where((r) => r.isRejected && r.replaceable).length;'));
  });
}
