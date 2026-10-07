// End-to-end test 2026-10-07: a resident could not take back a request.
// A Tulong request the office has not recommended yet can be withdrawn from
// its detail (POST /citizen/requests/{ref}/withdraw, offered while the
// server's `can_withdraw` says so); once cancelled, the timeline says why.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

import 'support/fake_api.dart';

const _ref = 'TUL-2026-09001';

Map<String, dynamic> _detail({required String status, required bool canWithdraw, String? remarks}) => {
  'ref': _ref,
  'type': 'tulong',
  'service': 'Educational Assistance',
  'service_key': 'tulong_educational',
  'status': status,
  'submitted': '2026-10-07T00:00:00Z',
  'office': 'MSWDO',
  'decision_remarks': remarks,
  'can_withdraw': canWithdraw,
  'requirements': const [],
  'history': [
    {'to': 'Submitted', 'at': '2026-10-07T00:00:00Z'},
    {'from': 'Submitted', 'to': status, 'at': '2026-10-07T01:00:00Z'},
  ],
};

Future<void> _pump(WidgetTester tester, RequestsService requests) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    if (++attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  tester.view.physicalSize = const Size(390, 2400);
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

  testWidgets('a Tulong request in screening is withdrawn after a confirmation', (tester) async {
    final calls = <String>[];
    FakeApi.installFull((req) {
      if (req.method == 'POST' && req.path.endsWith('/withdraw')) {
        calls.add(req.path);
        return _detail(status: 'Cancelled', canWithdraw: false, remarks: 'Withdrawn by the resident.');
      }
      return _detail(status: 'Initial Screening', canWithdraw: true);
    });
    final requests = RequestsService();
    await _pump(tester, requests);

    expect(find.widgetWithText(AppButton, 'Withdraw Request'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Withdraw Request'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw this request?'), findsOneWidget);

    // Keep it: nothing is sent.
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    await tester.tap(find.widgetWithText(AppButton, 'Withdraw Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();

    expect(calls, ['/citizen/requests/$_ref/withdraw']);
    expect(find.text('Reason for Cancellation'), findsOneWidget);
    expect(find.text('Withdrawn by the resident.'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Withdraw Request'), findsNothing, reason: 'a cancelled request is not withdrawn twice');
  });

  testWidgets('no Withdraw once the office has recommended it', (tester) async {
    FakeApi.installFull((req) => _detail(status: 'For Approval', canWithdraw: false));
    await _pump(tester, RequestsService());
    expect(find.widgetWithText(AppButton, 'Withdraw Request'), findsNothing);
  });
}
