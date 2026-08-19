// Verifies the Esperanza-styled explanation dialog shown before any
// protected device access (camera / photos / document) — correct
// title/message/buttons per action, and that "Not Now" cleanly returns to
// the form without ever attempting the actual system picker. The
// "Continue" -> real image_picker/file_picker/permission_handler path
// isn't exercised here: those plugins have no platform-channel handler
// under `flutter test` (true of this whole project already — no existing
// test taps through to a real picker call either), so that half of the
// flow is manual/device-QA territory, same as it always was for the
// underlying pickers themselves.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/widgets/attachment_picker.dart';

Future<void> _openPickerSheet(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AttachmentPicker(documentTypeLabel: 'Valid ID', attachments: const [], onAdd: (_) {}, onRemove: (_) {}),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add photo or document'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Take a photo shows the Camera Access Required explanation before anything else', (tester) async {
    await _openPickerSheet(tester);

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(find.text('Camera Access Required'), findsOneWidget);
    expect(
      find.text('Esperanza needs access to your camera so you can take a photo and attach it to your request.'),
      findsOneWidget,
    );
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Choose from gallery shows the Photo Access Required explanation', (tester) async {
    await _openPickerSheet(tester);

    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Photo Access Required'), findsOneWidget);
    expect(
      find.text('Esperanza needs access to your photos so you can select an image to attach to your request.'),
      findsOneWidget,
    );
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Choose a document shows the Document Access explanation, never a broad storage warning', (tester) async {
    await _openPickerSheet(tester);

    await tester.tap(find.text('Choose a document (PDF/DOCX)'));
    await tester.pumpAndSettle();

    expect(find.text('Document Access'), findsOneWidget);
    expect(
      find.text('Esperanza needs permission to let you choose a document to attach to your request.'),
      findsOneWidget,
    );
    expect(find.textContaining('all your files'), findsNothing);
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Not Now closes the explanation and returns to the form untouched — no attachment added, no error', (tester) async {
    Attachment? added;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AttachmentPicker(documentTypeLabel: 'Valid ID', attachments: const [], onAdd: (a) => added = a, onRemove: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add photo or document'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.text('Camera Access Required'), findsOneWidget);

    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();

    expect(find.text('Camera Access Required'), findsNothing);
    // Back on the plain empty-picker form — not a broken/blocked screen.
    expect(find.text('Add photo or document'), findsOneWidget);
    expect(added, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the explanation dialog uses the existing Esperanza confirm-sheet styling (rounded sheet, primary/secondary buttons)', (tester) async {
    await _openPickerSheet(tester);
    await tester.tap(find.text('Choose a document (PDF/DOCX)'));
    await tester.pumpAndSettle();

    // Same bottom-sheet shell every other Esperanza confirmation uses
    // (AppDialogs.confirm), not a bespoke error-style AlertDialog.
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
