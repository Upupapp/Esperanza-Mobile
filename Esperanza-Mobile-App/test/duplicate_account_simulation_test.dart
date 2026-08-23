// Functional coverage for Phase 6 — the "One Person, One Account"
// duplicate-account demo. FRONTEND SIMULATION ONLY: no real identity
// matching happens; the duplicate is preconfigured demo data. Verifies the
// demo login button, both scenario alerts on the real Cristy account
// (repeatable — one resolved "Yes", the other "No", without resetting the
// app), and the duplicate account's own read-only status notification.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _dismissWelcomeBanner(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close_rounded);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

Future<void> _openBell(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.notifications_outlined).first);
  await tester.pumpAndSettle();
}

/// NotificationsScreen is a lazily-built ListView.builder — a target
/// further down the (growing) feed may not be mounted yet at the initial
/// scroll position, so scroll it into view before asserting/tapping.
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sign In screen offers a clearly labeled duplicate-Cristy demo login, distinct from the real account', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    expect(find.text('Cristy Bonghanoy'), findsOneWidget); // the real account's own card
    expect(find.text('Demo: Duplicate Cristy Account'), findsOneWidget);
    // Never the same identifiers as the real account.
    expect(MockCatalog.duplicateCristyAccount.id, isNot(MockCatalog.demoAccounts.last.id));
    expect(MockCatalog.duplicateCristyAccount.email, isNot(MockCatalog.demoAccounts.last.email));
  });

  testWidgets('Logging in as the duplicate never grants Verified access, and shows the under-review warning', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Demo: Duplicate Cristy Account'));
    await tester.tap(find.text('Demo: Duplicate Cristy Account'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await _dismissWelcomeBanner(tester);

    expect(MockCatalog.duplicateCristyAccount.status, isNot('Approved'));

    await _openBell(tester);
    await tester.scrollUntilVisible(
      find.text('Duplicate Account Under Review'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Duplicate Account Under Review'), findsOneWidget);
    expect(
      find.textContaining('Verification is temporarily restricted while the account is reviewed'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Real Cristy receives both duplicate-alert scenarios; resolving A as "Yes" and B as "No" works independently, repeatably',
    (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
      _setPhoneViewport(tester);
      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cristy Bonghanoy'));
      await tester.tap(find.text('Cristy Bonghanoy'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await _dismissWelcomeBanner(tester);

      await _openBell(tester);
      await tester.scrollUntilVisible(
        find.text('Possible Duplicate Account Detected').first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Possible Duplicate Account Detected'), findsNWidgets(2)); // scenario A + B, both unresolved

      // --- Scenario A: "Yes, this is me" ---
      await _scrollToAndTap(tester, find.text('Possible Duplicate Account Detected').first);
      expect(find.text('Duplicate Account Detected'), findsOneWidget); // details screen header
      expect(find.text('Yes, this is me'), findsOneWidget);
      expect(find.text('No, this is not me'), findsOneWidget);

      await tester.tap(find.text('Yes, this is me'));
      await tester.pumpAndSettle();
      expect(find.text('Duplicate Account Confirmed'), findsOneWidget);
      // Exact match, not a substring — the resolved card behind the dialog
      // (resolution is recorded before the dialog opens) independently
      // contains an overlapping "cannot be upgraded to Verified status" phrase.
      expect(
        find.text(
          'Thank you for confirming that the other account also belongs to you. You may still access the account, '
          'but it cannot be upgraded to Verified status because Esperanza follows a one-person, '
          'one-verified-account policy. Please continue using your existing verified account for Dokyu, Tulong, '
          'and other verified resident services.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      // Back on the details screen — now shows the resolved outcome, not
      // the Yes/No choice again.
      expect(find.text('Yes, this is me'), findsNothing);
      expect(find.textContaining('Duplicate Stays Unverified'), findsOneWidget);
      Navigator.of(tester.element(find.text('Duplicate Account Details'))).pop();
      await tester.pumpAndSettle();

      // --- Scenario B: "No, this is not me" — still available, independent of A ---
      await tester.scrollUntilVisible(
        find.text('Possible Duplicate Account Detected'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Possible Duplicate Account Detected'), findsOneWidget); // only B still unresolved
      await _scrollToAndTap(tester, find.text('Possible Duplicate Account Detected'));
      await tester.tap(find.text('No, this is not me'));
      await tester.pumpAndSettle();
      expect(find.text('Report Submitted'), findsOneWidget);
      // The dialog's own message — not a substring match, since the
      // resolved card behind it (already rebuilt, resolution is recorded
      // before the dialog opens) independently contains overlapping text.
      expect(
        find.text('Thank you for confirming. The duplicate account has been flagged for administrative investigation.'),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Flagged for Investigation'), findsOneWidget);

      // Neither scenario silently changed the real Cristy's own account.
      final realCristy = MockCatalog.demoAccounts.last;
      expect(realCristy.status, 'Approved');

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Duplicate account tapping Dokyu via the "+" launcher gets the dedicated verified-account popup, '
    'and "Go to My Verified Account" switches the session and lands on Home',
    (tester) async {
      SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
      _setPhoneViewport(tester);
      await tester.pumpWidget(const EsperanzaMobileApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Demo: Duplicate Cristy Account'));
      await tester.tap(find.text('Demo: Duplicate Cristy Account'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await _dismissWelcomeBanner(tester);

      await tester.tap(find.byKey(const ValueKey('nav-center-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dokyu'));
      await tester.pumpAndSettle();

      // Not the generic AccessGuard/RestrictedFeatureNotice message — the
      // dedicated duplicate-account popup instead.
      expect(find.text('Use Your Verified Account'), findsOneWidget);
      expect(find.textContaining('Dokyu and Tulong are only available'), findsOneWidget);

      await tester.tap(find.text('Go to My Verified Account'));
      await tester.pumpAndSettle();

      expect(find.text('Switched to your verified Esperanza account.'), findsOneWidget);
      // Landed on Home, not straight into Dokyu — the signed-in hero
      // greeting is visible without scrolling and only renders for a
      // real (non-guest) account, confirming both "on Home" and "signed
      // in as the real Cristy now".
      expect(find.textContaining('Magandang araw, Cristy'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Duplicate account: "Not Now" on the verified-account popup leaves the session and screen unchanged', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'esperanza_onboarding_complete': true});
    _setPhoneViewport(tester);
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Demo: Duplicate Cristy Account'));
    await tester.tap(find.text('Demo: Duplicate Cristy Account'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await _dismissWelcomeBanner(tester);

    await tester.tap(find.byKey(const ValueKey('nav-center-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tulong'));
    await tester.pumpAndSettle();

    expect(find.text('Use Your Verified Account'), findsOneWidget);
    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();

    expect(find.text('Use Your Verified Account'), findsNothing);
    expect(find.text('Switched to your verified Esperanza account.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
