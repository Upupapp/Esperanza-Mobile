// Verifies the fix for a real crash: selecting an image in AttachmentPicker
// on Flutter Web threw "Unsupported operation: _Namespace" because the
// preview path called `dart:io`'s `File()` on a picked file's `path` — on
// web that's a blob: URL (or absent entirely), which `File()` cannot open.
// These tests exercise AttachmentPicker directly with pre-built Attachment
// data (bypassing the actual image_picker/file_picker plugin calls, which
// don't run inside a widget test) to prove the preview now goes through
// in-memory bytes instead, with a safe fallback — never a crash — when
// bytes aren't available.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/widgets/attachment_picker.dart';

// The smallest possible valid PNG (1x1 black pixel) — real, decodable
// bytes, not a placeholder, so a successful Image.memory decode is
// actually exercised rather than assumed.
final _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x8A, 0x8B, 0x8E, 0x25, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Attachment _attachment({
  required String id,
  required String fileName,
  AttachmentCategory category = AttachmentCategory.image,
  String? localPath,
  Uint8List? bytes,
}) {
  return Attachment(
    id: id,
    fileName: fileName,
    category: category,
    sizeBytes: bytes?.length ?? 1000,
    localPath: localPath,
    bytes: bytes,
    addedAt: DateTime.now(),
    documentTypeLabel: 'Valid ID',
  );
}

void main() {
  testWidgets('an attachment with in-memory bytes previews via Image.memory — the exact scenario that used to crash on web', (tester) async {
    final attachment = _attachment(
      id: 'att-1',
      fileName: 'valid-id.png',
      // Exactly what image_picker/file_picker hand back on Flutter Web —
      // must never be passed into dart:io's File().
      localPath: 'blob:http://localhost:12345/fake-blob-id',
      bytes: _tinyPng,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AttachmentPicker(documentTypeLabel: 'Valid ID', attachments: [attachment], onAdd: (_) {}, onRemove: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('valid-id.png'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Unable to load this image. Please try another file.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an attachment restored without bytes and without a usable path shows the category icon, not a crash', (tester) async {
    // Mirrors a request restored from SharedPreferences after an app
    // restart — bytes are intentionally not persisted (see Attachment's
    // doc comment), and on Flutter Web there is no local path either.
    final attachment = _attachment(id: 'att-2', fileName: 'old-id.jpg');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AttachmentPicker(documentTypeLabel: 'Valid ID', attachments: [attachment], onAdd: (_) {}, onRemove: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('old-id.jpg'), findsOneWidget);
    expect(find.byType(Image), findsNothing); // no bytes, no path -> falls back before ever attempting a preview
    expect(find.byIcon(Icons.image_outlined), findsOneWidget); // category icon fallback
    expect(tester.takeException(), isNull);
  });

  testWidgets('bytes that fail to decode as an image show the safe inline error instead of crashing', (tester) async {
    // Deliberately not a real image — exercises the errorBuilder path
    // required by "ALSO ADD SAFE ERROR UI": a failure must never replace
    // the form with Flutter's red error screen.
    final attachment = _attachment(id: 'att-3', fileName: 'corrupt.jpg', bytes: Uint8List.fromList([1, 2, 3, 4, 5]));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AttachmentPicker(documentTypeLabel: 'Valid ID', attachments: [attachment], onAdd: (_) {}, onRemove: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('corrupt.jpg'), findsOneWidget);
    expect(find.text('Unable to load this image. Please try another file.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a non-image attachment (PDF) never attempts an image preview', (tester) async {
    final attachment = _attachment(id: 'att-3', fileName: 'requirement.pdf', category: AttachmentCategory.pdf);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AttachmentPicker(documentTypeLabel: 'Valid ID', attachments: [attachment], onAdd: (_) {}, onRemove: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('requirement.pdf'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Remove calls onRemove with the attachment id, and removing returns the requirement to its empty state', (tester) async {
    final attachment = _attachment(id: 'att-1', fileName: 'doc.pdf', category: AttachmentCategory.pdf);
    String? removedId;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AttachmentPicker(documentTypeLabel: 'Valid ID', attachments: [attachment], onAdd: (_) {}, onRemove: (id) => removedId = id),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(removedId, 'att-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Replace opens the same picker sheet as Add (camera / gallery / document)', (tester) async {
    final attachment = _attachment(id: 'att-1', fileName: 'doc.pdf', category: AttachmentCategory.pdf);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AttachmentPicker(documentTypeLabel: 'Valid ID', attachments: [attachment], onAdd: (_) {}, onRemove: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Choose a document (PDF/DOCX)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the "Add photo or document" affordance is present and never crashes an empty AttachmentPicker', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AttachmentPicker(documentTypeLabel: 'Valid ID', attachments: [], onAdd: _noopAdd, onRemove: _noopRemove),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Add photo or document'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noopAdd(Attachment _) {}
void _noopRemove(String _) {}
