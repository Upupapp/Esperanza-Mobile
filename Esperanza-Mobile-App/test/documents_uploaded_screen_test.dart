// Coverage for the new "Documents Uploaded" hamburger-menu screen: a
// read-only history of documents uploaded through Dokyu/Tulong requirement
// uploaders, reading the existing MasterFileService store (never a second
// storage system), with All/Dokyu/Tulong filter tabs and an empty state.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/screens/shared/documents_uploaded_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/widgets/esperanza_drawer.dart';

import 'support/fake_api.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';

Attachment _fakeAttachment(String fileName) => Attachment(
  id: 'att-$fileName',
  fileName: fileName,
  category: AttachmentCategory.pdf,
  sizeBytes: 12345,
  bytes: Uint8List(0),
  addedAt: DateTime(2026, 1, 1),
  documentTypeLabel: fileName,
);

Future<CitizenSessionService> _signedInAsVerifiedDemo(WidgetTester tester) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified
  return session;
}

Future<MasterFileService> _readyMasterFile(WidgetTester tester) async {
  final mf = MasterFileService();
  var attempts = 0;
  while (!mf.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('MasterFileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return mf;
}

Future<void> _pumpScreen(WidgetTester tester, {required MasterFileService masterFile}) async {
  final session = await _signedInAsVerifiedDemo(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<MasterFileService>.value(value: masterFile),
      ],
      child: const MaterialApp(home: DocumentsUploadedScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Documents Uploaded screen', () {
    testWidgets('shows an empty state when nothing has been uploaded yet', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await _pumpScreen(tester, masterFile: mf);

      expect(find.text('No documents uploaded yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lists uploaded documents with requirement name, file name, module, service, and file type', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'valid_government_id',
        label: 'One (1) valid government-issued ID',
        attachment: _fakeAttachment('id_card.pdf'),
        origin: 'Dokyu',
        serviceName: 'Barangay Clearance',
      );
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'certificate_of_enrollment',
        label: 'Certificate of Enrollment',
        attachment: _fakeAttachment('enrollment.pdf'),
        origin: 'Tulong',
        serviceName: 'Educational Assistance',
      );
      await _pumpScreen(tester, masterFile: mf);

      expect(find.text('No documents uploaded yet'), findsNothing);
      expect(find.text('One (1) valid government-issued ID'), findsOneWidget);
      expect(find.text('id_card.pdf'), findsOneWidget);
      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Certificate of Enrollment'), findsOneWidget);
      expect(find.text('enrollment.pdf'), findsOneWidget);
      expect(find.text('Educational Assistance'), findsOneWidget);
      // Module tags — both appear at least once (the tag itself; Dokyu's
      // own requirement label above may also render "Dokyu" nowhere else).
      expect(find.text('Dokyu'), findsWidgets);
      expect(find.text('Tulong'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dokyu/Tulong tabs filter the list; All shows everything', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final mf = await _readyMasterFile(tester);
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'valid_government_id',
        label: 'One (1) valid government-issued ID',
        attachment: _fakeAttachment('id_card.pdf'),
        origin: 'Dokyu',
        serviceName: 'Barangay Clearance',
      );
      await mf.saveOrUpdate(
        accountId: _verifiedDemoId,
        documentType: 'certificate_of_enrollment',
        label: 'Certificate of Enrollment',
        attachment: _fakeAttachment('enrollment.pdf'),
        origin: 'Tulong',
        serviceName: 'Educational Assistance',
      );
      await _pumpScreen(tester, masterFile: mf);

      expect(find.text('id_card.pdf'), findsOneWidget);
      expect(find.text('enrollment.pdf'), findsOneWidget);

      // .first — the segmented tab's own "Dokyu"/"Tulong" label renders
      // before each card's module tag of the same text in the tree.
      await tester.tap(find.text('Dokyu').first);
      await tester.pumpAndSettle();
      expect(find.text('id_card.pdf'), findsOneWidget);
      expect(find.text('enrollment.pdf'), findsNothing);

      await tester.tap(find.text('Tulong').first);
      await tester.pumpAndSettle();
      expect(find.text('id_card.pdf'), findsNothing);
      expect(find.text('enrollment.pdf'), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('id_card.pdf'), findsOneWidget);
      expect(find.text('enrollment.pdf'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is reachable from the hamburger drawer for a signed-in resident', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = await _signedInAsVerifiedDemo(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider(create: (_) => MasterFileService()),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ],
          child: const MaterialApp(home: Scaffold(drawer: EsperanzaDrawer())),
        ),
      );
      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Documents Uploaded'), findsOneWidget);
      await tester.tap(find.text('Documents Uploaded'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentsUploadedScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // QA run 2026-10-04 (M12h): the list showed one replacement twice and
    // none of the documents attached on the website. It now reads the
    // server's GET /citizen/uploads.
    testWidgets('lists every file attached to requests, from the app or the website, each once', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FakeApi.install((path, query) {
        if (path == '/citizen/uploads') {
          return [
            {
              'ref': 'TUL-2026-00001', 'type': 'tulong', 'service': 'Educational Assistance',
              'requirement': 'Certificate of Enrollment', 'current': true,
              'file': {'name': 'second.pdf', 'mime': 'application/pdf', 'bytes': 10, 'scan_status': 'clean', 'url': 'https://test.invalid/f/2', 'uploaded_at': '2026-10-04T03:00:00Z'},
            },
            {
              'ref': 'TUL-2026-00001', 'type': 'tulong', 'service': 'Educational Assistance',
              'requirement': 'Certificate of Enrollment', 'current': false,
              'file': {'name': 'first.pdf', 'mime': 'application/pdf', 'bytes': 10, 'scan_status': 'error', 'url': null, 'uploaded_at': '2026-10-04T02:00:00Z'},
            },
            {
              'ref': 'DOK-2026-00001', 'type': 'dokyu', 'service': 'Barangay Indigency',
              'requirement': 'Valid ID', 'current': true,
              'file': {'name': 'sent-from-the-website.pdf', 'mime': 'application/pdf', 'bytes': 10, 'scan_status': 'clean', 'url': 'https://test.invalid/f/3', 'uploaded_at': '2026-10-04T01:00:00Z'},
            },
          ];
        }
        if (path == '/citizen/papeles') return [];
        throw const FakeApiError();
      });
      addTearDown(FakeApi.restore);
      final mf = await _readyMasterFile(tester);
      await _pumpScreen(tester, masterFile: mf);

      expect(find.text('second.pdf'), findsOneWidget);
      expect(find.text('first.pdf'), findsOneWidget);
      expect(find.text('sent-from-the-website.pdf'), findsOneWidget);
      expect(find.text('Replaced'), findsOneWidget, reason: 'the file a later upload replaced');
      expect(find.text('No documents uploaded yet'), findsNothing);

      await tester.tap(find.text('Dokyu').first);
      await tester.pumpAndSettle();
      expect(find.text('sent-from-the-website.pdf'), findsOneWidget);
      expect(find.text('second.pdf'), findsNothing);

      // A file the scan has not cleared says why instead of opening.
      await tester.tap(find.text('Tulong').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('first.pdf'));
      await tester.pumpAndSettle();
      expect(find.textContaining('virus check could not run'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
