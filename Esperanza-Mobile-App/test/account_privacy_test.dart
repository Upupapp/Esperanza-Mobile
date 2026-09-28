// The account and privacy features the backend already had and the app did
// not: the Municipality's published Privacy Policy (in place of the app's
// own text with `[TO BE PROVIDED]` placeholders), change password, and
// data-subject requests.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/content/privacy_policy_v1.dart';
import 'package:esperanza_mobile/screens/legal/privacy_policy_screen.dart';
import 'package:esperanza_mobile/screens/profile/change_password_screen.dart';
import 'package:esperanza_mobile/screens/profile/data_requests_screen.dart';
import 'package:esperanza_mobile/services/account_privacy_service.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/site_content_service.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:esperanza_mobile/widgets/app_text_field.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _published({int version = 2, String contact = 'Call the ICT Office at (056) 000-0000.'}) => {
  'doc_key': 'privacy',
  'version': version,
  'title': 'Privacy Policy',
  'effective_date': '2026-10-01',
  'intro': 'Published intro.',
  'sections': [
    {'heading': '1. What we collect', 'body': 'Only what a service needs.'},
    {'heading': '9. Contact Us', 'body': contact},
    {'unexpected': 'no heading or body: skipped'},
  ],
};

Future<void> _type(WidgetTester tester, String label, String text) async {
  final field = find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(TextField));
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String text) async {
  final button = find.widgetWithText(AppButton, text);
  final f = button.evaluate().isNotEmpty ? button : find.text(text).last;
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  group('Privacy Policy is the one the Municipality publishes', () {
    test('live, then the saved copy when offline, then the bundled version 1', () async {
      var online = true;
      FakeApi.installFull((r) {
        expect(r.path, '/site-content/privacy');
        if (!online) throw const FakeApiError(status: 503, code: 'UNAVAILABLE');
        return _published();
      });

      final live = await SiteContentService.privacyPolicy();
      expect(live.source, ContentSource.live);
      expect(live.version, 2);
      expect(live.effectiveDate, DateTime(2026, 10, 1));
      expect(live.sections.map((s) => s.heading), ['1. What we collect', '9. Contact Us']);

      online = false;
      final saved = await SiteContentService.privacyPolicy();
      expect(saved.source, ContentSource.saved);
      expect(saved.version, 2);

      SharedPreferences.setMockInitialValues({});
      final bundled = await SiteContentService.privacyPolicy();
      expect(bundled.source, ContentSource.bundled);
      expect(bundled.version, 1);
    });

    test('nothing published yet (404) falls back rather than showing an empty policy', () async {
      FakeApi.installFull((r) => throw const FakeApiError(status: 404));
      final doc = await SiteContentService.privacyPolicy();
      expect(doc.source, ContentSource.bundled);
      expect(doc.sections, isNotEmpty);
    });

    test('the bundled copy has a date and a contact, and no placeholder', () {
      final doc = SiteContentService.bundledPrivacyPolicyDocument;
      expect(doc.effectiveDate, isNotNull);
      expect(doc.sections.length, (bundledPrivacyPolicy['sections'] as List).length);
      expect(doc.sections.last.body, contains('Data Protection Officer'));
      for (final file in ['lib/content/privacy_policy_v1.dart', 'lib/screens/legal/privacy_policy_screen.dart']) {
        expect(File(file).readAsStringSync(), isNot(contains('TO BE PROVIDED')), reason: file);
      }
    });

    testWidgets('the screen shows the published text and its date, and offers data requests when signed in', (
      tester,
    ) async {
      FakeApi.installFull((r) => _published(contact: 'Email privacy@example.invalid.'));
      final session = CitizenSessionService();
      addTearDown(session.dispose);
      tester.view.physicalSize = const Size(400, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: session,
          child: const MaterialApp(home: PrivacyPolicyScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Effective Oct 1, 2026 · Version 2'), findsOneWidget);
      expect(find.text('9. Contact Us'), findsOneWidget);
      expect(find.text('Make a Data Request'), findsNothing, reason: 'signed out');
    });
  });

  group('change password', () {
    testWidgets('checks the new password on the phone before sending anything', (tester) async {
      final sent = <FakeApiRequest>[];
      FakeApi.installFull((r) {
        sent.add(r);
        return {'changed': true};
      });
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));

      await _type(tester, 'Current password', 'Old!Pass123');
      await _type(tester, 'New password', 'short');
      await _type(tester, 'Confirm new password', 'short');
      await _tap(tester, 'Change Password');
      expect(sent, isEmpty);
      expect(find.text('Dapat hindi bababa sa 8 characters ang password.'), findsOneWidget);

      await _type(tester, 'New password', 'New!Pass456');
      await _type(tester, 'Confirm new password', 'New!Pass457');
      await _tap(tester, 'Change Password');
      expect(sent, isEmpty);
      expect(find.text('The two new passwords do not match.'), findsOneWidget);
    });

    testWidgets('sends PUT /citizen/password with the confirmation', (tester) async {
      FakeApiRequest? sent;
      FakeApi.installFull((r) {
        sent = r;
        return {'changed': true};
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await _tap(tester, 'open');
      await _type(tester, 'Current password', 'Old!Pass123');
      await _type(tester, 'New password', 'New!Pass456');
      await _type(tester, 'Confirm new password', 'New!Pass456');
      await _tap(tester, 'Change Password');

      expect(sent!.method, 'PUT');
      expect(sent!.path, '/citizen/password');
      expect(sent!.body, {
        'current_password': 'Old!Pass123',
        'password': 'New!Pass456',
        'password_confirmation': 'New!Pass456',
      });
      expect(find.byType(ChangePasswordScreen), findsNothing, reason: 'closes on success');
    });

    testWidgets('a wrong current password is shown on that field', (tester) async {
      // A real ApiClient over the backend's exact 422 envelope
      // (CitizenPortalController::changePassword), so the per-field error is
      // parsed the way it is in the app.
      api = ApiClient(
        baseUrl: 'https://test.invalid',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'code': 'VALIDATION_FAILED',
                'message': {'fil': 'Mali ang kasalukuyang password.', 'en': 'The current password is incorrect.'},
                'fields': {
                  'current_password': ['Incorrect password.'],
                },
              },
            }),
            422,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await _type(tester, 'Current password', 'Wrong!Pass1');
      await _type(tester, 'New password', 'New!Pass456');
      await _type(tester, 'Confirm new password', 'New!Pass456');
      await _tap(tester, 'Change Password');
      expect(find.text('That is not your current password.'), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });
  });

  group('data requests', () {
    test('only the backend kinds are offered', () {
      expect(AccountPrivacyService.kinds.map((k) => k.key), ['access', 'correction', 'erasure', 'portability']);
    });

    testWidgets('lists past requests and files a new one', (tester) async {
      final sent = <FakeApiRequest>[];
      FakeApi.installFull((r) {
        sent.add(r);
        if (r.method == 'POST') {
          return {
            'ref': 'DSR-2026-0002',
            'kind': r.body!['kind'],
            'detail': r.body!['detail'],
            'status': 'Submitted',
            'submitted_at': '2026-09-28T02:00:00Z',
          };
        }
        return [
          {
            'ref': 'DSR-2026-0001',
            'kind': 'access',
            'detail': 'Everything you hold about me.',
            'status': 'Completed',
            'resolution': 'Sent by email.',
            'submitted_at': '2026-09-01T02:00:00Z',
          },
          {'kind': 'no ref: skipped'},
        ];
      });
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: DataRequestsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('DSR-2026-0001 · Sep 1, 2026'), findsOneWidget);
      expect(find.text('Response: Sent by email.'), findsOneWidget);

      await _tap(tester, 'Send Request');
      expect(sent.where((r) => r.method == 'POST'), isEmpty, reason: 'nothing chosen yet');

      await _tap(tester, 'Correct my data');
      await _type(tester, 'Details', '  My birthdate is wrong.  ');
      await _tap(tester, 'Send Request');

      final post = sent.singleWhere((r) => r.method == 'POST');
      expect(post.path, '/citizen/data-requests');
      expect(post.body, {'kind': 'correction', 'detail': 'My birthdate is wrong.'});
      expect(find.textContaining('DSR-2026-0002'), findsWidgets);
    });
  });
}
