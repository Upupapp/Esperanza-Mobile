// QA sweep 2026-11-18, assignment app-3: the Emergency tab's report form
// reached even when the past reports cannot be read, an incident refusal
// that names its field, a refused incident photo, the previous resident's
// requests kept off the phone after sign-out, the cancel-appointment dialog,
// a Balita post opened by its id, requirement files (size and View), the
// date filter's day, "Your Document" for a paper about someone else, the
// offline pill and the centre launcher for a screen reader. Synthetic data;
// the API is faked.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/document_preview.dart';
import 'package:esperanza_mobile/models/request_filters.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/appointments/appointments_screen.dart';
import 'package:esperanza_mobile/screens/sakuna/report_incident_screen.dart';
import 'package:esperanza_mobile/screens/sakuna/sakuna_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_list_screen.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/json_read.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/utils/requirement_document_type.dart';
import 'package:esperanza_mobile/widgets/app_text_field.dart';
import 'package:esperanza_mobile/widgets/esperanza_center_action.dart';
import 'package:esperanza_mobile/widgets/image_viewer_scaffold.dart';
import 'package:esperanza_mobile/widgets/new_request_fab.dart';
import 'package:esperanza_mobile/widgets/offline_notice.dart';
import 'package:esperanza_mobile/widgets/requirement_uploader.dart';

import 'support/fake_api.dart';

/// The envelope a 422 carries, with the field's own reason, which
/// [FakeApiError] has no way to send.
http.Response _refusal(String field, String reason) => http.Response(
  jsonEncode({
    'error': {
      'code': 'VALIDATION_FAILED',
      'message': {'en': 'Some fields need to be corrected.', 'fil': 'May mga kailangang itama.'},
      'fields': {
        field: [reason],
      },
    },
  }),
  422,
  headers: {'content-type': 'application/json'},
);

http.Response _ok(Object? data) =>
    http.Response(jsonEncode({'data': data}), 200, headers: {'content-type': 'application/json'});

/// [api] on a client whose answers [handler] writes in full.
void _installRaw(http.Response Function(http.Request request) handler) {
  api = ApiClient(httpClient: MockClient((r) async => handler(r)), baseUrl: 'https://test.invalid');
}

Map<String, dynamic> _requestRow(String ref) => {
  'ref': ref,
  'type': 'dokyu',
  'service': 'Barangay Clearance',
  'status': 'Submitted',
  'submitted': '2026-11-17T23:30:00+00:00',
};

Map<String, dynamic> _incidentRow(String ref) => {
  'ref': ref,
  'title': 'Flooding — Poblacion',
  'type': 'Flooding',
  'severity': 'High',
  'barangay': 'Poblacion',
  'status': 'Submitted',
  'reported': '2026-11-18T01:00:00+08:00',
};

Map<String, dynamic> _appointment() => {
  'ref': 'APT-2026-000101',
  'status': 'Booked',
  'date': '2030-10-22',
  'start_time': '09:00',
  'end_time': '09:30',
  'when': 'Tue, Oct 22, 2030, 9:00 AM',
  'office': 'Municipal Civil Registrar',
  'place': 'Municipal Civil Registrar',
  'schedule': 'Claiming of certificates',
  'location': 'Ground floor, Municipal Hall',
  'purpose': 'Claim my birth certificate',
  'can_cancel': true,
};

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

Future<void> _pumpSignedIn(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final session = CitizenSessionService();
  final base = MockCatalog.demoAccounts.last;
  await tester.runAsync(() async {
    await pumpEventQueue();
    await session.login(CitizenAccount.fromJson({...base.toJson(), 'status': 'Approved'}));
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await _settle(tester);
}

ServiceRequest _filed(DateTime submittedAt) => ServiceRequest(
  id: 'DOK-2026-00042',
  referenceNumber: 'DOK-2026-00042',
  applicantId: 'ESP-1',
  applicantName: 'Synthetic Resident',
  typeName: 'Barangay Clearance',
  category: ServiceCategory.dokyu,
  office: 'Barangay Hall',
  purpose: 'Employment',
  submittedAt: submittedAt,
  status: 'Submitted',
  statusHistory: const [],
  attachments: const <Attachment>[],
  expectedDays: '1-2 working days',
);

Widget _uploader(Attachment attachment) => MaterialApp(
  home: Scaffold(
    body: RequirementUploader(
      requirement: const RequirementInfo(label: 'Valid ID', documentType: 'Valid ID', isRequired: true),
      attachment: attachment,
      accent: AppColors.brand600,
      existingMasterDoc: null,
      onAttachNew: (_) {},
      onUseExisting: () {},
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  group('Report an Incident (132)', () {
    testWidgets('the form is reached when the past reports cannot be read', (tester) async {
      FakeApi.installFull((r) {
        if (r.path == '/citizen/incidents') throw const FakeApiError(status: 503, code: 'UNAVAILABLE');
        return <dynamic>[];
      });
      await _pumpSignedIn(tester, const SakunaScreen());

      await tester.ensureVisible(find.text('Report an Incident'));
      await tester.tap(find.text('Report an Incident'));
      await tester.pump();
      await _settle(tester);

      // The list and its own button show at once; the failed read says so.
      expect(find.byType(RequestListScreen), findsOneWidget);
      expect(find.text('Your past reports could not be loaded. Pull down to try again.'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget, reason: 'a way back, not a bare page');

      await tester.tap(find.descendant(of: find.byType(NewRequestFab), matching: find.text('Report an Incident')));
      await tester.pumpAndSettle();
      expect(find.byType(ReportIncidentScreen), findsOneWidget);
    });

    testWidgets('a refused report names the field, and the sitio stops at the server limit (136)', (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const reason = 'The sitio field must not be greater than 120 characters.';
      _installRaw((r) {
        if (r.method == 'POST' && r.url.path == '/citizen/incidents') return _refusal('sitio', reason);
        return _ok(<dynamic>[]);
      });
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CitizenSessionService()),
            ChangeNotifierProvider(create: (_) => RequestsService()),
          ],
          child: const MaterialApp(home: ReportIncidentScreen(accent: AppColors.rose600)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flood'));
      await tester.tap(find.text('High'));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(MockCatalog.barangays.first).last);
      await tester.pumpAndSettle();

      final sitio = find.descendant(
        of: find.byWidgetPredicate((w) => w is AppTextField && (w.label ?? '').startsWith('Sitio')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(sitio);
      await tester.enterText(sitio, 'x' * 150);
      await tester.pump();
      expect(tester.widget<TextField>(sitio).controller!.text, hasLength(maxIncidentSitioLength));

      final submit = find.text('Submit Report');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await _settle(tester);
      expect(find.text(reason), findsOneWidget);
      expect(find.text('Some fields need to be corrected.'), findsNothing);
    });
  });

  test('a photo the scan refused reads as refused, from scan_status (142)', () async {
    FakeApi.installFull(
      (r) => {
        ..._incidentRow('INC-2026-00021'),
        'photos': [
          {'name': 'flood-1.jpg', 'url': null, 'scan_status': 'infected'},
          {'name': 'flood-2.jpg', 'url': 'https://test.invalid/files/b?signature=x', 'scan_status': 'clean'},
          {'name': 'flood-3.jpg', 'url': null, 'scan_status': 'pending'},
        ],
      },
    );
    final service = RequestsService();
    addTearDown(service.dispose);
    final detail = await service.loadDetail('INC-2026-00021');
    expect(detail.incidentPhotoRefused, [true, false, false]);
  });

  group("Sign-out keeps the previous resident's lists off the phone (143)", () {
    test('a load under way when the lists are cleared does not refill them', () async {
      FakeApi.installFull((r) {
        if (r.path == '/citizen/requests') return [_requestRow('DOK-2026-00042')];
        if (r.path == '/citizen/incidents') return [_incidentRow('INC-2026-00021')];
        return <dynamic>[];
      });
      final service = RequestsService();
      addTearDown(service.dispose);

      final requests = service.loadRequests();
      final incidents = service.loadIncidents();
      service.clear();
      await Future.wait([requests, incidents]);

      expect(service.all, isEmpty);
      expect(service.loaded, isFalse, reason: 'the next resident still loads their own');
    });

    test('a reload while sign-out is still under way, with the old token, is dropped', () async {
      FakeApi.installFull((r) {
        if (r.path == '/citizen/requests') return [_requestRow('DOK-2026-00042')];
        if (r.path.startsWith('/citizen/requests/')) return _requestRow('DOK-2026-00042');
        if (r.path == '/citizen/incidents') return [_incidentRow('INC-2026-00021')];
        return <dynamic>[];
      });
      final service = RequestsService();
      addTearDown(service.dispose);
      await api.setToken('synthetic-token-resident-a');
      await service.loadRequests();
      expect(service.all, hasLength(1));

      // SignOut.signOut: the lists are cleared, then the server is told,
      // and only then the token is forgotten. Live updates reload meanwhile.
      service.clear();
      await service.refreshRequests();
      await service.loadRequests();
      await service.loadIncidents();
      await service.loadDetail('DOK-2026-00042').catchError((Object _) => _filed(DateTime(2026)));
      expect(service.all, isEmpty);

      // The next resident signs in: their own lists load.
      await api.setToken('synthetic-token-resident-b');
      await service.loadRequests();
      await service.loadIncidents();
      expect(service.all, hasLength(2));
      await api.setToken(null);
    });
  });

  group('Cancelling an appointment (178, 179)', () {
    testWidgets("the reason stops at the server's 300 and the dialog scrolls over the keyboard", (tester) async {
      FakeApi.installFull((r) => r.path == '/citizen/appointments' ? [_appointment()] : <dynamic>[]);
      await _pumpSignedIn(tester, const AppointmentsScreen());
      await tester.tap(find.text('Cancel appointment'));
      await tester.pumpAndSettle();

      final reason = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      await tester.enterText(reason, 'y' * 400);
      expect(tester.widget<TextField>(reason).controller!.text, hasLength(cancelReasonMaxLength));
      expect(cancelReasonMaxLength, 300);
      expect(tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable, isTrue);

      // A short phone with the keyboard up.
      tester.view.physicalSize = const Size(390, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 330);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'no overflow stripe');
    });

    testWidgets("a refusal names the field's own reason", (tester) async {
      const why = 'The reason field must not be greater than 300 characters.';
      _installRaw((r) {
        if (r.method == 'POST' && r.url.path.endsWith('/cancel')) return _refusal('reason', why);
        if (r.url.path == '/citizen/appointments') return _ok([_appointment()]);
        return _ok(<dynamic>[]);
      });
      await _pumpSignedIn(tester, const AppointmentsScreen());
      await tester.tap(find.text('Cancel appointment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel appointment').last);
      await _settle(tester);
      expect(find.text(why), findsOneWidget);
    });
  });

  test('a post opened by its id stays out of the feed and Home, and is still found (180, 213, 181)', () async {
    FakeApi.installFull((r) {
      if (r.path == '/announcements') {
        return [
          {'id': 1, 'body': 'Newest post', 'published_at': '2026-11-17T00:00:00Z'},
          {'id': 2, 'body': 'Last week', 'published_at': '2026-11-10T00:00:00Z'},
        ];
      }
      if (r.path == '/announcements/9') {
        return {'id': 9, 'body': 'Weeks old, another barangay', 'barangay': 'Synthetic Other', 'published_at': '2026-10-01T00:00:00Z'};
      }
      return <dynamic>[];
    });
    final balita = BalitaService();
    addTearDown(balita.dispose);
    await balita.loadFeed();

    final opened = await balita.loadAnnouncement(9);
    expect(opened.remoteId, 9);
    // The feed (its "All" tab) and Home's "latest updates" are the server's
    // feed only: a post for another barangay never joins them.
    expect(balita.posts.map((p) => p.remoteId), [1, 2]);
    expect(identical(balita.find(9), opened), isTrue);
    expect(identical(balita.findById(opened.id), opened), isTrue);
    expect(identical(await balita.loadAnnouncement(9), opened), isTrue, reason: 'once, the same object');

    // The feed's first page arriving after it (a cold start) keeps it found.
    await balita.loadFeed();
    expect(balita.posts.map((p) => p.remoteId), [1, 2]);
    expect(identical(balita.find(9), opened), isTrue);

    // Signed out: gone with the feed.
    balita.clear();
    expect(balita.find(9), isNull);
  });

  group('Requirement files (256, 257)', () {
    test("a file over the server's limit is refused before it is attached", () {
      const mb = 1024 * 1024;
      expect(requirementFileTooLarge('id-front.jpg', 6 * mb), contains('5 MB'));
      expect(requirementFileTooLarge('ID-FRONT.JPG', 4 * mb), isNull);
      expect(requirementFileTooLarge('cedula.pdf', 9 * mb), isNull);
      expect(requirementFileTooLarge('cedula.pdf', 11 * mb), contains('10 MB'));
    });

    test('a photo is taken at a size the server takes', () {
      final src = File('lib/widgets/requirement_uploader.dart').readAsStringSync();
      final call = src.substring(src.indexOf('pickImageProtected('));
      expect(call.substring(0, call.indexOf(');')), contains('maxDimension: 2000'));
    });

    testWidgets('View opens a requirement already on the server from its URL', (tester) async {
      const url = 'https://test.invalid/files/valid-id.jpg?signature=synthetic';
      await tester.pumpWidget(
        _uploader(
          Attachment(
            id: 'valid_id',
            fileName: 'valid-id.jpg',
            category: AttachmentCategory.image,
            sizeBytes: 120000,
            remoteUrl: url,
            addedAt: DateTime(2026, 11, 18),
            documentTypeLabel: 'Valid ID',
          ),
        ),
      );
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      final viewer = tester.widget<ImageViewerScaffold>(find.byType(ImageViewerScaffold));
      expect(viewer.image, isA<NetworkImage>());
      expect((viewer.image! as NetworkImage).url, url);
    });

    testWidgets('a Papeles document with no copy here offers no View that does nothing', (tester) async {
      await tester.pumpWidget(
        _uploader(
          Attachment(
            id: 'pap-7',
            fileName: 'valid-id.jpg',
            category: AttachmentCategory.image,
            sizeBytes: 120000,
            addedAt: DateTime(2026, 11, 18),
            documentTypeLabel: 'Valid ID',
            papelesId: 7,
          ),
        ),
      );
      expect(find.text('View'), findsNothing);
      expect(find.text('Replace'), findsOneWidget);
    });
  });

  test("the date filter uses the resident's own day, as the card prints it (119)", () {
    // The server sends UTC; 23:30 UTC is 07:30 the next morning in Esperanza.
    final submitted = JsonRead.date('2026-11-17T23:30:00+00:00')!;
    final local = submitted.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final request = _filed(submitted);
    expect(RequestFilters(dateRange: DateTimeRange(start: day, end: day)).apply([request]), [request]);
    final utcDay = DateTime(2026, 11, 17);
    if (utcDay != day) {
      expect(RequestFilters(dateRange: DateTimeRange(start: utcDay, end: utcDay)).apply([request]), isEmpty);
    }
  });

  test("'Your Document' never fills the deceased's or the child's details from the requester (120)", () {
    final death = documentData(
      documentMetas['mcro_death']!,
      const {'deceased_name': 'Synthetic Deceased', 'sex': 'Male'},
      fullName: 'Synthetic Requester',
      birthdate: '1990-01-02',
      sex: 'Female',
      civilStatus: 'Married',
      address: 'Poblacion, Esperanza',
    );
    expect(death['sex'], 'Male', reason: 'what was filed stays');
    for (final key in ['date_of_birth', 'civil_status', 'residence', 'citizenship', 'age']) {
      expect(death.containsKey(key), isFalse, reason: '$key is the deceased’s, not the requester’s');
    }
    final birth = documentData(
      documentMetas['mcro_live_birth']!,
      const {'child_name': 'Synthetic Child'},
      fullName: 'Synthetic Parent',
      birthdate: '1990-01-02',
      sex: 'Female',
    );
    expect(birth.containsKey('sex'), isFalse);
    expect(birth.containsKey('date_of_birth'), isFalse);
    // A paper about the requester is still completed from their profile.
    final clearance = documentData(documentMetas['brgy_clearance']!, const {}, fullName: 'Ana', sex: 'Female');
    expect(clearance['sex'], 'Female');
  });

  testWidgets('the offline pill sits under the app bar and lets its buttons through (147)', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => ApiClient.unreachable.value = false);
    var back = 0;
    var search = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OfflineNotice(
          probeEvery: const Duration(hours: 1),
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => back++),
              title: const Text('Screen title'),
              actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => search++)],
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    ApiClient.unreachable.value = true;
    await tester.pump();

    final pill = find.textContaining('No internet connection');
    expect(pill, findsOneWidget);
    expect(tester.getTopLeft(pill).dy, greaterThanOrEqualTo(kToolbarHeight));
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    expect(back, 1);
    expect(search, 1);

    ApiClient.unreachable.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets("the centre + launcher answers a screen reader's double-tap (148)", (tester) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: EsperanzaCenterAction(onPressed: () => opened++))),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Open Dokyu and Tulong'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(opened, 1);
    semantics.dispose();
  });
}
