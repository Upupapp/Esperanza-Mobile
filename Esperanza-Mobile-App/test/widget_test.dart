// Smoke test: the app boots to the citizen login screen when no session
// is stored (SharedPreferences is empty by default in the test harness).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/main.dart';

void main() {
  testWidgets('App boots to the citizen login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const EsperanzaMobileApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsNothing); // AppButton isn't a Material ElevatedButton
    expect(find.text('Sign In'), findsOneWidget);
  });
}
