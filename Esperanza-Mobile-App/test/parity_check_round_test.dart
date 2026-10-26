// The parity check of 2026-10-26: the app bugs it found and the owner's
// decisions (Dokyu and Tulong before approval, the address, booking from a
// request, shared Balita links, the Papeles viewer, the legal pages' dates),
// pinned so the app and the website stay together. Nothing reaches the
// network.
import 'dart:convert';
import 'dart:io';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/incident_types.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_submitted_screen.dart';
import 'package:esperanza_mobile/services/appointments_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/deep_links.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/message_language.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/services/site_content_service.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _detail({
  required String ref,
  required String type,
  required String status,
  String? remarks,
  bool canResubmit = false,
  List<Map<String, dynamic>> photos = const [],
}) => {
  'ref': ref,
  'type': type,
  'service': type == 'dokyu' ? 'Barangay Clearance' : 'Educational Assistance',
  'service_key': type == 'dokyu' ? 'brgy_clearance' : 'tulong_educational',
  'status': status,
  'submitted': '2026-10-07T00:00:00Z',
  'office': 'Barangay Office',
  'decision_remarks': remarks,
  'can_resubmit': canResubmit,
  'needs_correction': const [],
  'missing_required': const [],
  'requirements': const [],
  'photos': photos,
  'history': [
    {'to': 'Submitted', 'at': '2026-10-07T00:00:00Z'},
    {'from': 'Submitted', 'to': status, 'at': '2026-10-07T01:00:00Z'},
  ],
};

Future<void> _pumpDetail(WidgetTester tester, String ref) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    if (++attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
      ],
      child: MaterialApp(home: RequestDetailScreen(requestId: ref)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(FakeApi.restore);
  tearDown(() => MessageLanguage.filipino.value = false);

  group('requests', () {
    testWidgets('a cancelled Dokyu request says why, as the website does', (tester) async {
      FakeApi.installFull(
        (_) => _detail(ref: 'DOK-2026-09001', type: 'dokyu', status: 'Cancelled', remarks: 'Duplicate of DOK-2026-09000.'),
      );
      await _pumpDetail(tester, 'DOK-2026-09001');
      expect(find.text('This request was cancelled'), findsOneWidget);
      expect(find.text('Reason for Cancellation'), findsOneWidget);
      expect(find.text('Duplicate of DOK-2026-09000.'), findsOneWidget);
    });

    testWidgets('nothing flagged, nothing missing: the request can be resubmitted', (tester) async {
      FakeApi.installFull(
        (_) => _detail(ref: 'DOK-2026-09002', type: 'dokyu', status: 'Under Review', remarks: 'Please confirm your purok.', canResubmit: true),
      );
      await _pumpDetail(tester, 'DOK-2026-09002');
      expect(find.widgetWithText(AppButton, 'Resubmit Application'), findsOneWidget);
    });

    testWidgets('any active request offers to book a visit', (tester) async {
      FakeApi.installFull((_) => _detail(ref: 'DOK-2026-09003', type: 'dokyu', status: 'Under Verification'));
      await _pumpDetail(tester, 'DOK-2026-09003');
      expect(find.text('Book an appointment'), findsOneWidget);
    });

    testWidgets('an incident report is confirmed as a report, not a document request', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RequestSubmittedScreen(
            referenceNumber: 'INC-2026-09001',
            typeName: 'Flood',
            accent: Colors.red,
            requestId: 'INC-2026-09001',
            reportAnother: (_) => const SizedBox(),
          ),
        ),
      );
      expect(find.text('Your report was sent.'), findsOneWidget);
      expect(find.text('View the report'), findsOneWidget);
      expect(find.text('Report another'), findsOneWidget);
      expect(find.textContaining('approval, and release'), findsNothing);
    });
  });

  test('a refused incident photo says so, not "Being checked" for ever', () async {
    FakeApi.install(
      (path, query) => {
        'ref': 'INC-2026-09002',
        'title': 'Fire',
        'type': 'Fire',
        'severity': 'High',
        'barangay': 'Poblacion',
        'status': 'Submitted',
        'reported': '2026-10-07T00:00:00Z',
        'photos': [
          {'url': null, 'scan': 'infected'},
          {'url': null, 'scan': 'pending'},
        ],
        'timeline': const [],
      },
    );
    final service = RequestsService();
    addTearDown(service.dispose);
    final incident = await service.loadDetail('INC-2026-09002');
    expect(incident.incidentPhotoRefused, [true, false]);
  });

  test('the whole name, middle name and suffix included, and the server\'s lock', () {
    final a = CitizenAccount.fromJson({
      'id': 'ESP-1', 'firstName': 'Ana', 'lastName': 'Cruz', 'middleName': 'Reyes', 'suffix': 'Jr.',
      'email': '', 'mobile': '', 'barangay': 'Poblacion', 'purok': '', 'address': '', 'birthdate': '', 'sex': '',
      'civilStatus': '', 'occupation': '', 'profileCompleteness': 0, 'status': 'Approved', 'serverIdentityLocked': false,
    });
    expect(a.fullName, 'Ana Reyes Cruz Jr.');
    final back = CitizenAccount.fromJson(jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
    expect(back.serverIdentityLocked, isFalse);
    expect(back.suffix, 'Jr.');
  });

  test('incident kinds and severities read in Filipino when it is chosen', () {
    expect(incidentTypes.first.label, 'Flood');
    expect(severityLabel('Moderate'), 'Medium');
    MessageLanguage.filipino.value = true;
    expect(incidentTypes.first.label, 'Baha');
    expect(severityLabel('Critical'), 'Kritikal');
  });

  test('a pop-up waits only for a notification load already under way', () async {
    final service = NotificationsService();
    addTearDown(service.dispose);
    final stopwatch = Stopwatch()..start();
    await service.settled();
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)), reason: 'nothing loading: no wait');
  });

  test('a shared Balita link names its post; the first one opens once', () {
    expect(DeepLinks.postIdOf('/citizen/announcements?post=42'), 42);
    expect(DeepLinks.postIdOf('/citizen/announcements/?post=7'), 7);
    expect(DeepLinks.postIdOf('/citizen/events?post=42'), isNull);
    expect(DeepLinks.postIdOf('/'), isNull);
    DeepLinks.rememberInitial('/citizen/announcements?post=9');
    expect(DeepLinks.takePendingPost(), 9);
    expect(DeepLinks.takePendingPost(), isNull);
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:host="esperanza-web-platform-frontend.netlify.app"'));
    expect(manifest, contains('android:pathPrefix="/citizen/announcements"'));
  });

  test("a booking from a request knows each schedule's service and office", () {
    final s = AppointmentSchedule.fromApi({
      'id': 1, 'place': 'Barangay Hall', 'office': 'Barangay Office', 'service_key': 'brgy_clearance',
    })!;
    expect(s.serviceKey, 'brgy_clearance');
    expect(s.office, 'Barangay Office');
  });

  test('the legal pages carry when they were last updated', () {
    final doc = PublishedDocument.fromJson({
      'title': 'Privacy Policy', 'effective_date': '2026-01-15', 'last_updated': '2026-10-20T00:00:00Z',
      'sections': [
        {'heading': '1. Who we are', 'body': 'Synthetic text.'},
      ],
    }, ContentSource.live)!;
    expect(doc.lastUpdated, isNotNull);
  });

  test('the address is edited whole, as on the website; a sign-up without a purok has no leading comma', () {
    final edit = File('lib/screens/profile/edit_profile_screen.dart').readAsStringSync();
    expect(edit, contains("changes['address'] = blankToNull(_address.text)"));
    expect(edit, isNot(contains("changes['purok']")));
    final register = File('lib/screens/auth/register_screen.dart').readAsStringSync();
    expect(register, contains('if (_purok.text.trim().isNotEmpty) _purok.text.trim(),'));
  });

  test('Papeles reads the wallet again where a request can use it', () async {
    SharedPreferences.setMockInitialValues({});
    final calls = <String>[];
    FakeApi.install((path, query) {
      calls.add(path);
      return const [];
    });
    final mf = MasterFileService();
    addTearDown(mf.dispose);
    await mf.refreshQuietly(null);
    expect(calls, isEmpty, reason: 'no account, nothing to read');
    await mf.refreshQuietly('ESP-1');
    expect(calls, contains('/citizen/papeles'));
  });
}
