// Functional coverage for Phase 5 — the richer Dokyu/Tulong milestone
// timeline and its frontend-only payment/rejection simulation. Drives the
// real RequestDetailScreen (not just RequestMilestoneTimeline in
// isolation) so the demo controls, payment method sheet, and rejection
// reason card are all exercised the way a presenter actually would.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/receipt.dart';
import 'package:esperanza_mobile/models/request_milestones.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_status.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

Future<RequestsService> _pumpDetail(WidgetTester tester, String requestId) async {
  // The default 800x600 test canvas is unusually wide/short and leaves
  // this screen's lower content (the demo controls, well below the info
  // card + full timeline) outside the initial render/cache extent of the
  // ListView's Sliver — a realistic phone viewport avoids that, matching
  // every other functional suite in this app.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final requests = RequestsService(seedDemoData: true);
  var attempts = 0;
  await tester.pumpWidget(const SizedBox.shrink());
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }

  await tester.pumpWidget(
    ChangeNotifierProvider<RequestsService>.value(
      value: requests,
      child: MaterialApp(home: RequestDetailScreen(requestId: requestId)),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  // Drives the ListView's ScrollPosition directly to the very bottom
  // rather than a gesture-based drag/scrollUntilVisible — both of those
  // compute an offset from the target's *current* on-screen rect, which
  // is unreliable once this screen's content (full payment-sequence
  // timeline + demo controls) is taller than a single scroll increment.
  // Same technique already used successfully elsewhere in this suite (see
  // home_assets_integration_test.dart).
  final scrollable = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _tapNextDemoStep(WidgetTester tester) => _scrollToAndTap(tester, find.widgetWithText(AppButton, 'Next Demo Step'));

void main() {
  group('No-payment path (Certificate of Indigency-style free service)', () {
    testWidgets('demo-tulong-medical (free) advances Pending Review -> ... -> Completed with no payment steps', (
      tester,
    ) async {
      final requests = await _pumpDetail(tester, 'demo-tulong-medical');

      expect(requests.all.firstWhere((r) => r.id == 'demo-tulong-medical').requiresPayment, isFalse);

      // Starts at Pending Review (seeded). Keep advancing until the
      // service itself reports the sequence exhausted (Completed) — driven
      // off canAdvance() rather than the button's on-screen presence, since
      // the button may simply be scrolled out of the *current* position
      // without that meaning the sequence is actually done.
      var guard = 0;
      while (requests.canAdvance('demo-tulong-medical')) {
        guard++;
        if (guard > 10) fail('Next Demo Step never reached the end of the sequence.');
        await _tapNextDemoStep(tester);
      }

      expect(find.text(RequestMilestones.completed), findsWidgets);
      expect(find.text(RequestMilestones.waitingForPayment), findsNothing);
      expect(find.text('Choose Payment Method (Demo)'), findsNothing);
      expect(tester.takeException(), isNull);

      final finalRequest = requests.all.firstWhere((r) => r.id == 'demo-tulong-medical');
      expect(finalRequest.status, 'Completed');
    });
  });

  group('Payment-required path (Barangay Clearance, ₱50.00)', () {
    testWidgets('Onsite: reaches Waiting for Payment, choosing Onsite shows municipal-office copy, then completes', (
      tester,
    ) async {
      final requests = await _pumpDetail(tester, 'demo-dokyu-barangay-clearance');
      final seeded = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance');
      expect(seeded.requiresPayment, isTrue);
      expect(seeded.status, 'Approved'); // seeded final status — next step is Waiting for Payment

      await _tapNextDemoStep(tester); // Approved -> Waiting for Payment
      expect(find.text(RequestMilestones.waitingForPayment), findsWidgets);
      expect(find.text('Choose Payment Method (Demo)'), findsOneWidget);

      await _scrollToAndTap(tester, find.widgetWithText(AppButton, 'Choose Payment Method (Demo)'));
      expect(find.text('Choose Payment Method'), findsOneWidget); // sheet title
      expect(find.text('Pay at Municipal Office'), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);

      await tester.tap(find.text('Pay at Municipal Office'));
      await tester.pumpAndSettle();

      var request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance');
      expect(request.paymentMethod, 'Onsite');
      expect(request.status, RequestMilestones.canonicalStatusFor(RequestMilestones.paymentMethodSelected).label);
      expect(find.textContaining('Payment to be completed at Municipal Office'), findsOneWidget);

      await _tapNextDemoStep(tester); // Payment Method Selected -> Payment Processing
      await _tapNextDemoStep(tester); // Payment Processing -> Receipt Generated

      request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance');
      // Generated from the request's own catalog fee/applicant/reference —
      // never an invented amount.
      expect(request.receipt, isNotNull);
      expect(request.receipt!.type, ReceiptType.onsite);
      expect(request.receipt!.amount, seeded.fee);
      expect(request.receipt!.residentName, seeded.applicantName);
      expect(request.receipt!.requestReferenceNumber, seeded.referenceNumber);

      await _tapNextDemoStep(tester); // Receipt Generated -> Paid
      await _tapNextDemoStep(tester); // Paid -> Ready for Release
      await _tapNextDemoStep(tester); // Ready for Release -> Completed

      request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance');
      expect(request.status, 'Completed');
      // The receipt survives all the way to the end of the sequence.
      expect(request.receipt, isNotNull);
      expect(find.widgetWithText(AppButton, 'Next Demo Step'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GCash: choosing an online method is clearly marked Demo/Simulation and never leaves Onsite copy', (
      tester,
    ) async {
      final requests = await _pumpDetail(tester, 'demo-dokyu-barangay-clearance');
      await _tapNextDemoStep(tester); // -> Waiting for Payment
      await _scrollToAndTap(tester, find.widgetWithText(AppButton, 'Choose Payment Method (Demo)'));

      expect(find.text('DEMO'), findsNWidgets(2)); // GCash + Maya tiles, not Onsite

      await tester.tap(find.text('GCash'));
      await tester.pumpAndSettle();

      final request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance');
      expect(request.paymentMethod, 'GCash');
      expect(find.textContaining('GCash (Demo / Simulation)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Rejected branch', () {
    testWidgets('Reject (Demo) branches to Rejected and shows the reason card, no further advance possible', (
      tester,
    ) async {
      final requests = await _pumpDetail(tester, 'demo-tulong-financial');
      expect(requests.all.firstWhere((r) => r.id == 'demo-tulong-financial').status, 'Approved');

      await _scrollToAndTap(tester, find.text('Reject Request (Demo)'));
      expect(find.text('Reject this request? (Demo)'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Reject (Demo)'));
      await tester.pumpAndSettle();

      final request = requests.all.firstWhere((r) => r.id == 'demo-tulong-financial');
      expect(request.status, 'Rejected');
      expect(request.adminRemarks, contains('did not match the information shown on your valid ID'));
      expect(find.text('Reason for Rejection'), findsOneWidget);
      expect(find.textContaining('did not match the information shown on your valid ID'), findsWidgets);
      // No demo controls remain once terminal.
      expect(find.widgetWithText(AppButton, 'Next Demo Step'), findsNothing);
      expect(find.text('Reject Request (Demo)'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
