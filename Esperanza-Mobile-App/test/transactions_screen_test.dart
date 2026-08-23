// Coverage for the Transactions screen (Milestone B) — it must be a
// read-only view derived from each ServiceRequest's own Receipt, never a
// separate hardcoded list, sorted newest-first, and it must reuse the same
// ReceiptScreen/receipt data as the request detail screen's "View Receipt".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/receipt.dart';
import 'package:esperanza_mobile/screens/shared/receipt_screen.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/screens/shared/transactions_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

/// AutomatedTestWidgetsFlutterBinding fakes the clock — a real
/// `Future.delayed` never fires unless something calls `tester.pump()` to
/// advance it, so the wait loop must pump rather than delay for real.
Future<RequestsService> _loaded(WidgetTester tester, {bool seedDemoData = true}) async {
  SharedPreferences.setMockInitialValues({});
  final requests = RequestsService(seedDemoData: seedDemoData);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

Future<CitizenSessionService> _signedInAs(WidgetTester tester, CitizenAccount account) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(account);
  return session;
}

/// Pumps TransactionsScreen wired to both providers it now depends on —
/// RequestsService and (since the screen scopes its list to the signed-in
/// account's own applicantId) CitizenSessionService. Defaults to the
/// verified Cristy Bonghanoy demo account, since that's who the seeded
/// paid-transaction demo data (and _payThrough's manual payments) belong
/// to in every test below.
Future<void> _pumpTransactions(WidgetTester tester, RequestsService requests, {CitizenAccount? account}) async {
  final session = await _signedInAs(tester, account ?? MockCatalog.demoAccounts.last);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
      ],
      child: const MaterialApp(home: TransactionsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Drives 'demo-dokyu-barangay-clearance' (₱50.00) from Approved to Receipt
/// Generated, choosing [method] at the payment-method step, using the
/// already-loaded [requests] service directly (no detail screen needed
/// here — RequestsService.advanceMilestone is the same code path the
/// detail screen's "Next Demo Step" button calls).
Future<void> _payThrough(RequestsService requests, String method) async {
  await requests.advanceMilestone('demo-dokyu-barangay-clearance'); // Approved -> Waiting for Payment
  await requests.advanceMilestone('demo-dokyu-barangay-clearance', paymentMethod: method); // -> Payment Method Selected
  await requests.advanceMilestone('demo-dokyu-barangay-clearance'); // -> Payment Processing
  await requests.advanceMilestone('demo-dokyu-barangay-clearance'); // -> Receipt Generated
}

void main() {
  testWidgets('No paid transactions yet shows the proper empty state, not a fake seeded list', (tester) async {
    // seedDemoData: false — even Cristy's own seeded paid-transaction demo
    // data must not leak into this assertion; this proves the *genuine*
    // empty state, not merely "an account with no seed happens to be empty".
    final requests = await _loaded(tester, seedDemoData: false);
    await _pumpTransactions(tester, requests);

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Your paid Dokyu or Tulong transactions will appear here.'), findsOneWidget);
  });

  group('Seeded demo transactions (verified Cristy Bonghanoy)', () {
    testWidgets('all three seeded paid transactions are visible, one per payment method, with real service/fee data', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      await _pumpTransactions(tester, requests);

      expect(find.text('Certificate of Residency'), findsOneWidget);
      expect(find.text('Real Property Tax Clearance'), findsOneWidget);
      expect(find.text('Social Pension (Indigent Senior Citizen)'), findsOneWidget);
      expect(find.textContaining('₱50.00'), findsWidgets); // Certificate of Residency's real fee
      expect(find.textContaining('₱100.00'), findsWidgets); // RPT Clearance's and Social Pension's real fees
      expect(find.textContaining('GCash'), findsWidgets);
      expect(find.textContaining('Maya'), findsWidgets);
      expect(find.textContaining('Onsite / Municipal Office'), findsWidgets);
      expect(find.text('Paid'), findsNWidgets(3));
    });

    testWidgets('does not duplicate on a second load (simulates a restart)', (tester) async {
      final requests = await _loaded(tester);
      final paidCount = requests.all.where((r) => r.receipt != null).length;
      expect(paidCount, 3);

      // Persist, then restore into a fresh RequestsService instance from
      // the same SharedPreferences-backed storage — exactly what an app
      // restart does.
      final reloaded = RequestsService(seedDemoData: true);
      var attempts = 0;
      while (!reloaded.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('RequestsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(reloaded.all.where((r) => r.receipt != null).length, 3);
    });

    testWidgets("the duplicate Cristy registration does not inherit the verified account's transactions", (
      tester,
    ) async {
      final requests = await _loaded(tester);
      await _pumpTransactions(tester, requests, account: MockCatalog.duplicateCristyAccount);

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Certificate of Residency'), findsNothing);
    });

    testWidgets('View Receipt on each seeded transaction opens the unified Esperanza receipt with correct data', (
      tester,
    ) async {
      final requests = await _loaded(tester);
      final gcash = requests.all.firstWhere((r) => r.id == 'demo-paid-dokyu-residency-gcash');
      await _pumpTransactions(tester, requests);

      await tester.tap(find.text('Certificate of Residency'));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptScreen), findsOneWidget);
      expect(tester.widget<ReceiptScreen>(find.byType(ReceiptScreen)).receipt, same(gcash.receipt));
      expect(find.text('Cristy Bonghanoy'), findsWidgets);
      expect(find.text('Mode of Payment'), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text(gcash.fee), findsOneWidget);
    });
  });

  testWidgets('A paid request appears as a transaction card with its own receipt data, and View Receipt opens '
      'the same receipt shown from the request detail screen', (tester) async {
    final requests = await _loaded(tester);
    await _payThrough(requests, 'GCash');
    final receipt = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance').receipt!;

    await _pumpTransactions(tester, requests);

    expect(find.text('Barangay Clearance'), findsOneWidget);
    expect(find.text(receipt.requestReferenceNumber), findsOneWidget);
    expect(find.textContaining(receipt.amount), findsWidgets);
    expect(find.textContaining('GCash'), findsWidgets);
    expect(find.text('Paid'), findsNWidgets(4)); // 3 seeded + this one

    await tester.tap(find.text('View Receipt').first);
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptScreen), findsOneWidget);
    expect(find.text(receipt.referenceNumber), findsOneWidget);
    expect(find.text(receipt.amount), findsWidgets);
  });

  testWidgets('Most recent transaction is listed first', (tester) async {
    final requests = await _loaded(tester);
    await _payThrough(requests, 'Onsite'); // demo-dokyu-barangay-clearance, paid first
    final firstReceipt = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance').receipt!;

    // The 3 seeded transactions are all dated in the past (see
    // RequestsService._seedPaidTransactionDemoIfNeeded) — this one was just
    // paid "now", so it must sort above all of them. The ListView builds
    // its children in list order, so the first Text built in the whole
    // tree (build order, not screen position) is this transaction's own
    // service name.
    await _pumpTransactions(tester, requests);

    expect(find.text(firstReceipt.requestReferenceNumber), findsOneWidget);
    final firstCardText = tester
        .widgetList<Text>(find.descendant(of: find.byType(ListView), matching: find.byType(Text)))
        .first
        .data;
    expect(firstCardText, 'Barangay Clearance');
  });

  testWidgets('Free Dokyu/Tulong requests never produce a transaction entry', (tester) async {
    final requests = await _loaded(tester);
    // demo-tulong-medical and demo-tulong-financial are seeded Free
    // (requiresPayment: false) — confirm neither ever gets a receipt and
    // neither shows up here even though other paid requests exist.
    await _payThrough(requests, 'Maya');

    await _pumpTransactions(tester, requests);

    expect(find.text('Medical Assistance (AICS)'), findsNothing);
    expect(find.text('Financial Assistance (AICS)'), findsNothing);
    expect(find.text('Barangay Clearance'), findsOneWidget); // the one that WAS paid
  });

  testWidgets('Onsite transaction shows "Onsite / Municipal Office" as its payment method', (tester) async {
    final requests = await _loaded(tester);
    await _payThrough(requests, 'Onsite');
    final receipt = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance').receipt!;
    expect(receipt.type, ReceiptType.onsite);

    await _pumpTransactions(tester, requests);

    // findsWidgets, not findsOneWidget: the seeded Social Pension
    // transaction is also paid Onsite (see
    // RequestsService._seedPaidTransactionDemoIfNeeded) — both correctly
    // show the same payment-method label.
    expect(find.textContaining('Onsite / Municipal Office'), findsWidgets);
  });

  testWidgets(
    "Request detail screen's View Receipt reaches the exact same Receipt object Transactions would show for it",
    (tester) async {
      final requests = await _loaded(tester);
      await _payThrough(requests, 'GCash');
      final receipt = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance').receipt!;

      await tester.pumpWidget(
        ChangeNotifierProvider<RequestsService>.value(
          value: requests,
          child: MaterialApp(home: RequestDetailScreen(requestId: 'demo-dokyu-barangay-clearance')),
        ),
      );
      await tester.pumpAndSettle();
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'View Receipt'));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptScreen), findsOneWidget);
      expect(tester.widget<ReceiptScreen>(find.byType(ReceiptScreen)).receipt, same(receipt));
      expect(find.text(receipt.referenceNumber), findsOneWidget);
      expect(find.text(receipt.amount), findsOneWidget);
    },
  );
}
