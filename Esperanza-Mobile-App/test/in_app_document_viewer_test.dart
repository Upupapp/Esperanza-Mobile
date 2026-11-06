// Sprint 4 (owner's manual test, 2026-11-06): My Documents opens files
// INSIDE the app. A picture opens in the zoom viewer and a PDF in the new PDF
// viewer, from both the server's list (_UploadCard) and Papeles
// (_DocumentCard); before this every PDF, and every server file, went to
// another app.
//
// pdfx draws with a platform renderer that has no channel under
// `flutter test`, so the pages are swapped for a marker through
// PdfViewerScreen.debugPagesBuilder. Nothing here touches the network:
// the lists come from FakeApi and the viewer's bytes from an injected loader.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/screens/shared/documents_uploaded_screen.dart';
import 'package:esperanza_mobile/screens/shared/pdf_viewer_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/widgets/image_viewer_scaffold.dart';

import 'support/fake_api.dart';

const _pagesMarker = 'PDF PAGES';

void _fakePages() {
  PdfViewerScreen.debugPagesBuilder = (bytes, onError) => Text('$_pagesMarker ${bytes.length}');
  addTearDown(() => PdfViewerScreen.debugPagesBuilder = null);
}

Future<void> _pumpViewer(WidgetTester tester, Future<Uint8List> Function() load) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PdfViewerScreen(title: 'Certificate of Enrollment', fileName: 'enrollment.pdf', load: load),
    ),
  );
}

Future<MasterFileService> _readyMasterFile(WidgetTester tester) async {
  final mf = MasterFileService();
  var attempts = 0;
  while (!mf.loaded) {
    if (++attempts > 100) throw StateError('MasterFileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return mf;
}

Future<void> _pumpDocuments(WidgetTester tester, {MasterFileService? masterFile}) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    if (++attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last);
  final mf = masterFile ?? await _readyMasterFile(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<MasterFileService>.value(value: mf),
      ],
      child: const MaterialApp(home: DocumentsUploadedScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _upload(String name, String mime, String url) => {
  'ref': 'TUL-2026-00001',
  'type': 'tulong',
  'service': 'Educational Assistance',
  'requirement': 'Requirement $name',
  'current': true,
  'file': {'name': name, 'mime': mime, 'bytes': 10, 'scan_status': 'clean', 'url': url, 'uploaded_at': '2026-11-06T01:00:00Z'},
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PDF viewer', () {
    testWidgets('shows a loader, then the pages, and Share once the file is in', (tester) async {
      _fakePages();
      await _pumpViewer(tester, () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Uint8List.fromList(List.filled(7, 1));
      });
      await tester.pump();
      expect(find.text('$_pagesMarker 7'), findsNothing);
      final share = find.widgetWithIcon(IconButton, Icons.ios_share_rounded);
      expect(tester.widget<IconButton>(share).onPressed, isNull, reason: 'nothing to share yet');

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      expect(find.text('$_pagesMarker 7'), findsOneWidget);
      expect(find.text('Certificate of Enrollment'), findsOneWidget);
      expect(tester.widget<IconButton>(share).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a file that cannot be fetched says so, and Try Again fetches it again', (tester) async {
      _fakePages();
      var calls = 0;
      await _pumpViewer(tester, () async {
        calls++;
        if (calls == 1) throw Exception('offline');
        return Uint8List.fromList([1, 2, 3]);
      });
      await tester.pumpAndSettle();
      expect(find.text(PdfViewerScreen.errorTitle), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('$_pagesMarker 3'), findsOneWidget);
      expect(find.text(PdfViewerScreen.errorTitle), findsNothing);
    });

    testWidgets('an empty file is an error, not a blank page', (tester) async {
      _fakePages();
      await _pumpViewer(tester, () async => Uint8List(0));
      await tester.pumpAndSettle();
      expect(find.text(PdfViewerScreen.errorTitle), findsOneWidget);
      expect(find.textContaining(_pagesMarker), findsNothing);
    });

    testWidgets('a file the renderer cannot read says so, without Try Again', (tester) async {
      PdfViewerScreen.debugPagesBuilder = (bytes, onError) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onError());
        return const SizedBox();
      };
      addTearDown(() => PdfViewerScreen.debugPagesBuilder = null);
      await _pumpViewer(tester, () async => Uint8List.fromList([1]));
      await tester.pumpAndSettle();
      expect(find.text(PdfViewerScreen.unreadable), findsOneWidget);
      expect(find.text('Try Again'), findsNothing);
    });
  });

  group('My Documents opens files inside the app', () {
    testWidgets('a PDF from the server opens in the PDF viewer, a picture in the zoom viewer', (tester) async {
      _fakePages();
      FakeApi.install((path, query) {
        if (path == '/citizen/uploads') {
          return [
            _upload('enrollment.pdf', 'application/pdf', 'https://test.invalid/f/1'),
            _upload('id-front.jpg', 'image/jpeg', 'https://test.invalid/f/2'),
          ];
        }
        if (path == '/citizen/papeles') return [];
        throw const FakeApiError();
      });
      addTearDown(FakeApi.restore);
      await _pumpDocuments(tester);

      await tester.tap(find.text('enrollment.pdf'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PdfViewerScreen), findsOneWidget);
      expect(find.text('Requirement enrollment.pdf'), findsWidgets);
      Navigator.of(tester.element(find.byType(PdfViewerScreen))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('id-front.jpg'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ImageViewerScaffold), findsOneWidget);
      expect(find.byType(PdfViewerScreen), findsNothing);
    });

    testWidgets('a PDF kept on this phone opens from the phone\'s copy', (tester) async {
      _fakePages();
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: MockCatalog.demoAccounts.last.id,
        documentType: 'certificate_of_enrollment',
        label: 'Certificate of Enrollment',
        attachment: Attachment(
          id: 'att-enrollment',
          fileName: 'enrollment.pdf',
          category: AttachmentCategory.pdf,
          sizeBytes: 5,
          bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
          addedAt: DateTime(2026, 11, 6),
          documentTypeLabel: 'Certificate of Enrollment',
        ),
        origin: 'Tulong',
        serviceName: 'Educational Assistance',
      );
      await _pumpDocuments(tester, masterFile: mf);

      await tester.tap(find.text('enrollment.pdf'));
      await tester.pumpAndSettle();
      expect(find.byType(PdfViewerScreen), findsOneWidget);
      expect(find.text('$_pagesMarker 5'), findsOneWidget);
    });
  });
}
