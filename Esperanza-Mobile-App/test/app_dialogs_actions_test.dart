// Confirm sheets put cancel and confirm side by side only when both labels
// fit; otherwise they stack full width, confirm on top, so a long action
// ("View Existing Request") is never cut to "View Existing R…".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/widgets/app_dialogs.dart';

Future<void> _open(WidgetTester tester, String confirmLabel) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => AppDialogs.confirm(context, title: 'T', message: 'M', confirmLabel: confirmLabel, cancelLabel: 'Close'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('short labels sit side by side', (tester) async {
    await _open(tester, 'Remove');
    final cancel = tester.getCenter(find.text('Close'));
    final confirm = tester.getCenter(find.text('Remove'));
    expect(cancel.dy, confirm.dy);
    expect(cancel.dx, lessThan(confirm.dx));
  });

  testWidgets('a long confirm label stacks full width, confirm on top, and is not ellipsized to half width', (tester) async {
    await _open(tester, 'View Existing Request');
    final cancel = tester.getCenter(find.text('Close'));
    final confirm = tester.getCenter(find.text('View Existing Request'));
    expect(confirm.dy, lessThan(cancel.dy));
    expect(confirm.dx, closeTo(cancel.dx, 1));
    // Full width: the confirm button spans the sheet, not half of it. (The
    // test font's wide glyphs would truncate even this, so the label itself
    // is checked by width, not by ellipsis.)
    final button = find.ancestor(of: find.text('View Existing Request'), matching: find.byType(Material)).first;
    expect(tester.getSize(button).width, greaterThan(300));
  });
}
