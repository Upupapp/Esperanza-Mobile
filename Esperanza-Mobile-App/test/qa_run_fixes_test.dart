// What the live QA run of 2026-10-04 found on the Android app against
// staging, pinned so it cannot come back. Each test is named for what a
// resident saw. Nothing here reaches the network.
import 'dart:convert';

import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/utils/banner_memory.dart';
import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/utils/requirement_document_type.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:esperanza_mobile/widgets/live_banners.dart';
import 'package:esperanza_mobile/widgets/requirement_uploader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

void main() {
  tearDown(FakeApi.restore);

  test('a refused sign-in says what is wrong, not "some fields need correcting"', () {
    const e = ApiException(
      status: 422,
      code: 'VALIDATION_FAILED',
      messageFil: 'May mga field na kailangang itama.',
      messageEn: 'Some fields need to be corrected.',
      fields: {
        'identifier': ['Maling identifier o password. / Invalid identifier or password.'],
      },
    );
    expect(e.explain(), 'Maling identifier o password.');
    expect(e.explain(filipino: false), 'Invalid identifier or password.');

    const plain = ApiException(status: 500, messageEn: 'Server error', messageFil: 'May mali');
    expect(plain.explain(filipino: false), 'Server error', reason: 'no field message: the envelope');
  });

  test('a replaced document stays on the correction list, so Resubmit stays', () async {
    api = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'ref': 'TUL-2026-00001',
              'type': 'tulong',
              'status': 'Needs Requirements',
              'history': [
                {'from': 'Initial Screening', 'to': 'Needs Requirements', 'at': '2026-10-04T01:00:00Z'},
              ],
              'needs_correction': [
                {'key': 'valid_id', 'label': 'Valid ID', 'reason': 'Unreadable', 'remarks': 'Clearer copy', 'resolved': true},
                {'key': 'indigency', 'label': 'Certificate of Indigency', 'reason': 'Expired', 'remarks': null, 'resolved': false},
              ],
              'can_resubmit': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
      baseUrl: 'https://test.invalid',
    );
    final service = RequestsService();
    addTearDown(service.dispose);

    final r = await service.loadDetail('TUL-2026-00001');

    expect(r.flaggedRequirements.map((f) => f.id), ['valid_id', 'indigency']);
    expect(r.flaggedRequirements.first.isResolved, isTrue);
    expect(r.flaggedRequirements.last.isResolved, isFalse);
  });

  test('the history of a request starts with when it was filed', () async {
    api = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'ref': 'TUL-2026-00009',
              'type': 'tulong',
              'status': 'Needs Requirements',
              'submitted': '2026-10-04T06:16:00Z',
              'history': [
                {'from': 'Submitted', 'to': 'Initial Screening', 'at': '2026-10-04T06:21:00Z'},
                {'from': 'Initial Screening', 'to': 'Needs Requirements', 'at': '2026-10-04T06:21:30Z'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
      baseUrl: 'https://test.invalid',
    );
    final service = RequestsService();
    addTearDown(service.dispose);

    final r = await service.loadDetail('TUL-2026-00009');

    expect(r.statusHistory.map((h) => h.status), ['Submitted', 'Initial Screening', 'Needs Requirements']);
    expect(r.statusHistory.first.at, DateTime.utc(2026, 10, 4, 6, 16));
  });

  test('a request with a fee carries its amount, status and receipt; a free one has none', () async {
    var paid = true;
    api = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'ref': 'DOK-2026-00009',
              'type': 'dokyu',
              'status': 'Under Verification',
              'submitted': '2026-10-05T01:00:00Z',
              'payment': paid ? {'ref': 'PAY-2026-00009', 'amount': 30, 'status': 'Approved', 'receipt_no': 'OR-2026-0000009'} : null,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
      baseUrl: 'https://test.invalid',
    );
    final service = RequestsService();
    addTearDown(service.dispose);

    final r = await service.loadDetail('DOK-2026-00009');
    expect(r.payment?.amount, 30);
    expect(r.payment?.isPaid, isTrue);
    expect(r.payment?.receiptNo, 'OR-2026-0000009');

    paid = false;
    final free = await service.loadDetail('DOK-2026-00009');
    expect(free.payment, isNull);
  });

  test('the banners staff publish are read from the live list', () async {
    api = ApiClient(
      httpClient: MockClient((req) async {
        expect(req.url.path, endsWith('/banners'));
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 4, 'title': 'Sample Fiesta', 'subtitle': 'Sample line', 'cta_label': 'View', 'cta_route': 'citizen.events', 'theme': 'from-purple-600 to-navy-900', 'image_url': null},
              {'id': 5, 'title': '', 'theme': null},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'https://test.invalid',
    );

    final banners = await LiveBanner.load();
    expect(banners, hasLength(1), reason: 'a banner without a title is skipped');
    expect(banners.single.title, 'Sample Fiesta');
    expect(banners.single.action, isNotNull, reason: 'the events button opens the Events tab');
    expect(LiveBanner.fromApi(const {'title': 'x', 'cta_route': 'citizen.dashboard'}).action, isNull, reason: 'Home itself is the dashboard');
  });

  testWidgets('a live banner shows its title, subtitle and button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveBannersStrip(
            banners: [
              LiveBanner(title: 'Sample Fiesta', subtitle: 'Sample line', ctaLabel: 'View', ctaRoute: 'citizen.events'),
              LiveBanner(title: 'Second sample', ctaLabel: 'Hidden', ctaRoute: 'citizen.dashboard'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Sample Fiesta'), findsOneWidget);
    expect(find.text('Sample line'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Second sample'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing, reason: 'no button where it would lead to this same screen');
  });

  test('each promotional poster is shown once on a phone, not on every app start', () async {
    SharedPreferences.setMockInitialValues({});
    var shown = 0;

    await BannerMemory.showOnce('assets/images/Dokyu Tab.png', () => shown++);
    await BannerMemory.showOnce('assets/images/Dokyu Tab.png', () => shown++);
    expect(shown, 1);

    await BannerMemory.showOnce('assets/images/Tulong Tab.png', () => shown++);
    expect(shown, 2, reason: 'another poster still shows');
  });

  testWidgets('a screen reader reaches Replace on its own inside a correction card', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('Application Needs Correction'),
              const Text('Reason: the ID is cut off'),
              RequirementUploader(
                requirement: const RequirementInfo(label: 'Valid ID', documentType: 'Valid ID', isRequired: true),
                attachment: Attachment(
                  id: 'a1',
                  fileName: 'valid-id-sample.pdf',
                  category: AttachmentCategory.pdf,
                  sizeBytes: 41000,
                  addedAt: DateTime(2026, 10, 4),
                  documentTypeLabel: 'Valid ID',
                ),
                accent: Colors.purple,
                existingMasterDoc: null,
                showTitle: false,
                onAttachNew: (_) {},
                onUseExisting: () {},
              ),
            ],
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.text('Replace'));
    expect(node.label, 'Replace', reason: 'its own node, not merged into the card');
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('a disabled button looks disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppButton(label: 'Resubmit Application', onPressed: null),
            ],
          ),
        ),
      ),
    );
    final dimmed = tester.widget<Opacity>(
      find.ancestor(of: find.text('Resubmit Application'), matching: find.byType(Opacity)).first,
    );
    expect(dimmed.opacity, lessThan(1));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppButton(label: 'Resubmit Application', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    final active = tester.widget<Opacity>(
      find.ancestor(of: find.text('Resubmit Application'), matching: find.byType(Opacity)).first,
    );
    expect(active.opacity, 1);
  });
}
