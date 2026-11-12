// "Your Document": the certificate or request slip a Dokyu request is for,
// drawn as the website draws it (barangay-certificate-preview and
// municipal-request-preview), word for word, from the request's answers. The
// app showed only the office's signed scan; it now previews the document on
// the form's Review step and offers it, with Download PDF, once approved.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/document_preview.dart';
import 'package:esperanza_mobile/models/request_release.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/document_view_screen.dart';
import 'package:esperanza_mobile/services/barangay_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/utils/document_pdf.dart';
import 'package:esperanza_mobile/widgets/document_paper.dart';
import 'package:esperanza_mobile/widgets/zoomable_document.dart';

import 'support/fake_api.dart';

String _rows(List<(String, String)> rows) => rows.map((r) => '${r.$1}: ${r.$2}').join('\n');

String _text(DocumentSheet sheet) => [
  for (final b in sheet.body)
    switch (b) {
      DocText(:final spans) => spans.map((s) => s.text).join(),
      DocPairs(:final rows) => _rows(rows),
      DocList(:final rows) => _rows(rows),
      DocInline(:final rows) => _rows(rows),
      DocBoxes(:final labels) => labels.join(' '),
      DocBox(:final rows) => [
        for (final r in rows)
          switch (r) {
            DocBar(:final labels) => labels.join(' | '),
            DocCells(:final cells) => _rows(cells),
            DocBoxList(:final rows) => _rows(rows),
          },
      ].join('\n'),
    },
].join('\n');

final _issued = IssuedDocumentInfo.fromApi({
  'control_number': 'BRGY-2026-000123',
  'serial': 'K7Q2-9XMA',
  'verify_url': 'https://esperanza.example.invalid/verify?code=K7Q2-9XMA',
  'issued_on': '2026-10-03',
})!;

ServiceRequest _request({required String status, String? serviceKey, ServiceCategory category = ServiceCategory.dokyu}) =>
    ServiceRequest(
      id: 'DR-2026-00042',
      referenceNumber: 'DR-2026-00042',
      applicantId: '',
      applicantName: '',
      typeName: 'Barangay Clearance',
      category: category,
      office: 'Barangay Hall',
      purpose: '',
      submittedAt: DateTime(2026, 10, 1),
      status: status,
      statusHistory: const [],
      attachments: const <Attachment>[],
      expectedDays: '',
      formFields: const {
        'requester_name': 'Ana Reyes Cruz',
        'age': 34,
        'residency_type': 'Permanent',
        'purok': '3',
        'purpose': ['Local Employment', 'NBI Clearance'],
      },
    )..serviceKey = serviceKey;

void main() {
  tearDown(FakeApi.restore);

  test('the punong barangay and secretary are read where the server keeps them', () {
    // GET /barangays on staging (2026-10-22): the names only inside `officials`.
    final b = BarangayInfo.fromApi({
      'name': 'Baras',
      'punong_barangay': null,
      'officials': {'punong_barangay': 'Hon. Synthetic Captain', 'barangay_secretary': 'Synthetic Secretary'},
    })!;
    expect(b.captain, 'Hon. Synthetic Captain');
    expect(b.secretary, 'Synthetic Secretary');
    expect(BarangayInfo.fromApi({'name': 'Baras', 'punong_barangay': 'Hon. Top'})!.captain, 'Hon. Top');
  });

  test('the ordinal date the paper forms use', () {
    expect(issuanceDate(DateTime(2026, 10, 1)), '1st day of October, 2026');
    expect(issuanceDate(DateTime(2026, 10, 2)), '2nd day of October, 2026');
    expect(issuanceDate(DateTime(2026, 10, 3)), '3rd day of October, 2026');
    expect(issuanceDate(DateTime(2026, 10, 11)), '11th day of October, 2026');
    expect(issuanceDate(DateTime(2026, 10, 12)), '12th day of October, 2026');
    expect(issuanceDate(DateTime(2026, 10, 13)), '13th day of October, 2026');
    expect(issuanceDate(DateTime(2026, 10, 21)), '21st day of October, 2026');
    expect(issuanceDate(DateTime(2026, 10, 22)), '22nd day of October, 2026');
  });

  test('a Barangay Clearance reads as the website\'s, filled with the answers', () {
    final sheet = buildDocument(
      documentMetas['brgy_clearance']!,
      _request(status: 'Approved').formFields,
      barangay: 'Baras',
      punongBarangay: 'Hon. Synthetic Captain',
      today: DateTime(2026, 10, 22),
    );
    expect(sheet.title, 'BARANGAY CLEARANCE');
    expect(sheet.isBarangay, isTrue);
    final text = _text(sheet);
    expect(
      text,
      contains(
        'This is to certify that Ana Reyes Cruz, 34 years of age, is a ( / ) permanent, (  ) temporary, (  ) renter resident of Purok 3, Barangay Baras, Esperanza, Masbate.',
      ),
    );
    // The paper's tick list of purposes (LABANGTATAY BRGY TEMPLATES, 2026-11-03).
    expect(text, contains('( / ) Local Employment'));
    expect(text, contains('( / ) NBI Clearance'));
    expect(text, contains('(  ) Travel Abroad'));
    expect(text, contains('no derogatory record on file in this office'));
    expect(sheet.closing, 'Given today 22nd day of October, 2026 at Barangay Baras, Esperanza, Masbate, Philippines.');
  });

  test('each certificate dates and words as its paper does (Labangtaytay templates, 2026-11-03)', () {
    final day = DateTime(2026, 11, 3);
    final late = _text(buildDocument(documentMetas['brgy_cert_late_registration']!, const {}, barangay: 'Baras', today: day));
    expect(late, contains('Issued this 3rd day of November, 2026 upon request'));
    expect(late, contains('LATE REGISTRATION of his/her birth'));
    final ftjs = _text(buildDocument(documentMetas['brgy_first_time_jobseeker']!, const {}, barangay: 'Baras', today: day));
    expect(ftjs, contains('Oath of Undertaking'));
    expect(ftjs, contains('Signed this 3rd day of November, 2026 at Barangay Baras'));
    expect(ftjs, contains('valid for one (1) year'));
  });

  test('a blank answer keeps the paper\'s line, and its own default', () {
    final text = _text(buildDocument(documentMetas['brgy_indigency']!, const {}, barangay: 'Baras'));
    expect(text, contains('This is to certify that _______________________, ___ years of age, is a (  ) permanent'));
    expect(buildDocument(documentMetas['brgy_indigency']!, const {}, barangay: 'Baras').validity, '(Indigency certificate valid three (3) months from the date of issuance)');
  });

  test('the office\'s template names the document, as on the website', () {
    final meta = documentMetas['brgy_cert_national_id']!;
    final unedited = buildDocument(
      meta,
      const {},
      barangay: 'Baras',
      template: const DocumentTemplate(title: 'CERTIFICATION', subtitle: '', note: 'Valid for 6 months.'),
    );
    expect(unedited.title, 'CERTIFICATION');
    expect(unedited.subtitle, 'For Registration of National ID', reason: 'a version-1 template keeps the built-in subtitle');
    expect(unedited.note, 'Valid for 6 months.');
    final edited = buildDocument(
      meta,
      const {},
      barangay: 'Baras',
      template: const DocumentTemplate(subtitle: 'For PhilSys', version: 2),
    );
    expect(edited.title, 'BARANGAY CERTIFICATION');
    expect(edited.subtitle, 'For PhilSys');
  });

  test('every document the website draws builds, barangay and municipal', () {
    expect(documentMetas.length, 27);
    for (final meta in documentMetas.values) {
      final sheet = buildDocument(meta, const {}, barangay: 'Baras');
      expect(sheet.body, isNotEmpty, reason: meta.key);
      expect(sheet.isBarangay, meta.key.startsWith('brgy_'), reason: meta.key);
    }
    expect(buildDocument(documentMetas['dokyu_indigency']!, const {}, barangay: 'X').disclaimer, contains('Municipal Social Welfare'));
  });

  test("Your Document leaves out the slip's form number and signatories, as the website's Track Request", () {
    final pet = documentMetas['municipal_pet_registration']!;
    expect(pet.technician, isNotNull, reason: 'the request form preview names them');
    final issued = pet.asIssued;
    expect([issued.formNo, issued.officiant, issued.technician, issued.verifier], everyElement(isNull));
    expect(issued.office, pet.office);
    expect(issued.title, pet.title);
  });

  test('a filed request is completed as the website completes it', () {
    final data = documentData(
      documentMetas['brgy_clearance']!,
      const {'purpose': <String>[], 'age': ''},
      fullName: 'Ana Reyes Cruz',
      birthdate: '1992-04-05',
      purok: 'Purok 3',
      sex: 'Female',
    );
    expect(data['requester_name'], 'Ana Reyes Cruz');
    expect(data['purok'], '3');
    expect(data['sex'], 'Female');
    expect(data['citizenship'], 'Filipino');
    expect(data['age'], isA<int>());
    expect(data.containsKey('purpose'), isFalse, reason: 'an empty answer is no answer');
    final filed = documentData(documentMetas['brgy_clearance']!, const {'requester_name': 'For My Mother'}, fullName: 'Ana');
    expect(filed['requester_name'], 'For My Mother', reason: 'what was filed wins');
  });

  testWidgets('the page is the website\'s A4 sheet: wording, signatures and, once issued, the control number', (tester) async {
    final sheet = buildDocument(
      documentMetas['brgy_clearance']!,
      _request(status: 'Released').formFields,
      barangay: 'Baras',
      punongBarangay: 'Hon. Synthetic Captain',
      barangaySecretary: 'Synthetic Secretary',
      issued: _issued,
      today: DateTime(2026, 10, 3),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: DocumentPaper(sheet: sheet)))));
    expect(find.text('BARANGAY CLEARANCE'), findsOneWidget);
    expect(find.text('BARANGAY BARAS'), findsOneWidget);
    expect(find.text('TO WHOM IT MAY CONCERN:'), findsOneWidget);
    expect(find.textContaining('Ana Reyes Cruz', findRichText: true), findsOneWidget);
    // Signed as the Clearance paper is: the Punong Barangay's name without "Hon.",
    // the resident's line and thumbmark box, "Released by" the Secretary.
    expect(find.text('SYNTHETIC CAPTAIN'), findsOneWidget);
    expect(find.text('Resident Signature'), findsOneWidget);
    expect(find.text('Right Thumbmark'), findsOneWidget);
    expect(find.textContaining('SYNTHETIC SECRETARY', findRichText: true), findsOneWidget);
    expect(find.textContaining('BRGY-2026-000123', findRichText: true), findsOneWidget);
    expect(find.text('Not Valid without Barangay Seal'), findsOneWidget);
    // An A4 page (794 x 1123), scaled to the screen.
    final page = tester.getSize(find.byType(DocumentPage));
    expect(page.width, DocumentPage.width);
    expect(page.height, greaterThanOrEqualTo(DocumentPage.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the PDF is the page as drawn, for a certificate and for each kind of slip', (tester) async {
    for (final key in ['brgy_clearance', 'dokyu_cedula', 'municipal_pet_registration', 'mcro_marriage_license']) {
      final capture = GlobalKey();
      final sheet = buildDocument(documentMetas[key]!, _request(status: 'Approved').formFields, barangay: 'Baras', issued: _issued);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: DocumentPaper(sheet: sheet, captureKey: capture)))),
      );
      expect(tester.takeException(), isNull, reason: key);
      final bytes = await tester.runAsync(() async => DocumentPdf.fromPng(await DocumentPdf.capture(capture), title: sheet.title));
      expect(String.fromCharCodes(bytes!.take(4)), '%PDF', reason: key);
    }
  });

  testWidgets('every document draws as a page without error', (tester) async {
    for (final meta in documentMetas.values) {
      final sheet = buildDocument(meta, _request(status: 'Approved').formFields, barangay: 'Baras', issued: _issued);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: DocumentPaper(sheet: sheet)))));
      expect(tester.takeException(), isNull, reason: meta.key);
      expect(find.text(sheet.title.toUpperCase()), findsWidgets, reason: meta.key);
    }
  });

  testWidgets('the page zooms: pinch in and out, double-tap in and back', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sheet = buildDocument(documentMetas['brgy_clearance']!, _request(status: 'Approved').formFields, barangay: 'Baras');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ZoomableDocument(sheet: sheet))));
    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.maxScale, ZoomableDocument.maxScale);
    expect(viewer.minScale, lessThan(1), reason: 'zooming out shows the whole page');
    double scale() => viewer.transformationController!.value.getMaxScaleOnAxis();

    // Double-tap: in, then back to the whole width.
    final page = find.byType(DocumentPaper);
    await tester.tap(page);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(page);
    await tester.pumpAndSettle();
    expect(scale(), closeTo(ZoomableDocument.doubleTapScale, 0.01));
    await tester.tap(page);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(page);
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1, 0.01));

    // Two fingers apart: zoom in; together: zoom out.
    final c = tester.getCenter(page);
    Future<void> pinch(double from, double to) async {
      final a = await tester.startGesture(c - Offset(from, 0));
      final b = await tester.startGesture(c + Offset(from, 0));
      await tester.pump();
      for (var i = 1; i <= 5; i++) {
        final d = from + (to - from) * i / 5;
        await a.moveTo(c - Offset(d, 0));
        await b.moveTo(c + Offset(d, 0));
        await tester.pump();
      }
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
    }

    await pinch(40, 120);
    final zoomedIn = scale();
    expect(zoomedIn, greaterThan(1.5));
    await pinch(120, 40);
    expect(scale(), lessThan(zoomedIn));
    // Out below the screen's width: the page settles in the middle.
    await tester.tap(page);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(page);
    await tester.pumpAndSettle();
    if (scale() > 1.01) {
      await tester.tap(page);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(page);
      await tester.pumpAndSettle();
    }
    // Past the double-tap wait, so the next touch is a pinch.
    await tester.pump(const Duration(milliseconds: 500));
    await pinch(120, 40);
    expect(scale(), lessThan(1));
    final m = viewer.transformationController!.value;
    final left = m.getTranslation().x;
    final right = 390 - (left + 390 * scale());
    expect(left, closeTo(right, 1), reason: 'centred');
    expect(tester.takeException(), isNull);
  });

  group('Track Request', () {
    Future<void> pump(WidgetTester tester, ServiceRequest r) async {
      // A phone-tall screen: the paper is longer than the default 800x600.
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      FakeApi.installFull((_) => <dynamic>[]);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CitizenSessionService(),
          child: MaterialApp(
            home: Scaffold(body: DocumentReadyCard(request: r, accent: AppColors.brand600)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an approved request offers its document', (tester) async {
      await pump(tester, _request(status: 'Approved', serviceKey: 'brgy_clearance'));
      expect(find.text('Your document is ready'), findsOneWidget);
      expect(find.text('View Document'), findsOneWidget);
      await tester.tap(find.text('View Document'));
      await tester.pumpAndSettle();
      expect(find.text('Your Document'), findsOneWidget);
      expect(find.text('BARANGAY CLEARANCE'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);
    });

    testWidgets('a released one says so', (tester) async {
      await pump(tester, _request(status: 'Released', serviceKey: 'brgy_clearance'));
      expect(find.text('Your document has been released'), findsOneWidget);
    });

    testWidgets('a document the website does not draw sends the resident to the office', (tester) async {
      await pump(tester, _request(status: 'Approved', serviceKey: 'mcro_some_new_service'));
      expect(find.textContaining("Online preview isn't available"), findsOneWidget);
      expect(find.text('View Document'), findsNothing);
    });

    test('only at the statuses the website offers it', () {
      expect(documentReadyStatuses, {'Approved', 'Mark to Release', 'Released'});
      expect(documentMetaFor(_request(status: 'Approved', serviceKey: 'brgy_clearance')), isNotNull);
      expect(
        documentMetaFor(_request(status: 'Approved', serviceKey: 'brgy_clearance', category: ServiceCategory.tulong)),
        isNull,
      );
    });
  });
}
