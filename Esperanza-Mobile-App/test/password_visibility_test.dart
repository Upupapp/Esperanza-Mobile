// Every password field can show what was typed (owner, 2026-10-12: on the app
// and the web portal alike). AppTextField carries the eye for any password it
// draws; the sign-in screen has its own.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/screens/profile/change_password_screen.dart';
import 'package:esperanza_mobile/widgets/app_text_field.dart';

void main() {
  testWidgets("a password field's eye shows and hides what was typed", (tester) async {
    final controller = TextEditingController(text: 'S3cret!pass');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AppTextField(label: 'Password', controller: controller, obscureText: true))));
    bool hidden() => tester.widget<TextField>(find.byType(TextField)).obscureText;

    expect(hidden(), isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(hidden(), isFalse);
    // Shown, it is still a password: no autocorrect, no learned suggestions.
    expect(tester.widget<TextField>(find.byType(TextField)).autocorrect, isFalse);
    expect(tester.widget<TextField>(find.byType(TextField)).enableSuggestions, isFalse);

    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(hidden(), isTrue);
  });

  testWidgets('an ordinary field has no eye', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AppTextField(label: 'Name'))));
    expect(find.byTooltip('Show password'), findsNothing);
  });

  testWidgets('Change password: each of its three password fields has an eye', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show password'), findsNWidgets(3));
  });

  test('every hidden-text field in the app is one that has an eye', () {
    // A raw TextField with obscureText would be a password field with no way
    // to see what was typed. Only AppTextField (which adds the eye) and the
    // sign-in screen's field (which has its own) may set it.
    const allowed = {'lib/widgets/app_text_field.dart', 'lib/screens/auth/login_screen.dart'};
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      if (allowed.contains(path)) continue;
      final source = file.readAsStringSync();
      // Fields drawn with AppTextField pass obscureText to it, not to a TextField.
      final raw = RegExp(r'(?<![A-Za-z])(TextFormField|TextField)\([^;]*obscureText', dotAll: true);
      expect(raw.hasMatch(source), isFalse, reason: '$path draws a password field without the eye; use AppTextField');
    }
  });
}
