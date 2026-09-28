// The request title and its status badge share one row. They used to be split
// 50/50 (Expanded + Flexible), so a short badge left space the title could not
// use and "Barangay Clearance" wrapped beside it. The badge is now capped
// instead; the title takes the rest.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';

import 'support/fake_api.dart';

Future<void> _pump(WidgetTester tester, {required double width, required String service, required String status}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  FakeApi.installFull((_) => {'ref': 'DR-1', 'type': 'dokyu', 'service': service, 'status': status, 'office': 'Office'});
  addTearDown(FakeApi.restore);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
      ],
      child: const MaterialApp(home: RequestDetailScreen(requestId: 'DR-1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a short title fits on one line beside a short badge', (tester) async {
    await _pump(tester, width: 390, service: 'Barangay Clearance', status: 'Approved');
    // Font-independent: the width the title may use, against the width of
    // the office line below it (the full row). A 50/50 split gave the title
    // about half; now it gets everything the capped badge does not take.
    final titleMax = tester.renderObject<RenderParagraph>(find.text('Barangay Clearance')).constraints.maxWidth;
    final rowWidth = tester.renderObject<RenderParagraph>(find.text('Office')).constraints.maxWidth;
    expect(titleMax, greaterThan(rowWidth * 0.55));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long title and a long badge do not overflow at 280pt', (tester) async {
    await _pump(
      tester,
      width: 280,
      service: 'Certificate of Indigency for Medical and Burial Assistance',
      status: 'Under Verification',
    );
    expect(tester.takeException(), isNull);
  });
}
