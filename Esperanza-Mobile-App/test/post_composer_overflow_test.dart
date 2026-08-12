// Regression test for the post composer's "BOTTOM OVERFLOWED BY 15 PIXELS"
// bug: opens PostComposerSheet with a simulated on-screen keyboard (via a
// MediaQuery viewInsets override, since driving a real platform keyboard
// isn't available in a widget test) at several device heights, types long
// multiline text, and asserts no RenderFlex/overflow exceptions were
// thrown. Actual image/video selection goes through a platform channel
// (image_picker) and can't be exercised here — see the manual QA notes in
// the PR/report for that part.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/balita/post_composer_sheet.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';

void main() {
  final sizes = <String, Size>{
    'small (320x568)': const Size(320, 568),
    'normal (360x800)': const Size(360, 800),
    'large (412x915)': const Size(412, 915),
  };

  for (final entry in sizes.entries) {
    for (final keyboardHeight in [0.0, 260.0, 340.0]) {
      testWidgets(
        'PostComposerSheet has zero overflow at ${entry.key}, keyboard inset $keyboardHeight',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final session = CitizenSessionService();
          await session.login(MockCatalog.demoAccounts.first);

          await tester.pumpWidget(
            ChangeNotifierProvider<CitizenSessionService>.value(
              value: session,
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: entry.value,
                    viewInsets: EdgeInsets.only(bottom: keyboardHeight),
                  ),
                  child: const Scaffold(body: PostComposerSheet()),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Long multiline text — the other overflow trigger named in the
          // bug report ("the composer has more vertical content").
          await tester.enterText(
            find.byType(TextField),
            List.generate(8, (i) => 'Line $i of a long simulated Balita post about Esperanza.').join('\n'),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
