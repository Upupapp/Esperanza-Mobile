// Tulong runs its own case lifecycle, not the request lifecycle Dokyu runs.
//
// The web declares the set in `config/esperanza_tulong_lifecycle.php` and the
// backend has run it since its finding B-044 closed (2026-10-04). The lists
// below are transcribed from that file on the web repo's origin/main; when this
// test fails, re-read the config there, do not "fix" the expectation. AppStatus
// stays the badge component's labels (status_parity_test.dart); a Tulong case's
// own statuses resolve through TulongStatus instead, and before that existed a
// case in Initial Screening tripped fromLabel's assertion and read as "Draft".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_status.dart';
import 'package:esperanza_mobile/theme/tulong_status.dart';
import 'package:esperanza_mobile/utils/peso_text.dart';
import 'package:esperanza_mobile/widgets/status_chip.dart';

import 'support/fake_api.dart';

const _ref = 'TUL-2026-00042';

Map<String, dynamic> _case(String status, {Map<String, dynamic>? assistance, List<Map<String, dynamic>>? history}) => {
  'ref': _ref,
  'type': 'tulong',
  'service': 'Educational Assistance',
  'service_key': 'tulong_educational',
  'status': status,
  'submitted': '2026-10-04T00:00:00Z',
  'office': 'MSWDO',
  'requirements': const [],
  'needs_correction': const [],
  'assistance': ?assistance,
  'history':
      history ??
      [
        {'to': 'Submitted', 'at': '2026-10-04T00:00:00Z'},
        {'from': 'Submitted', 'to': 'Initial Screening', 'at': '2026-10-04T01:00:00Z'},
        {'from': 'Initial Screening', 'to': 'Assessment', 'at': '2026-10-04T02:00:00Z'},
        {'from': 'Assessment', 'to': 'For Approval', 'at': '2026-10-04T03:00:00Z'},
        {'from': 'For Approval', 'to': 'Assistance Processing', 'at': '2026-10-04T04:00:00Z'},
      ],
};

Future<void> _pumpDetail(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final requests = RequestsService();
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    if (++attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
      ],
      child: const MaterialApp(home: RequestDetailScreen(requestId: _ref)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(FakeApi.restore);

  group('the vocabulary is the web config\'s', () {
    test('main sequence, side states, terminal, all, tulong_only', () {
      expect(TulongStatus.mainSequence, [
        'Submitted',
        'Initial Screening',
        'Assessment',
        'For Approval',
        'Assistance Processing',
        'Ready for Release',
        'Completed',
      ]);
      expect(TulongStatus.sideStates, ['Needs Requirements', 'Returned for Reassessment']);
      expect(TulongStatus.terminal, ['Completed', 'Rejected', 'Cancelled']);
      expect(TulongStatus.all, [
        'Submitted',
        'Initial Screening',
        'Assessment',
        'For Approval',
        'Assistance Processing',
        'Ready for Release',
        'Completed',
        'Needs Requirements',
        'Returned for Reassessment',
        'Rejected',
        'Cancelled',
      ]);
      expect(TulongStatus.tulongOnly.toSet(), {
        'Initial Screening',
        'Assessment',
        'For Approval',
        'Assistance Processing',
        'Ready for Release',
        'Needs Requirements',
        'Returned for Reassessment',
      });
    });

    test('it stands beside AppStatus: the shared four resolve there, the seven never do', () {
      final appLabels = AppStatus.values.map((s) => s.label).toSet();
      expect(TulongStatus.tulongOnly.where(appLabels.contains), isEmpty);
      expect(TulongStatus.all.where(appLabels.contains).toSet(), {'Submitted', 'Completed', 'Rejected', 'Cancelled'});
    });
  });

  test('every Tulong status shows in its own colour, and only the terminal ones are done', () {
    for (final label in TulongStatus.all) {
      final view = RequestStatusView(label);
      expect(view.style.background, isNot(AppStatus.draft.style.background), reason: '$label reads as Draft');
      expect(view.isDone, TulongStatus.terminal.contains(label), reason: '$label isDone');
    }
  });

  test('the detail carries what was approved and what was received', () async {
    FakeApi.installFull(
      (req) => _case(
        'Completed',
        assistance: {'approved_amount': '4000.00', 'released_amount': '4000.00', 'release_reference': 'DV-2026-0042', 'released_at': '2026-10-04T05:00:00Z'},
      ),
    );
    final service = RequestsService();
    addTearDown(service.dispose);

    final r = await service.loadDetail(_ref);

    expect(r.assistance?.approvedAmount, '4000.00');
    expect(r.assistance?.releaseReference, 'DV-2026-0042');
    expect(r.assistance?.office, 'MSWDO');
    expect(pesoText(r.assistance?.releasedAmount), '₱4,000.00');
  });

  testWidgets('an approved case shows its own stage, the seven steps and the approved amount', (tester) async {
    FakeApi.installFull((req) => _case('Assistance Processing', assistance: {'approved_amount': '4000.00'}));
    await _pumpDetail(tester);

    final chips = tester.widgetList<StatusChip>(find.byType(StatusChip));
    expect(chips.map((c) => c.requestStatus), contains('Assistance Processing'));
    for (final step in TulongStatus.mainSequence) {
      expect(find.text(step), findsWidgets, reason: 'the timeline is missing "$step"');
    }
    // Dokyu's steps are not a Tulong case's.
    expect(find.text('Under Verification'), findsNothing);
    expect(find.text('Mark to Release'), findsNothing);
    expect(find.text('Approved — being prepared'), findsOneWidget);
    expect(find.text('₱4,000.00'), findsOneWidget);
  });

  testWidgets('a case returned for reassessment tells the resident nothing is needed', (tester) async {
    FakeApi.installFull(
      (req) => _case(
        'Returned for Reassessment',
        history: [
          {'to': 'Submitted', 'at': '2026-10-04T00:00:00Z'},
          {'from': 'Submitted', 'to': 'Initial Screening', 'at': '2026-10-04T01:00:00Z'},
          {'from': 'Initial Screening', 'to': 'Assessment', 'at': '2026-10-04T02:00:00Z'},
          {'from': 'Assessment', 'to': 'For Approval', 'at': '2026-10-04T03:00:00Z'},
          {'from': 'For Approval', 'to': 'Returned for Reassessment', 'at': '2026-10-04T04:00:00Z'},
        ],
      ),
    );
    await _pumpDetail(tester);

    expect(find.textContaining('Nothing is needed from you'), findsOneWidget);
    // Not approved yet: no amount card.
    expect(find.text('Approved amount'), findsNothing);
  });


  test('pesoText groups thousands and keeps centavos', () {
    expect(pesoText('4000.00'), '₱4,000.00');
    expect(pesoText(1234567.5), '₱1,234,567.50');
    expect(pesoText('15'), '₱15.00');
    expect(pesoText(null), isNull);
    expect(pesoText('n/a'), isNull);
  });
}
