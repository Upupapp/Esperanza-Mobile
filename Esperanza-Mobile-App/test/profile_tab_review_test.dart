// The Profile tab's side-by-side review (Settings, Digital ID, Privacy
// Policy, Help & Support): controls that did nothing, and copy that stopped
// being true once the app reached the real backend.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/profile/settings_screen.dart';
import 'package:esperanza_mobile/services/notification_preferences_service.dart';
import 'package:esperanza_mobile/utils/app_version.dart';

import 'support/fake_api.dart';

List<Map<String, dynamic>> _rows({bool dokyuSms = false}) => [
  {
    'category': 'dokyu',
    'label': {'en': 'Document request updates', 'fil': 'Update sa mga kahilingang dokumento'},
    'in_app': true,
    'sms': dokyuSms,
    'email': false,
  },
  {
    'category': 'sakuna',
    'label': {'en': 'Emergency alerts', 'fil': 'Mga alerto sa emergency'},
    'in_app': true,
    'sms': true,
    'email': false,
  },
  {'label': 'no category: skipped, not fatal'},
];

Future<void> _pumpSettings(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
  await tester.pumpAndSettle();
}

Finder _chip(String category, String label) => find.descendant(
  of: find.ancestor(of: find.text(category), matching: find.byType(Column)).first,
  matching: find.widgetWithText(FilterChip, label),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  group('notification preferences', () {
    test('parse the server rows and skip a malformed one', () async {
      FakeApi.installFull((r) => {'preferences': _rows()});
      final list = await NotificationPreferencesService.fetch();
      expect(list.map((p) => p.category), ['dokyu', 'sakuna']);
      expect(list.first.labelEn, 'Document request updates');
      expect(list.last.sms, isTrue);
    });

    testWidgets('Settings shows the server categories, and a tap saves just that one', (tester) async {
      final sent = <FakeApiRequest>[];
      FakeApi.installFull((r) {
        sent.add(r);
        return {'preferences': _rows(dokyuSms: r.method == 'PUT')};
      });
      await _pumpSettings(tester);

      expect(find.text('Document request updates'), findsOneWidget);
      expect(find.text('Emergency alerts'), findsOneWidget);
      // The old controls were widget state only; nothing may bring them back.
      expect(find.text('Push notifications'), findsNothing);
      expect(find.text('Filipino'), findsNothing);

      await tester.tap(_chip('Document request updates', 'Text (SMS)'));
      await tester.pumpAndSettle();

      final put = sent.singleWhere((r) => r.method == 'PUT');
      expect(put.path, '/citizen/notification-preferences');
      expect(put.body, {
        'preferences': [
          {'category': 'dokyu', 'in_app': true, 'sms': true, 'email': false},
        ],
      });
      expect(tester.widget<FilterChip>(_chip('Document request updates', 'Text (SMS)')).selected, isTrue);
    });

    testWidgets('a failed save puts the switch back and says why', (tester) async {
      FakeApi.installFull((r) {
        if (r.method == 'PUT') throw const FakeApiError(status: 500, code: 'SERVER_ERROR', messageEn: 'Server trouble');
        return {'preferences': _rows()};
      });
      await _pumpSettings(tester);
      await tester.tap(_chip('Document request updates', 'Email'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(_chip('Document request updates', 'Email')).selected, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('a failed load offers Try Again', (tester) async {
      var calls = 0;
      FakeApi.installFull((r) {
        if (calls++ == 0) throw const FakeApiError(status: 500, code: 'SERVER_ERROR');
        return {'preferences': _rows()};
      });
      await _pumpSettings(tester);
      expect(find.text('Document request updates'), findsNothing);
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.text('Document request updates'), findsOneWidget);
    });
  });

  test('the version shown to citizens matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*([^\s+]+)', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });

  test('citizen-facing copy no longer claims the app is a demo that sends nothing', () {
    // Each of these was on screen after 2026-09-25, when every one became
    // false. The demo-account ID wallet and the simulated face scan keep
    // their notes, because those still are simulations.
    const retired = {
      'lib/screens/legal/privacy_policy_screen.dart': 'does not currently connect to any external backend',
      'lib/screens/profile/settings_screen.dart': 'Frontend Preview Build',
      'lib/screens/support/help_support_screen.dart': 'Frontend Preview Build',
      'lib/screens/auth/register_screen.dart': 'no data leaves your device',
    };
    for (final e in retired.entries) {
      expect(File(e.key).readAsStringSync(), isNot(contains(e.value)), reason: e.key);
    }
  });
}
