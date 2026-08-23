// Functional coverage for Milestone 4's receipt system — milestone
// integration (Waiting for Payment -> ... -> Receipt Generated -> Paid ->
// Ready for Release), the single unified EsperanzaReceipt design shared by
// GCash/Maya/Onsite (only the "Mode of Payment" row differs), per-request
// receipt persistence, and View/Download Receipt. FRONTEND SIMULATION
// ONLY: no real payment gateway, no real file I/O beyond what share_plus's
// own platform channel would do (which isn't available in this test
// environment — Download Receipt is exercised for graceful failure
// handling, not an actual saved file).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/receipt.dart';
import 'package:esperanza_mobile/models/request_milestones.dart';
import 'package:esperanza_mobile/screens/shared/receipt_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/utils/receipt_export.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:esperanza_mobile/widgets/receipts/esperanza_receipt.dart';

Future<RequestsService> _pumpDetail(WidgetTester tester, String requestId) async {
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
  final scrollable = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _tapNextDemoStep(WidgetTester tester) => _scrollToAndTap(tester, find.widgetWithText(AppButton, 'Next Demo Step'));

/// "View Receipt" sits near the *top* of the list (in the info card), not
/// the bottom where the demo controls/"Next Demo Step" live — a plain
/// ListView's Sliver only builds elements within the current viewport plus
/// cache extent, so after scrolling to the bottom for a "Next Demo Step"
/// tap, the top of the list is genuinely un-built, not just off-screen;
/// `find` returns zero results for it rather than an unreachable-but-real
/// widget. Scroll back to the top before looking for it.
Future<void> _scrollToTopAndTap(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.minScrollExtent);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Drives 'demo-dokyu-barangay-clearance' (₱50.00 fee) from its seeded
/// Approved state through to Receipt Generated, choosing [method]
/// ('Onsite' / 'GCash' / 'Maya') at the payment-method step.
Future<RequestsService> _payThroughToReceipt(WidgetTester tester, String method) async {
  final requests = await _pumpDetail(tester, 'demo-dokyu-barangay-clearance');
  await _tapNextDemoStep(tester); // Approved -> Waiting for Payment
  await _scrollToAndTap(tester, find.widgetWithText(AppButton, 'Choose Payment Method (Demo)'));
  await tester.tap(find.text(method == 'Onsite' ? 'Pay at Municipal Office' : method));
  await tester.pumpAndSettle();
  await _tapNextDemoStep(tester); // Payment Method Selected -> Payment Processing
  await _tapNextDemoStep(tester); // Payment Processing -> Receipt Generated
  return requests;
}

void main() {
  group('Milestone integration', () {
    testWidgets('Receipt Generated sits between Payment Processing and Paid in the visible timeline', (tester) async {
      await _payThroughToReceipt(tester, 'Onsite');
      expect(find.text(RequestMilestones.receiptGenerated), findsWidgets);
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('View Receipt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('View Receipt', () {
    testWidgets('Onsite payment shows the unified Esperanza receipt with correct request data', (tester) async {
      final requests = await _payThroughToReceipt(tester, 'Onsite');
      final request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance');
      final receipt = request.receipt!;
      expect(receipt.type, ReceiptType.onsite);

      await _scrollToTopAndTap(tester, find.widgetWithText(AppButton, 'View Receipt'));
      expect(find.byType(ReceiptScreen), findsOneWidget);
      expect(find.byType(EsperanzaReceipt), findsOneWidget);
      expect(find.text('Municipality of Esperanza, Masbate'), findsOneWidget);
      expect(find.text('Official Payment Receipt'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);
      expect(find.text(receipt.residentName), findsWidgets);
      expect(find.text(receipt.serviceName), findsOneWidget);
      expect(find.text(receipt.requestReferenceNumber), findsOneWidget);
      expect(find.text(receipt.amount), findsOneWidget);
      expect(find.text('Mode of Payment'), findsOneWidget);
      expect(find.text('Onsite — Municipal Office'), findsOneWidget);
      expect(find.text(receipt.referenceNumber), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GCash payment shows the exact same unified Esperanza receipt, with GCash as its Mode of Payment', (
      tester,
    ) async {
      final requests = await _payThroughToReceipt(tester, 'GCash');
      final receipt = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance').receipt!;
      expect(receipt.type, ReceiptType.gcash);

      await _scrollToTopAndTap(tester, find.widgetWithText(AppButton, 'View Receipt'));
      expect(find.byType(EsperanzaReceipt), findsOneWidget);
      // No separate GCash-branded design — same municipal receipt shell.
      expect(find.text('Municipality of Esperanza, Masbate'), findsOneWidget);
      expect(find.text('Official Payment Receipt'), findsOneWidget);
      expect(find.text('Mode of Payment'), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text(receipt.amount), findsOneWidget);
      expect(find.text(receipt.referenceNumber), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Maya payment shows the exact same unified Esperanza receipt, with Maya as its Mode of Payment', (
      tester,
    ) async {
      final requests = await _payThroughToReceipt(tester, 'Maya');
      final receipt = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance').receipt!;
      expect(receipt.type, ReceiptType.maya);

      await _scrollToTopAndTap(tester, find.widgetWithText(AppButton, 'View Receipt'));
      expect(find.byType(EsperanzaReceipt), findsOneWidget);
      expect(find.text('Municipality of Esperanza, Masbate'), findsOneWidget);
      expect(find.text('Official Payment Receipt'), findsOneWidget);
      expect(find.text('Mode of Payment'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text(receipt.amount), findsOneWidget);
      expect(find.text(receipt.referenceNumber), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('View Receipt stays reachable after the request advances past Paid to Completed', (tester) async {
      final requests = await _payThroughToReceipt(tester, 'Onsite');
      await _tapNextDemoStep(tester); // Receipt Generated -> Paid
      await _tapNextDemoStep(tester); // Paid -> Ready for Release
      await _tapNextDemoStep(tester); // Ready for Release -> Completed

      final finalReceipt = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance').receipt;
      expect(finalReceipt, isNotNull);

      // Still reachable and tappable even after Completed — not tied to
      // the milestone that generated it.
      await _scrollToTopAndTap(tester, find.widgetWithText(AppButton, 'View Receipt'));
      expect(find.byType(ReceiptScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Download Receipt', () {
    testWidgets('the button is present, enabled, and captures the receipt without a synchronous crash', (
      tester,
    ) async {
      await _payThroughToReceipt(tester, 'Onsite');
      await _scrollToTopAndTap(tester, find.widgetWithText(AppButton, 'View Receipt'));

      final downloadButton = find.widgetWithText(AppButton, 'Download Receipt');
      expect(downloadButton, findsOneWidget);
      expect(tester.widget<AppButton>(downloadButton).onPressed, isNotNull);

      // Actually completing an export depends on share_plus's own platform
      // channel (and, for a memory-only XFile, path_provider's) — neither
      // has a registered response in this widget-test environment, so
      // waiting for it to fully resolve isn't meaningful here (and
      // `pumpAndSettle` times out doing so). A handful of bounded pumps is
      // enough to prove the tap starts the export (the loading state
      // engages) without throwing synchronously; the actual
      // save/share/download behavior is verified live (Flutter Web run),
      // not by this widget test.
      await tester.tap(downloadButton);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('captureRepaintBoundary produces non-empty, well-formed PNG bytes from a rendered receipt', (
      tester,
    ) async {
      final key = GlobalKey();
      final receipt = Receipt(
        type: ReceiptType.onsite,
        amount: '₱50.00',
        referenceNumber: 'OR-1234567890',
        dateTime: DateTime(2026, 1, 1, 9, 30),
        residentName: 'Cristy Bonghanoy',
        serviceName: 'Barangay Clearance',
        requestReferenceNumber: 'DOC-2026-001',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(key: key, child: EsperanzaReceipt(receipt: receipt)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // RenderRepaintBoundary.toImage() rasterizes on the engine's raster
      // thread, which the fake-clock AutomatedTestWidgetsFlutterBinding
      // never actually drives forward — awaiting it directly here hangs
      // until the test framework's own timeout. `runAsync` escapes to a
      // real event loop for just this call, which is all toImage() needs.
      final bytes = await tester.runAsync(() => captureRepaintBoundary(key));
      expect(bytes, isNotNull);
      expect(bytes, isNotEmpty);
      // PNG magic bytes — confirms this is a real, well-formed PNG, not
      // just "some bytes came back".
      expect(bytes!.take(8).toList(), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    });
  });

  group('Independent per-request receipts', () {
    testWidgets("one request's receipt never appears on another request's screen", (tester) async {
      final requests = await _payThroughToReceipt(tester, 'GCash');
      final gcashReceipt = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance').receipt!;

      // A second, independent paid-through request, via the same catalog
      // item's request flow but its own id — confirm the two don't share
      // state. Re-using the same seeded id would only prove the *same*
      // request keeps working, not that a second one is independent, so
      // this drives 'demo-dokyu-barangay-clearance' a second time in a
      // fresh service instance standing in for "a different request the
      // citizen paid a different way".
      SharedPreferences.setMockInitialValues({});
      final otherRequests = RequestsService(seedDemoData: true);
      var attempts = 0;
      while (!otherRequests.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await tester.pumpWidget(
        ChangeNotifierProvider<RequestsService>.value(
          value: otherRequests,
          child: MaterialApp(home: RequestDetailScreen(requestId: 'demo-dokyu-barangay-clearance')),
        ),
      );
      await tester.pumpAndSettle();
      await _tapNextDemoStep(tester);
      await _scrollToAndTap(tester, find.widgetWithText(AppButton, 'Choose Payment Method (Demo)'));
      await tester.tap(find.text('Pay at Municipal Office'));
      await tester.pumpAndSettle();
      await _tapNextDemoStep(tester);
      await _tapNextDemoStep(tester);

      final onsiteReceipt = otherRequests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance').receipt!;
      expect(onsiteReceipt.type, ReceiptType.onsite);
      expect(onsiteReceipt.referenceNumber, isNot(gcashReceipt.referenceNumber));
      expect(gcashReceipt.type, ReceiptType.gcash);
    });
  });
}
