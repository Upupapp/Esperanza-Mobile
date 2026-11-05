// Certificates in the app (owner, 2026-11-05, sheet item 9): every
// certificate the resident holds, from group sessions (as applicant or as
// partner) and from events, listed from GET /citizen/certificates
// (esperanza-backend WelfareSessionsController::certificates), drawn in the
// app as the website's certificate window draws it (welfare-certificate.js),
// and reached from a notification's `?certificate=` link (the partner's
// copy). Synthetic data; no network.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/resident_certificate.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/certificate_view_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_list_screen.dart';
import 'package:esperanza_mobile/screens/tulong/certificates_screen.dart';
import 'package:esperanza_mobile/services/certificates_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/message_language.dart';
import 'package:esperanza_mobile/services/notification_feed.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';

import 'support/fake_api.dart';

const _sessionUrl = 'https://esperanza.example.test/verify/tok-session';
const _eventUrl = 'https://esperanza.example.test/verify/tok-event';

/// As the server sends them: newest first, a session's then an event's.
final _session = <String, dynamic>{
  'source': 'session',
  'event_key': null,
  'control_number': 'PMOC-2026-000007',
  'title': 'Certificate of Pre-Marriage Orientation',
  'issued_on': '2026-11-04',
  'session': {'ref': 'SES-2026-0003', 'date': '2026-11-03', 'venue': 'MSWDO Hall'},
  'request_ref': null,
  'role': 'partner',
  'verify_url': _sessionUrl,
  'verification_code': 'ABCDEFGH2345',
  'holder_names': ['Juan Halimbawa', 'Maria Sample'],
  'document': {
    'control_number': 'PMOC-2026-000007',
    'serial': 'ABCD-EFGH-2345',
    'verify_url': _sessionUrl,
    'issued_on': '2026-11-04',
    'revoked': false,
    'field_values': {
      'cert_title': 'Certificate of Pre-Marriage Orientation',
      'cert_subtitle': 'Pre-Marriage Orientation and Counseling',
      'body': 'This is to certify that Juan Halimbawa and Maria Sample attended the Pre-Marriage Orientation on 3 November 2026 at MSWDO Hall.',
      'holder_names': ['Juan Halimbawa', 'Maria Sample'],
      'applicant': 'Juan Halimbawa and Maria Sample',
      'session_date': '2026-11-03',
      'venue': 'MSWDO Hall',
      'office_name': 'Municipal Social Welfare and Development Office',
      'signed_by': 'team',
      'signatories': [
        {'name': 'Ana Facilitator', 'position': 'Social Welfare Officer II', 'accreditation_no': 'PMC-0001', 'accreditation_valid_until': '2027-12-31'},
      ],
    },
  },
};

final _event = <String, dynamic>{
  'source': 'event',
  'event_key': 'health-day-x1',
  'control_number': 'EVT-2026-000001',
  'title': 'Certificate of Attendance',
  'issued_on': '2026-10-30',
  'event': {'key': 'health-day-x1', 'title': 'Barangay Health Day', 'date': '2026-10-28', 'venue': 'Municipal Plaza'},
  'session': null,
  'request_ref': null,
  'role': 'attendee',
  'verify_url': _eventUrl,
  'verification_code': 'HGFEDCBA5432',
  'holder_names': ['Maria Sample'],
  'document': {
    'control_number': 'EVT-2026-000001',
    'serial': 'HGFE-DCBA-5432',
    'issued_on': '2026-10-30',
    'revoked': false,
    'field_values': {
      'cert_title': 'Certificate of Attendance',
      'cert_subtitle': 'Barangay Health Day',
      'applicant': 'Maria Sample',
      'event_date': '2026-10-28',
      'venue': 'Municipal Plaza',
      'office': 'Municipality of Esperanza',
      'signatories': [
        {'name': 'Pedro Halimbawa', 'position': 'Municipal Mayor'},
      ],
    },
  },
};

/// No control number: nothing to name or open it by.
final _malformed = <String, dynamic>{'source': 'session', 'title': 'Broken row', 'issued_on': '2026-11-05'};

void _serve(Object Function() rows) => FakeApi.install((path, query) {
  if (path == '/citizen/certificates') return rows();
  throw const FakeApiError();
});

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: home));
  await _settle(tester);
}

ServerNotification _notice(String link) => ServerNotification(
  id: 1,
  category: 'tulong',
  title: 'Your certificate is ready',
  body: 'b',
  pill: 'Completed',
  ref: null,
  link: link,
  unread: true,
  pinned: false,
  at: DateTime(2026, 11, 4),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    FakeApi.restore();
    MessageLanguage.filipino.value = false;
  });

  test('both sources are read, in the order sent, and a malformed row is skipped', () async {
    _serve(() => [_session, 'not a row', _malformed, _event]);
    final list = await CertificatesService.mine();
    expect(list.map((c) => c.controlNumber), ['PMOC-2026-000007', 'EVT-2026-000001']);
    expect(list[0].source, CertificateSource.session);
    expect(list[0].date, DateTime(2026, 11, 3));
    expect(list[0].venue, 'MSWDO Hall');
    expect(list[1].source, CertificateSource.event);
    expect(list[1].eventTitle, 'Barangay Health Day');
    expect(list[1].verifyUrl, _eventUrl);
  });

  test('a row without a title or a top-level verify URL reads them from its document', () {
    final c = ResidentCertificate.fromApi({
      'control_number': 'EVT-2026-000002',
      'event_key': 'clean-up-x2',
      'document': {
        'verify_url': _eventUrl,
        'revoked': 'true',
        'field_values': {'cert_title': 'Certificate of Participation', 'cert_subtitle': 'Coastal Clean-up'},
      },
    })!;
    expect(c.isEvent, isTrue, reason: 'an event_key marks an event certificate, as on the website');
    expect(c.title, 'Certificate of Participation');
    expect(c.eventTitle, 'Coastal Clean-up');
    expect(c.verifyUrl, _eventUrl);
    expect(c.revoked, isTrue);
  });

  testWidgets('the list shows both sources newest first, each with where it came from and Open', (tester) async {
    _serve(() => [_session, _malformed, _event]);
    await _pump(tester, const CertificatesScreen());

    expect(find.text('My certificates'), findsOneWidget);
    expect(find.text('Broken row'), findsNothing);
    final session = find.text('Certificate of Pre-Marriage Orientation');
    final event = find.text('Certificate of Attendance');
    expect(session, findsOneWidget);
    expect(event, findsOneWidget);
    expect(tester.getTopLeft(session).dy, lessThan(tester.getTopLeft(event).dy), reason: 'newest first');
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
    expect(find.text('Juan Halimbawa and Maria Sample'), findsOneWidget);
    expect(find.text('Barangay Health Day · Oct 28, 2026 · Municipal Plaza · EVT-2026-000001'), findsOneWidget);
    expect(find.text('Issued on Nov 4, 2026'), findsOneWidget);
    expect(find.text('View certificate'), findsNWidgets(2));
  });

  testWidgets("in Filipino, the website's own words", (tester) async {
    MessageLanguage.filipino.value = true;
    _serve(() => [_session]);
    await _pump(tester, const CertificatesScreen());
    expect(find.text('Aking mga sertipiko'), findsOneWidget);
    expect(find.text('Sesyon'), findsOneWidget);
    expect(find.text('Tingnan ang sertipiko'), findsOneWidget);
    expect(find.text('Juan Halimbawa at Maria Sample'), findsOneWidget);
  });

  testWidgets('no certificates: says so', (tester) async {
    _serve(() => <dynamic>[]);
    await _pump(tester, const CertificatesScreen());
    expect(find.text('No certificates yet'), findsOneWidget);
    expect(find.text('View certificate'), findsNothing);
  });

  testWidgets('the server cannot be reached: the error state, with Try Again', (tester) async {
    _serve(() => throw const FakeApiError(status: 500, code: 'SERVER_ERROR', messageEn: 'The server had a problem.'));
    await _pump(tester, const CertificatesScreen());
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('The server had a problem.'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    _serve(() => [_event]);
    await tester.tap(find.text('Try Again'));
    await _settle(tester);
    expect(find.text('Certificate of Attendance'), findsOneWidget);
  });

  testWidgets('Open shows the certificate itself, in the app', (tester) async {
    _serve(() => [_session, _event]);
    await _pump(tester, const CertificatesScreen());

    final buttons = find.text('View certificate');
    await tester.ensureVisible(buttons.last);
    await tester.tap(buttons.last);
    await _settle(tester);
    expect(find.byKey(const Key('certificate_view')), findsOneWidget);
    expect(find.text('CERTIFICATE OF ATTENDANCE'), findsOneWidget);
    expect(find.text('Control No. EVT-2026-000001'), findsOneWidget);
  });

  group('the certificate, as the website draws it', () {
    testWidgets("a session's: seal, letterhead, title, holders, signatories, control number and verify QR", (tester) async {
      await _pump(tester, CertificateViewScreen(certificate: ResidentCertificate.fromApi(_session)!));
      expect(find.text('Certificate'), findsOneWidget, reason: 'the window title');
      expect(find.byType(Image), findsOneWidget, reason: 'the municipal seal');
      expect(find.text('Republic of the Philippines'), findsOneWidget);
      expect(find.text('MUNICIPALITY OF ESPERANZA'), findsOneWidget);
      expect(find.text('Municipal Social Welfare and Development Office'), findsOneWidget);
      expect(find.text('CERTIFICATE OF PRE-MARRIAGE ORIENTATION'), findsOneWidget);
      expect(find.text('Pre-Marriage Orientation and Counseling'), findsOneWidget);
      expect(
        find.text(
          'This is to certify that Juan Halimbawa and Maria Sample attended the Pre-Marriage Orientation on 3 November 2026 at MSWDO Hall.',
        ),
        findsOneWidget,
      );
      expect(find.text('Given this 4th day of November 2026 at the Municipality of Esperanza, Masbate, Philippines.'), findsOneWidget);
      expect(find.text('ANA FACILITATOR'), findsOneWidget);
      expect(find.text('Social Welfare Officer II'), findsOneWidget);
      expect(find.text('DSWD Accreditation No. PMC-0001 (valid until 2027-12-31)'), findsOneWidget);
      expect(find.text('Control No. PMOC-2026-000007'), findsOneWidget);
      expect(find.text('Issued 4 November 2026'), findsOneWidget);
      expect(find.text('Verification code ABCD-EFGH-2345'), findsOneWidget);
      expect(find.text('Scan the QR code or visit esperanza.example.test/verify to check this certificate.'), findsOneWidget);
      expect(tester.widget<QrImageView>(find.byType(QrImageView)).semanticsLabel, 'QR code to verify this certificate');
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('REVOKED'), findsNothing);
    });

    testWidgets("an event's: the wording made from the event, and the municipality as its office", (tester) async {
      await _pump(tester, CertificateViewScreen(certificate: ResidentCertificate.fromApi(_event)!));
      expect(find.text('CERTIFICATE OF ATTENDANCE'), findsOneWidget);
      expect(find.text('Barangay Health Day'), findsOneWidget);
      expect(
        find.text('This is to certify that Maria Sample participated in Barangay Health Day held on 28 October 2026 at Municipal Plaza.'),
        findsOneWidget,
      );
      expect(find.text('Municipal Social Welfare and Development Office'), findsNothing);
      expect(find.text('PEDRO HALIMBAWA'), findsOneWidget);
      expect(find.text('Municipal Mayor'), findsOneWidget);
      expect(find.text('Control No. EVT-2026-000001'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('in Filipino, the window follows the language; the certificate stays English', (tester) async {
      MessageLanguage.filipino.value = true;
      await _pump(tester, CertificateViewScreen(certificate: ResidentCertificate.fromApi(_session)!));
      expect(find.text('Sertipiko'), findsOneWidget);
      expect(find.text('I-download ang PDF'), findsOneWidget);
      expect(find.text('CERTIFICATE OF PRE-MARRIAGE ORIENTATION'), findsOneWidget);
    });
  });

  test('without holder names, the holders are the applicant line, as on the website', () {
    final c = ResidentCertificate.fromApi({
      'control_number': 'EVT-2026-000003',
      'source': 'event',
      'document': {
        'field_values': {'applicant': 'Maria Sample'},
      },
    })!;
    expect(c.holderNames, ['Maria Sample']);
  });

  testWidgets("a withdrawn certificate says so in the website's words, and opens with REVOKED across it", (tester) async {
    MessageLanguage.filipino.value = true;
    _serve(() => [
      {
        ..._session,
        'document': {
          ...(_session['document'] as Map<String, dynamic>),
          'revoked': true,
          'revoked_reason': 'Inilabas nang may mali',
        },
      },
    ]);
    await _pump(tester, const CertificatesScreen());
    expect(find.text('Binawi ang sertipikong ito: Inilabas nang may mali'), findsOneWidget);
    await tester.tap(find.text('Tingnan ang sertipiko'));
    await _settle(tester);
    expect(find.text('REVOKED'), findsOneWidget);
    expect(find.text('Binawi ang sertipikong ito: Inilabas nang may mali'), findsOneWidget);
  });

  group('the notification link', () {
    test('?certificate= opens My certificates on that certificate', () {
      final d = serverNotificationDestination(_notice('/citizen/assistance-requests?certificate=PMOC-2026-000007'));
      expect(d, isA<CertificatesScreen>());
      expect((d! as CertificatesScreen).openControlNumber, 'PMOC-2026-000007');
      // The Tulong page itself, and a case, still lead where they did.
      expect(serverNotificationDestination(_notice('/citizen/assistance-requests')), isNot(isA<CertificatesScreen>()));
      expect(
        serverNotificationDestination(_notice('/citizen/assistance-requests/TUL-2026-00001')),
        isNot(isA<CertificatesScreen>()),
      );
    });

    testWidgets('the named certificate is shown once the list is read', (tester) async {
      _serve(() => [_event, _session]);
      final d = serverNotificationDestination(_notice('/citizen/assistance-requests?certificate=PMOC-2026-000007'))!;
      await _pump(tester, d);
      expect(find.byKey(const Key('certificate_view')), findsOneWidget);
      expect(find.text('Control No. PMOC-2026-000007'), findsOneWidget);

      // Back on the list: not opened again.
      await tester.pageBack();
      await _settle(tester);
      expect(find.byKey(const Key('certificate_view')), findsNothing);
      expect(find.byKey(const Key('certificates_screen')), findsOneWidget);
      expect(find.byKey(const Key('certificate_not_found')), findsNothing);
    });

    testWidgets('one not in the list: the list, with a plain message', (tester) async {
      _serve(() => [_event]);
      await _pump(tester, const CertificatesScreen(openControlNumber: 'PMOC-2026-000099'));
      expect(find.byKey(const Key('certificate_view')), findsNothing);
      expect(find.byKey(const Key('certificate_not_found')), findsOneWidget);
      expect(find.textContaining('PMOC-2026-000099 is not in your list yet'), findsOneWidget);
      expect(find.text('Certificate of Attendance'), findsOneWidget);
    });
  });

  testWidgets('the Tulong list leads to My certificates', (tester) async {
    FakeApi.installFull((r) {
      if (r.path == '/citizen/requests') return <dynamic>[];
      if (r.path == '/citizen/certificates') return [_session];
      throw const FakeApiError();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RequestsService()),
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: const MaterialApp(
          home: RequestListScreen(
            category: ServiceCategory.tulong,
            title: 'Tulong',
            subtitle: 's',
            catalog: [],
            accent: AppColors.purple700,
            icon: Icons.volunteer_activism_outlined,
            pushed: true,
          ),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.byKey(const Key('tulong_my_certificates')));
    await _settle(tester);
    expect(find.byKey(const Key('certificates_screen')), findsOneWidget);
    expect(find.text('Certificate of Pre-Marriage Orientation'), findsOneWidget);
  });
}
