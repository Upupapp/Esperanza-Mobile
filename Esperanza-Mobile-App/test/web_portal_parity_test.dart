// Mobile ↔ Citizen Web Portal feature parity (2026-10-07). Each group is a
// capability the web portal had and the app did not, on the same endpoint
// the web portal calls:
//
//  - Forgot / reset password (POST /auth/citizen/password/forgot, /reset)
//  - Valid ID verification after sign-up (GET/POST /citizen/verification/id)
//  - Attaching a Papeles document by reference (`papeles_id` on .../attach)
//  - The LGU's Help content (GET /site-content/faqs, tutorials, support)
//  - Support ticket history (GET /citizen/support/tickets)
//  - The published Terms and Conditions (GET /site-content/terms)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/id_verification.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/auth/forgot_password_screen.dart';
import 'package:esperanza_mobile/screens/auth/login_screen.dart';
import 'package:esperanza_mobile/screens/legal/terms_screen.dart';
import 'package:esperanza_mobile/screens/profile/id_verification_screen.dart';
import 'package:esperanza_mobile/screens/support/help_support_screen.dart';
import 'package:esperanza_mobile/screens/support/support_tickets_screen.dart';
import 'package:esperanza_mobile/services/account_privacy_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/message_language.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/site_content_service.dart';
import 'package:esperanza_mobile/services/support_service.dart';
import 'package:esperanza_mobile/utils/requirement_document_type.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:esperanza_mobile/widgets/server_requirement_uploader.dart';

import 'support/fake_api.dart';

const _ref = 'DOK-2026-00031';

Map<String, dynamic> _detail() => {
  'ref': _ref,
  'type': 'dokyu',
  'service': 'Barangay Clearance',
  'service_key': 'brgy_clearance',
  'status': 'Submitted',
  'submitted': '2026-10-07T00:00:00Z',
  'requirements': [
    {'key': 'req_1', 'label': 'Cedula', 'status': 'Pending Review', 'attachable': true, 'file': null},
  ],
  'history': [
    {'to': 'Submitted', 'at': '2026-10-07T00:00:00Z'},
  ],
};

Future<CitizenSessionService> _signedIn(WidgetTester? tester) async {
  final session = CitizenSessionService();
  if (tester != null) {
    await tester.runAsync(() => session.login(MockCatalog.demoAccounts.last));
  } else {
    await session.login(MockCatalog.demoAccounts.last);
  }
  return session;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  group('Forgot / reset password', () {
    test('asks for a code, then resets with it, on the web portal\'s endpoints', () async {
      final calls = <String>[];
      FakeApi.installFull((r) {
        calls.add('${r.method} ${r.path} ${r.body}');
        return {'sent': true};
      });

      await AccountPrivacyService.requestPasswordReset('  esp-res-2026-0004 ');
      await AccountPrivacyService.resetPassword(identifier: 'esp-res-2026-0004', code: '123456', password: 'Esperanza#2026');

      expect(calls[0], 'POST /auth/citizen/password/forgot {identifier: esp-res-2026-0004}');
      expect(calls[1], contains('POST /auth/citizen/password/reset'));
      expect(calls[1], contains('code: 123456'));
      expect(calls[1], contains('password_confirmation: Esperanza#2026'));
    });

    testWidgets('sign-in offers "Forgot password?", which walks request → reset → done', (tester) async {
      final calls = <String>[];
      FakeApi.installFull((r) {
        calls.add(r.path);
        return {'sent': true, 'reset': true};
      });
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = CitizenSessionService();
      await tester.pumpWidget(
        ChangeNotifierProvider<CitizenSessionService>.value(
          value: session,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Forgot password?'));
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'synthetic.resident@esperanza-test.invalid');
      await tester.tap(find.text('Send Code'));
      await tester.pumpAndSettle();
      expect(calls, ['/auth/citizen/password/forgot']);
      expect(find.text('Verification code'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '654321');
      await tester.enterText(fields.at(1), 'Esperanza#2026');
      await tester.enterText(fields.at(2), 'Esperanza#2026');
      final resetButton = find.widgetWithText(AppButton, 'Reset Password');
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(calls.last, '/auth/citizen/password/reset');
      expect(find.text('Password reset'), findsOneWidget);
    });
  });

  group('Valid ID verification after sign-up', () {
    test('a new ID is offered only where the server takes one and none is waiting', () {
      IdVerificationView view(bool canSubmit, String? status) => IdVerificationView.fromApi({
        'id_types': ['PhilSys National ID'],
        'can_submit': canSubmit,
        'submission': status == null ? null : {'id_type': 'PhilSys National ID', 'status': status},
      });
      expect(view(true, 'Rejected').canSendNew, isTrue);
      expect(view(true, null).canSendNew, isTrue);
      expect(view(true, 'Pending Review').canSendNew, isFalse, reason: 'one is still waiting for an officer');
      expect(view(false, 'Accepted').canSendNew, isFalse, reason: 'a verified account takes no ID');
    });

    testWidgets('a rejected ID shows the officer\'s reason and the form to send a new one', (tester) async {
      FakeApi.installFull((r) => {
        'id_types': ['PhilSys National ID', 'Driver\'s License'],
        'can_submit': true,
        'submission': {
          'id_type': 'Driver\'s License',
          'status': 'Rejected',
          'remarks': 'The photo is blurred.',
          'submitted_at': '2026-10-01T00:00:00Z',
          'reviewed_at': '2026-10-02T00:00:00Z',
        },
      });
      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: IdVerificationScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not accepted: The photo is blurred.'), findsOneWidget);
      expect(find.text('Send a New ID'), findsOneWidget);
      expect(find.text('Send for Verification'), findsOneWidget);
    });

    testWidgets('an ID waiting for review offers no second one', (tester) async {
      FakeApi.installFull((r) => {
        'id_types': ['PhilSys National ID'],
        'can_submit': true,
        'submission': {'id_type': 'PhilSys National ID', 'status': 'Pending Review'},
      });
      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: IdVerificationScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Waiting for the LGU to check it'), findsOneWidget);
      expect(find.text('Send for Verification'), findsNothing);
    });
  });

  group('Attaching a Papeles document by reference', () {
    test('attach with a Papeles id sends papeles_id and no file', () async {
      final calls = <String>[];
      FakeApi.installFull((r) {
        calls.add('${r.method} ${r.path} ${r.body}');
        return _detail();
      });
      final service = RequestsService();
      addTearDown(service.dispose);

      await service.attachRequirement(_ref, requirementKey: 'req_1', papelesId: 12);

      expect(calls, ['POST /citizen/requests/$_ref/requirements/req_1/attach {papeles_id: 12}']);
    });

    test('a new request\'s documents go by reference when they come from Papeles, by file otherwise', () async {
      final calls = <String>[];
      FakeApi.installFull((r) {
        calls.add('${r.method} ${r.path} ${r.body}');
        return _detail();
      });
      final service = RequestsService();
      addTearDown(service.dispose);
      final request = await service.loadDetail(_ref);
      calls.clear();

      final failed = await service.attachPicked(request, {
        'Cedula': Attachment(
          id: 'pap-12',
          fileName: 'synthetic-cedula.pdf',
          category: AttachmentCategory.pdf,
          sizeBytes: 1024,
          addedAt: DateTime(2026, 10, 7),
          documentTypeLabel: 'Cedula',
          papelesId: 12,
        ),
      });

      expect(failed, isEmpty, reason: 'a server-held document needs no file on this phone');
      expect(calls, ['POST /citizen/requests/$_ref/requirements/req_1/attach {papeles_id: 12}']);
    });

    Future<(CitizenSessionService, MasterFileService)> seedPapeles(WidgetTester tester, String type) async {
      final session = await _signedIn(tester);
      final masterFile = MasterFileService();
      FakeApi.installFull((r) => [
        {'id': 12, 'name': 'Synthetic Community Tax Certificate', 'type': type, 'category': 'Papeles', 'file_type': 'pdf', 'bytes': 1024},
      ]);
      await tester.runAsync(() => masterFile.syncFromServer(session.account!.id));
      return (session, masterFile);
    }

    Future<void> pumpUploader(
      WidgetTester tester,
      CitizenSessionService session,
      MasterFileService masterFile, {
      required bool allowPapeles,
      ValueChanged<Attachment>? onPicked,
    }) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<MasterFileService>.value(value: masterFile),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ServerRequirementUploader(
                label: 'Cedula',
                current: null,
                accent: Colors.blue,
                busy: false,
                serviceName: 'Barangay Clearance',
                category: ServiceCategory.dokyu,
                allowPapeles: allowPapeles,
                onPicked: onPicked ?? (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('"From My Papeles" offers a server-only document for an attach', (tester) async {
      final (session, masterFile) = await seedPapeles(tester, 'Synthetic Other Document');
      Attachment? picked;
      await pumpUploader(tester, session, masterFile, allowPapeles: true, onPicked: (a) => picked = a);

      await tester.tap(find.text('Upload Cedula'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('From My Papeles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Synthetic Community Tax Certificate'));
      await tester.pumpAndSettle();

      expect(picked?.papelesId, 12);
      expect(picked?.documentTypeLabel, 'Cedula');
      expect(picked?.localPath, isNull);
    });

    testWidgets('a replacement never offers Papeles: the server takes only a new file there', (tester) async {
      final (session, masterFile) = await seedPapeles(tester, 'Synthetic Other Document');
      await pumpUploader(tester, session, masterFile, allowPapeles: false);

      await tester.tap(find.text('Upload Cedula'));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('From My Papeles'), findsNothing);
    });

    testWidgets('a matching Papeles document is offered for reuse even when its file is not on this phone', (tester) async {
      final (session, masterFile) = await seedPapeles(tester, documentTypeFor('Cedula'));
      Attachment? picked;
      await pumpUploader(tester, session, masterFile, allowPapeles: true, onPicked: (a) => picked = a);

      await tester.tap(find.text('Use Existing Document'));
      await tester.pumpAndSettle();

      expect(picked?.papelesId, 12);
    });
  });

  group('Help content the LGU publishes', () {
    Object? helpHandler(FakeApiRequest r) => switch (r.path) {
      '/site-content/faqs' => {
        'sections': [
          {'q': 'How do I request a document online?', 'a': 'Go to Dokyu.', 'q_fil': 'Paano humiling ng dokumento?', 'a_fil': 'Pumunta sa Dokyu.'},
        ],
      },
      '/site-content/tutorials' => {
        'sections': [
          {'title': 'Requesting a clearance', 'duration': '3:24', 'video_url': 'https://example.invalid/video'},
          {'title': 'A tutorial with no video yet', 'duration': '4:10'},
        ],
      },
      '/site-content/support' => {
        'channels': [
          {'key': 'phone', 'label': 'Call the ICT Office', 'label_fil': 'Tawagan ang ICT Office', 'value': '(056) 000-0000'},
          {'key': 'email', 'label': 'Email Support', 'value': 'support@example.invalid'},
        ],
        'office_hours': 'Monday to Friday, 8:00 AM to 5:00 PM',
      },
      _ => throw const FakeApiError(status: 404),
    };

    test('FAQs follow the chosen language; a tutorial with neither a link nor a write-up is hidden, as on the web portal', () async {
      FakeApi.installFull(helpHandler);
      addTearDown(() => MessageLanguage.filipino.value = false);

      var help = await SiteContentService.help();
      expect(help.faqs.single.question, 'How do I request a document online?');
      expect(help.tutorials.map((t) => t.title), ['Requesting a clearance']);
      expect(help.channels.map((c) => c.value), ['(056) 000-0000', 'support@example.invalid']);
      expect(help.officeHours, 'Monday to Friday, 8:00 AM to 5:00 PM');

      MessageLanguage.filipino.value = true;
      help = await SiteContentService.help();
      expect(help.faqs.single.question, 'Paano humiling ng dokumento?');
      expect(help.channels.first.label, 'Tawagan ang ICT Office');
    });

    testWidgets('Help & Support shows the LGU\'s FAQs and real contact details, never placeholders', (tester) async {
      FakeApi.installFull(helpHandler);
      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: HelpSupportScreen())),
      );
      await tester.pumpAndSettle();

      // The website's tabs; the contact details are under Support.
      expect(find.text('FAQs'), findsOneWidget);
      expect(find.text('Tutorials'), findsOneWidget);
      expect(find.text('How do I request a document online?'), findsOneWidget);
      await tester.tap(find.text('Support'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('(056) 000-0000'), 300);
      expect(find.text('support@example.invalid'), findsOneWidget);
      expect(find.textContaining('TO BE PROVIDED'), findsNothing);
      await tester.scrollUntilVisible(find.text('Terms and Conditions'), 300);
      expect(find.text('Terms and Conditions'), findsOneWidget);
    });

    testWidgets('FAQs are searched and filtered by the LGU\'s categories, as on the website', (tester) async {
      FakeApi.installFull((r) => switch (r.path) {
            '/site-content/faqs' => {
              'sections': [
                {'q': 'How do I request a document online?', 'a': 'Go to Dokyu.', 'category': 'Documents'},
                {'q': 'Which files can I upload?', 'a': 'Photos and PDFs.', 'category': 'Mobile app'},
              ],
            },
            _ => throw const FakeApiError(status: 404),
          });
      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: HelpSupportScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tutorials'), findsNothing, reason: 'no tutorial is published');
      expect(find.text('2 results'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Mobile app'));
      await tester.pumpAndSettle();
      expect(find.text('Which files can I upload?'), findsOneWidget);
      expect(find.text('How do I request a document online?'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.enterText(find.byType(TextField), 'dokyu');
      await tester.pumpAndSettle();
      expect(find.text('1 result'), findsOneWidget);
      expect(find.text('How do I request a document online?'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nothing like this');
      await tester.pumpAndSettle();
      expect(find.text('No FAQs match your search.'), findsOneWidget);
    });

    test('the app\'s own help no longer says a profile photo comes from the gallery', () {
      // The app's own help answers are gone: every answer is the LGU's,
      // the profile photo one included (2026-10-22).
      final src = File('lib/screens/support/help_support_screen.dart').readAsStringSync();
      expect(src, isNot(contains('choose a new one from')));
      expect(src, isNot(contains('Troubleshooting')));
      expect(src, isNot(contains('simulated Face Verification')));
    });
  });

  group('Support ticket history', () {
    final tickets = [
      {
        'ref': 'TKT-2026-0042',
        'category': 'Dokyu',
        'subject': 'Cannot attach my cedula',
        'body': 'The upload stops halfway.',
        'status': 'Completed',
        'response': 'Fixed on our side. Please try again.',
        'responded_at': '2026-10-06T00:00:00Z',
        'attachment': null,
        'created_at': '2026-10-05T00:00:00Z',
      },
    ];

    test('lists the tickets with the office\'s reply', () async {
      FakeApi.installFull((r) => tickets);
      final list = await SupportService.myTickets();
      expect(list.single.ref, 'TKT-2026-0042');
      expect(list.single.response, 'Fixed on our side. Please try again.');
    });

    testWidgets('My Support Tickets shows the status, and the reply in the conversation', (tester) async {
      // The list, and a ticket's own detail (the conversation, 2026-10-15).
      FakeApi.installFull((r) => r.path.endsWith('/TKT-2026-0042') ? tickets.first : tickets);
      await tester.pumpWidget(const MaterialApp(home: SupportTicketsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Cannot attach my cedula'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Resolved by the office'), findsOneWidget);
      await tester.tap(find.text('Cannot attach my cedula'));
      await tester.pumpAndSettle();
      expect(find.text('Fixed on our side. Please try again.'), findsOneWidget);
    });
  });

  group('Terms and Conditions', () {
    testWidgets('shows the published Terms', (tester) async {
      FakeApi.installFull((r) => {
        'title': 'Terms and Conditions',
        'effective_date': '2026-01-15',
        'intro': 'These Terms govern the Platform.',
        'sections': [
          {'heading': '1. Acceptance of Terms', 'body': 'By registering you agree.'},
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: TermsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
      expect(find.text('These Terms govern the Platform.'), findsOneWidget);
    });

    testWidgets('offline with no saved copy says so and offers a retry', (tester) async {
      FakeApi.installFull((r) => throw const FakeApiError(status: 503));
      await tester.pumpWidget(const MaterialApp(home: TermsScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('could not be loaded'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
