// The app's own screens in Filipino (owner, 2026-10-23): the website's
// wording only, English where the website has none, and the LGU's Default
// Language until the resident picks one. Nothing here reaches the network.
import 'dart:io';

import 'package:esperanza_mobile/l10n/filipino_text.dart';
import 'package:esperanza_mobile/l10n/tr.dart';
import 'package:esperanza_mobile/services/message_language.dart';
import 'package:esperanza_mobile/widgets/language_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => MessageLanguage.filipino.value = false);

  test('English unless Filipino is chosen; a phrase the website lacks stays English', () {
    expect(tr('Request a Document'), 'Request a Document');
    MessageLanguage.filipino.value = true;
    expect(tr('Request a Document'), 'Humiling ng Dokumento');
    expect(tr('A phrase the website never had'), 'A phrase the website never had');
  });

  test("the LGU's default applies until the resident chooses, then the choice wins", () async {
    SharedPreferences.setMockInitialValues({});
    await MessageLanguage.load();
    expect(MessageLanguage.filipino.value, isFalse);

    await MessageLanguage.applyServerDefault('fil');
    expect(MessageLanguage.filipino.value, isTrue, reason: 'no choice yet: the LGU default');

    await MessageLanguage.set(filipino: false);
    await MessageLanguage.applyServerDefault('fil');
    expect(MessageLanguage.filipino.value, isFalse, reason: "the resident's choice wins");

    await MessageLanguage.applyServerDefault('something else');
    expect(MessageLanguage.filipino.value, isFalse);
  });

  test("the next start opens in the LGU's default before the server answers", () async {
    SharedPreferences.setMockInitialValues({'esperanza_server_default_language': 'fil'});
    await MessageLanguage.load();
    expect(MessageLanguage.filipino.value, isTrue);

    SharedPreferences.setMockInitialValues({
      'esperanza_server_default_language': 'fil',
      'esperanza_message_language': 'en',
    });
    await MessageLanguage.load();
    expect(MessageLanguage.filipino.value, isFalse, reason: 'a stored choice beats the default');
  });

  test('every Filipino entry is a phrase the app shows through tr()', () {
    final used = <String>{};
    final literal = RegExp(r"\btr\(\s*'((?:[^'\\]|\\.)*)'\s*\)");
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final m in literal.allMatches(f.readAsStringSync())) {
        used.add(m.group(1)!.replaceAllMapped(RegExp(r'\\(.)'), (x) => x.group(1)!));
      }
    }
    final stale = filipinoText.keys.where((k) => !used.contains(k)).toList();
    expect(stale, isEmpty, reason: 'run tool/l10n/build_filipino.py again');
  });

  test('status names are never translated, as on the website', () {
    for (final s in ['Submitted', 'Approved', 'Rejected', 'Released', 'Verified', 'Under Review', 'Cancelled']) {
      expect(filipinoText.containsKey(s), isFalse, reason: s);
    }
  });

  testWidgets('a screen already open redraws when the language changes', (tester) async {
    await tester.pumpWidget(
      LanguageScope(
        child: MaterialApp(
          home: Scaffold(body: Builder(builder: (_) => Text(tr('Request a Document')))),
        ),
      ),
    );
    expect(find.text('Request a Document'), findsOneWidget);

    MessageLanguage.filipino.value = true;
    await tester.pump();
    expect(find.text('Humiling ng Dokumento'), findsOneWidget);

    MessageLanguage.filipino.value = false;
    await tester.pump();
    expect(find.text('Request a Document'), findsOneWidget);
  });
}
