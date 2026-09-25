// One unreadable record must cost that record — not a citizen's whole history.
//
// `PersistenceRecovery.discardUnreadable` is all-or-nothing by design: it
// clears an entire key. That is right for a payload that is not a collection at
// all, and much too blunt for one that is.
//
// This file used to also cover RequestsService's own persisted request list
// the same way. RequestsService no longer persists or restores anything --
// the server is the only source of truth for a request's own state now
// (production-readiness programme, 2026-09-25) -- so that recovery path no
// longer exists to regression-test; those two cases were removed rather than
// kept pointed at a decode step that no longer runs. Balita still persists
// locally, so its own entry-tolerance coverage stays.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/persistence_recovery.dart';

/// Pumps until [isLoaded], failing loudly rather than hanging the suite.
Future<void> _settle(WidgetTester tester, bool Function() isLoaded, String what) async {
  var attempts = 0;
  while (!isLoaded()) {
    attempts++;
    if (attempts > 100) {
      throw StateError('$what never finished loading.');
    }
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  setUp(PersistenceRecovery.resetForTest);

  group('A single unreadable record does not cost the whole collection', () {
    testWidgets('a malformed balita post does not empty the feed', (tester) async {
      final good = Announcement(
        id: 'post-good',
        official: 'Esperanza LGU',
        author: 'Barangay Hall',
        body: 'All residents are invited to the barangay assembly on Saturday.',
        time: '2h ago',
        likes: 0,
      ).toJson();

      SharedPreferences.setMockInitialValues({
        'esperanza_balita_posts': jsonEncode([
          {'not': 'an announcement'},
          good,
        ]),
      });

      final balita = BalitaService();
      await _settle(tester, () => balita.loaded, 'BalitaService');

      expect(balita.posts.map((p) => p.id), contains('post-good'));
    });
  });
}
