// QA sweep 2026-11-18, app-2: requests, their details and the Resident
// Profile. Each test names what went wrong before. Nothing here touches the
// network: test/support/fake_api.dart answers every call.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/catalog_item.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/request_release.dart';
import 'package:esperanza_mobile/models/resident_profile.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/documents_uploaded_screen.dart';
import 'package:esperanza_mobile/screens/shared/my_requests_screen.dart';
import 'package:esperanza_mobile/screens/shared/new_request_screen.dart';
import 'package:esperanza_mobile/screens/shared/pdf_viewer_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_list_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_submitted_screen.dart';
import 'package:esperanza_mobile/screens/shared/service_request_wizard_screen.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:esperanza_mobile/widgets/app_date_field.dart';
import 'package:esperanza_mobile/widgets/image_viewer_scaffold.dart';
import 'package:esperanza_mobile/widgets/request_release_cards.dart';

import 'support/dokyu_tulong_fixtures.dart';
import 'support/fake_api.dart';

const _service = 'Barangay Certification (Synthetic)';

Map<String, dynamic> _row(String ref, {String status = 'Submitted', String? submitted, String service = _service}) => {
  'ref': ref,
  'type': 'dokyu',
  'service': service,
  'status': status,
  'submitted': submitted ?? DateTime.now().toUtc().toIso8601String(),
};

Future<CitizenSessionService> _signedIn(WidgetTester tester) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    if (++attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last); // verified
  return session;
}

void _phone(WidgetTester tester, {double height = 844}) {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpDetail(WidgetTester tester, RequestsService requests, String ref) async {
  _phone(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
      ],
      child: MaterialApp(home: RequestDetailScreen(requestId: ref)),
    ),
  );
  await tester.pumpAndSettle();
}

CitizenAccount _account() => CitizenAccount(
  id: 'ESP-RES-TEST-1118',
  firstName: 'Test',
  lastName: 'Resident',
  email: 'test.1118@example.com',
  mobile: '09171234567',
  barangay: 'Agoho',
  purok: 'Purok 1',
  address: 'Purok 1, Barangay Agoho, Esperanza, Masbate',
  birthdate: '—',
  sex: '—',
  civilStatus: '—',
  occupation: '—',
  profileCompleteness: 40,
  status: 'Approved',
);

Future<ResidentProfileService> _profiles() async {
  final service = ResidentProfileService();
  await Future<void>.delayed(const Duration(milliseconds: 50)); // _restore()
  return service;
}

Map<String, dynamic> _issued({required String scan}) => {
  'control_number': 'BC-2026-000042',
  'verify_url': 'https://example.invalid/verify/?code=abcdefgh',
  'issued_on': '2026-10-14',
  'has_scan': true,
  'scan_url': scan,
};

void main() {
  tearDown(FakeApi.restore);

  group('Wizard date questions', () {
    final now = DateTime(2026, 11, 18);

    test('a date still to come can be picked; one that has happened stops at today', () {
      for (final (key, label) in [
        ('event_date', 'Event Date'),
        ('travel_date', 'Planned travel date'),
        ('planned_wedding_date', 'Planned wedding date (if set)'),
        ('license_valid_until', 'License: Valid Until'),
        ('next_meeting_date', 'Date of Next Meeting'),
      ]) {
        expect(ServiceRequestWizardScreen.lastDateFor(key, label, now: now).isAfter(now), isTrue, reason: label);
      }
      for (final (key, label) in [
        ('date_of_birth', 'Date of Birth'),
        ('dateOfDeath', 'Date of Death'),
        ('date_of_marriage', 'Date of Marriage'),
        ('husband_dob', "Husband's Date of Birth"),
        ('incident_date', 'Date of the incident'),
        ('burial_date', 'Date Buried/Cremated'),
      ]) {
        expect(ServiceRequestWizardScreen.lastDateFor(key, label, now: now), now, reason: label);
      }
    });

    testWidgets("the Service Catalog's Event Date offers days after today", (tester) async {
      SharedPreferences.setMockInitialValues({});
      _phone(tester, height: 2400);
      FakeApi.installFull((r) => <dynamic>[]);
      final session = CitizenSessionService();
      await session.login(MockCatalog.demoAccounts.last);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider(create: (_) => RequestsService()),
            ChangeNotifierProvider(create: (_) => ResidentProfileService()),
            ChangeNotifierProvider(create: (_) => MasterFileService()),
            ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: MaterialApp(
            home: ServiceRequestWizardScreen(
              category: ServiceCategory.dokyu,
              item: CatalogItem.fromApi({
                'key': 'brgy_event_permit',
                'type': 'dokyu',
                'name': 'Barangay Event / Special Permit',
                'office': 'Barangay Hall',
                'fee': {'display': 'Free', 'kind': 'free', 'required_inputs': <String>[]},
                'requirements': <String>[],
                'process': ['Submit', 'Release'],
                'fields': [
                  {'key': 'event_date', 'label': 'Event Date', 'type': 'date'},
                ],
                'version': 1,
              }),
              accent: AppColors.brand600,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final field = tester.widget<AppDateField>(find.byType(AppDateField));
      expect(field.label, 'Event Date');
      expect(field.lastDate!.isAfter(DateTime.now()), isTrue);
    });
  });

  group('A Submit that got no answer', () {
    test('finds the request the server filed anyway, and only after no answer', () async {
      final rows = [_row('DR-2026-00010', submitted: '2026-01-05T00:00:00Z')];
      DokyuTulongFixtures.install(requests: rows);
      final requests = RequestsService();
      await requests.loadRequests();
      final check = FiledRequestCheck.of(requests);

      rows.add(_row('DR-2026-00011'));
      expect(
        await check.find(const ApiException(status: 422, messageEn: 'Invalid.'), requests, serviceName: _service),
        isNull,
        reason: 'a refusal filed nothing',
      );
      final filed = await check.find(
        const ApiException(retryable: true, messageEn: 'The request timed out.'),
        requests,
        serviceName: _service,
      );
      expect(filed?.referenceNumber, 'DR-2026-00011');
    });

    test('when nothing new is on the list, the form says it may still have been filed', () async {
      DokyuTulongFixtures.install(requests: [_row('DR-2026-00010', submitted: '2026-01-05T00:00:00Z')]);
      final requests = RequestsService();
      await requests.loadRequests();
      const timedOut = ApiException(retryable: true, messageEn: 'The request timed out.');
      final check = FiledRequestCheck.of(requests);
      expect(await check.find(timedOut, requests, serviceName: _service), isNull);
      expect(FiledRequestCheck.explain(timedOut), contains('may still have been filed'));
      expect(FiledRequestCheck.explain(const ApiException(status: 422, messageEn: 'Invalid.')), 'Invalid.');
    });

    testWidgets('the form goes on as filed instead of offering Submit again', (tester) async {
      SharedPreferences.setMockInitialValues({});
      _phone(tester);
      var posts = 0;
      final rows = <Map<String, dynamic>>[];
      DokyuTulongFixtures.install(
        requests: rows,
        onSubmit: (body) {
          posts++;
          // Filed, but the answer never reached the phone.
          rows.add(_row('DR-2026-00077'));
          throw const FakeApiError(status: 504, code: 'GATEWAY_TIMEOUT', messageEn: 'The server took too long.');
        },
      );
      final session = await _signedIn(tester);
      final requests = RequestsService();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider(create: (_) => MasterFileService()),
          ],
          child: const MaterialApp(
            home: NewRequestScreen(
              category: ServiceCategory.dokyu,
              item: CatalogItem(
                key: 'dokyu_synthetic_certification',
                name: _service,
                office: 'Barangay Hall',
                fee: 'Free',
                days: '1 day',
                requirements: [],
                process: ['Submit Request', 'Release'],
              ),
              accent: AppColors.blue700,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Employment requirement');
      final submit = find.widgetWithText(AppButton, 'Submit Request');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(posts, 1);
      expect(find.byType(RequestSubmittedScreen), findsOneWidget);
      expect(find.text('DR-2026-00077'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Request detail', () {
    testWidgets('an incident the office did not confirm is not an application to apply for again', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FakeApi.installFull((r) {
        if (r.path == '/services') return <dynamic>[];
        if (r.path == '/citizen/incidents/INC-2026-00007') {
          return {
            'ref': 'INC-2026-00007',
            'type': 'Flood',
            'status': 'Rejected',
            'reported': '2026-11-01T00:00:00Z',
            'barangay': 'Agoho',
          };
        }
        throw const FakeApiError();
      });
      await _pumpDetail(tester, RequestsService(), 'INC-2026-00007');

      expect(find.text('Not confirmed by the office'), findsOneWidget);
      expect(find.text('Application Rejected'), findsNothing);
      expect(find.text('Apply Again'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Apply Again says so when the service is no longer offered', (tester) async {
      SharedPreferences.setMockInitialValues({});
      DokyuTulongFixtures.install(
        requests: [_row('DR-2026-00031', status: 'Rejected', service: 'Retired Certificate (Synthetic)')],
      );
      final requests = RequestsService();
      await requests.loadRequests();
      await requests.loadCatalog();
      await _pumpDetail(tester, requests, 'DR-2026-00031');

      await tester.ensureVisible(find.text('Apply Again'));
      await tester.tap(find.text('Apply Again'));
      await tester.pumpAndSettle();
      expect(find.textContaining('cannot be applied for in the app right now'), findsOneWidget);
    });

    testWidgets('pulling down reads the request again', (tester) async {
      SharedPreferences.setMockInitialValues({});
      var reads = 0;
      FakeApi.installFull((r) {
        if (r.path == '/services') return <dynamic>[];
        if (r.path == '/citizen/requests/DR-2026-00040') {
          reads++;
          return _row('DR-2026-00040');
        }
        throw const FakeApiError();
      });
      await _pumpDetail(tester, RequestsService(), 'DR-2026-00040');
      expect(reads, 1);

      await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(reads, 2);
    });
  });

  group('Signed copy', () {
    final pdf = Uint8List.fromList(latin1.encode('%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF'));
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    );

    test('a PDF is known by its contents, since its link names no type', () {
      expect(IssuedDocumentsCard.isPdf(pdf), isTrue);
      expect(IssuedDocumentsCard.isPdf(png), isFalse);
    });

    Future<Uri?> openWith(WidgetTester tester, Uint8List bytes) async {
      Uri? fetched;
      IssuedDocumentsCard.debugFetch = (uri) async {
        fetched = uri;
        return http.Response.bytes(bytes, 200, headers: {'content-type': 'application/octet-stream'});
      };
      addTearDown(() => IssuedDocumentsCard.debugFetch = null);
      PdfViewerScreen.debugPagesBuilder = (bytes, onError) => Text('PDF PAGES ${bytes.length}');
      addTearDown(() => PdfViewerScreen.debugPagesBuilder = null);
      _phone(tester, height: 1600);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IssuedDocumentsCard(
                documents: [IssuedDocumentInfo.fromApi(_issued(scan: 'https://test.invalid/files/old?signature=a'))!],
                accent: AppColors.brand700,
                // Read again: the link from five minutes ago has expired.
                reload: () async => [IssuedDocumentInfo.fromApi(_issued(scan: 'https://test.invalid/files/new?signature=b'))!],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View signed copy'));
      await tester.pumpAndSettle();
      return fetched;
    }

    testWidgets('a PDF opens in the PDF viewer, from a link read just now', (tester) async {
      final fetched = await openWith(tester, pdf);
      expect(fetched?.path, '/files/new');
      expect(find.byType(PdfViewerScreen), findsOneWidget);
      expect(find.byType(ImageViewerScaffold), findsNothing);
    });

    testWidgets('a picture opens in the image viewer', (tester) async {
      await openWith(tester, png);
      expect(find.byType(ImageViewerScaffold), findsOneWidget);
      expect(find.byType(PdfViewerScreen), findsNothing);
    });
  });

  group('Documents Uploaded', () {
    testWidgets('a file still being checked is read again when tapped', (tester) async {
      SharedPreferences.setMockInitialValues({});
      var reads = 0;
      Map<String, dynamic> upload(String scan) => {
        'ref': 'TUL-2026-00001',
        'type': 'tulong',
        'service': 'Educational Assistance',
        'requirement': 'Certificate of Enrollment',
        'current': true,
        'file': {
          'name': 'enrollment.pdf',
          'mime': 'application/pdf',
          'bytes': 10,
          'scan_status': scan,
          'url': null,
          'uploaded_at': '2026-11-18T01:00:00Z',
        },
      };
      FakeApi.install((path, query) {
        if (path == '/citizen/uploads') {
          reads++;
          return [upload(reads == 1 ? 'pending' : 'infected')];
        }
        if (path == '/citizen/papeles') return <dynamic>[];
        throw const FakeApiError();
      });
      final mf = MasterFileService();
      var attempts = 0;
      while (!mf.loaded) {
        if (++attempts > 100) throw StateError('MasterFileService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      final session = await _signedIn(tester);
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
      expect(reads, 1);

      await tester.tap(find.text('enrollment.pdf'));
      await tester.pumpAndSettle();
      expect(reads, 2, reason: '"Try again in a minute" reads the list again');
      expect(find.textContaining('failed the virus check'), findsOneWidget);
    });
  });

  group('My Requests', () {
    testWidgets('a list that could not be read says so, not "No requests yet"', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FakeApi.installFull((r) => throw const FakeApiError(status: 503, code: 'UNAVAILABLE', messageEn: 'The server is busy.'));
      final session = await _signedIn(tester);
      final requests = RequestsService();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ],
          child: const MaterialApp(home: MyRequestsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No requests yet'), findsNothing);
      expect(find.text('Your requests could not be loaded'), findsOneWidget);

      DokyuTulongFixtures.install(requests: [_row('DR-2026-00050')]);
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.text(_service), findsOneWidget);
      expect(find.text('Your requests could not be loaded'), findsNothing);
    });
  });

  group('Dokyu list', () {
    testWidgets('the last card clears the navbar and the New Request button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      _phone(tester);
      DokyuTulongFixtures.install(requests: [_row('DR-2026-00060')]);
      final requests = RequestsService();
      await requests.loadRequests();
      const navbar = 90.0;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RequestsService>.value(value: requests),
            ChangeNotifierProvider(create: (_) => CitizenSessionService()),
            ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: MaterialApp(
            // RootShell's extendBody publishes the navbar as bottom padding.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(bottom: navbar)),
              child: child!,
            ),
            home: const RequestListScreen(
              category: ServiceCategory.dokyu,
              title: 'Dokyu',
              subtitle: 's',
              catalog: [],
              accent: AppColors.brand600,
              icon: Icons.description_outlined,
              pushed: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final list = tester.widget<ListView>(find.byType(ListView));
      // The navbar, the 56 dp button and a gap: not the 48 dp it had.
      expect((list.padding! as EdgeInsets).bottom, greaterThanOrEqualTo(navbar + 56 + 16));
    });
  });

  group('Resident Profile family name', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts as the surname, as on the website', () {
      expect(ResidentProfile.seedFrom(_account()).familyName, 'Resident');
    });

    test('an old "<last name> Family" on the phone is repaired, and never sent', () async {
      final old = ResidentProfile.seedFrom(_account())..familyName = 'Resident Family';
      SharedPreferences.setMockInitialValues({
        'esperanza_resident_profiles': jsonEncode({_account().id: old.toJson()}),
      });
      final service = await _profiles();
      expect(service.profileFor(_account()).familyName, 'Resident');

      service.profileFor(_account()).familyName = 'Dela Cruz Family';
      FakeApiRequest? sent;
      FakeApi.installFull((r) {
        if (r.method == 'PUT') sent = r;
        return {
          'individual': {'ref': 'RES-2026-0951', 'verification': 'For Validation'},
        };
      });
      await service.submit(_account().id);
      expect((sent!.body!['family'] as Map)['surname'], 'Dela Cruz', reason: 'the server adds " Family" itself');
    });
  });

  group('Resident Profile record on file', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Map<String, dynamic> unverified() => {
      'individual': {'ref': 'RES-2026-0950', 'verification': 'Unverified', 'sex': 'Female', 'occupation': 'Fisher'},
      'household': {'address': 'Purok 1, Agoho', 'water': 'Deep Well', 'electricity': 'Solar'},
      'family': {
        'surname': 'Dela Cruz',
        'members': [
          {'ref': 'RES-2026-0952', 'name': 'Ana Dela Cruz', 'relation': 'Daughter'},
        ],
      },
      'review': null,
    };

    test('an Unverified record (a registry import) is loaded, but not taken as sent', () async {
      final service = await _profiles();
      FakeApi.installFull((r) => unverified());
      await service.sync(_account());

      final p = service.profileFor(_account());
      expect(p.household.waterSource, 'Deep Well');
      expect(p.household.electricitySource, 'Solar');
      expect(p.familyName, 'Dela Cruz');
      expect(p.familyMembers.single.serverRef, 'RES-2026-0952');
      expect(p.personalSaved || p.householdSaved || p.familySaved, isFalse);
    });

    test('a tag the resident unticked and saved for later does not come back on the next sync', () async {
      final service = await _profiles();
      FakeApi.installFull((r) => {
        ...unverified(),
        'individual': {
          'ref': 'RES-2026-0950',
          'verification': 'Unverified',
          'tags': ['Registered Voter'],
        },
      });
      await service.sync(_account());
      final p = service.profileFor(_account());
      expect(p.personal.isVoter, isTrue, reason: 'taken from the record the first time');

      await service.savePersonal(_account().id, p.personal..isVoter = false, markComplete: false);
      await service.sync(_account());
      expect(service.profileFor(_account()).personal.isVoter, isFalse);
    });

    test('a submit keeps what is on file where the phone has nothing', () async {
      final service = await _profiles();
      final p = service.profileFor(_account());
      await service.savePersonal(_account().id, p.personal..sex = 'Female', markComplete: true);

      FakeApiRequest? sent;
      FakeApi.installFull((r) {
        if (r.method == 'PUT') sent = r;
        return unverified();
      });
      await service.submit(_account().id);

      final household = sent!.body!['household'] as Map;
      expect(household['water'], 'Deep Well', reason: 'it was sent as null, which cleared it');
      expect(household['electricity'], 'Solar');
      expect((sent!.body!['personal'] as Map)['occupation'], 'Fisher');
    });
  });
}
