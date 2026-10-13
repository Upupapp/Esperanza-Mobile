// The sign-in screen as the owner's design sets it (2026-10-12, "Esperanza
// Onboarding Prototype" screen 5), and that the redesign kept every way out of
// it working: Sign In, Forgot password?, Register, Continue as Guest.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/auth/forgot_password_screen.dart';
import 'package:esperanza_mobile/screens/auth/login_screen.dart';
import 'package:esperanza_mobile/screens/auth/register_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';

Future<CitizenSessionService> _pump(WidgetTester tester, {Size size = const Size(390, 844), double textScale = 1}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = CitizenSessionService();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: session,
      child: MaterialApp(
        home: const LoginScreen(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

void main() {
  testWidgets("the design's content: the municipal hall, the wordmark, the form", (tester) async {
    await _pump(tester);

    final photo = tester.widget<Image>(find.byWidgetPredicate((w) => w is Image && w.semanticLabel == 'Esperanza Municipal Hall'));
    expect((photo.image as AssetImage).assetName, signInPhotoAsset);

    for (final text in [
      'Esperanza',
      'CITIZEN PORTAL',
      'Municipality of Esperanza, Masbate',
      'Welcome back',
      'Sign in to manage your requests.',
      'Resident ID, email, or mobile',
      'Password',
      'Forgot password?',
      'Sign In',
      'or',
      'Continue as Guest',
      "Don't have an account?",
      'Register',
    ]) {
      expect(find.text(text), findsOneWidget, reason: '"$text" is missing');
    }
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('the photograph is declared and loads', (tester) async {
    final bytes = await rootBundle.load(signInPhotoAsset);
    expect(bytes.lengthInBytes, greaterThan(0));
  });

  testWidgets('the eye shows and hides the password', (tester) async {
    await _pump(tester);
    bool hidden() => tester.widget<TextField>(find.byType(TextField).last).obscureText;

    expect(hidden(), isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(hidden(), isFalse);
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(hidden(), isTrue);
  });

  testWidgets('an empty sign-in says what is missing', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Please enter your email/resident ID and password.'), findsOneWidget);
  });

  testWidgets('Forgot password? and Register still open their screens', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Register'));
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('Continue as Guest starts a guest session', (tester) async {
    final session = await _pump(tester);
    await tester.ensureVisible(find.text('Continue as Guest'));
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    expect(session.isGuest, isTrue);
  });

  for (final size in const [Size(320, 568), Size(360, 800), Size(390, 844), Size(412, 915)]) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('lays out without overflow at ${size.width.toInt()}x${size.height.toInt()}, text ${scale}x', (tester) async {
        await _pump(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        // Every way out can still be reached.
        for (final text in ['Sign In', 'Continue as Guest', 'Register']) {
          await tester.ensureVisible(find.text(text));
          expect(find.text(text).hitTestable(), findsOneWidget, reason: '"$text" cannot be reached');
        }
      });
    }
  }
}
