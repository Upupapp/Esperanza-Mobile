// Citizens bug hunt, 25 Nov 2026 - the app's side (#6, #8, #29).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/models/resident_profile.dart';
import 'package:esperanza_mobile/theme/app_status.dart';
import 'package:esperanza_mobile/widgets/verification_status_panel.dart';

Future<void> _pump(WidgetTester tester, Widget panel) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: panel))),
    );

void main() {
  testWidgets('#6 an approved resident whose ID check was revoked is told requests are paused, not "full access"', (tester) async {
    await _pump(
      tester,
      VerificationStatusPanel(status: AppStatus.approved, identityRevoked: true, onAction: () {}),
    );
    expect(find.textContaining('revoked your ID check'), findsOneWidget);
    expect(find.textContaining('full access'), findsNothing);
    expect(find.text('Send a New ID'), findsOneWidget);
  });

  testWidgets('#6 a rejected account is told to send a new ID, not to wait', (tester) async {
    await _pump(tester, VerificationStatusPanel(status: AppStatus.rejected, onAction: () {}));
    expect(find.text('Send a new valid ID from your profile, or visit your barangay office.'), findsOneWidget);
  });

  testWidgets('#6 an approved resident with a verified ID still reads full access', (tester) async {
    await _pump(tester, const VerificationStatusPanel(status: AppStatus.approved));
    expect(find.textContaining('full access'), findsOneWidget);
  });

  test('#29 the registry civil statuses are choices, as on the website', () {
    for (final s in ['Single', 'Married', 'Live-in', 'Widowed', 'Separated', 'Annulled', 'Divorced']) {
      expect(ResidentProfileOptions.civilStatus, contains(s));
    }
  });

  test('#8 a saved family member has no Remove: the barangay removes them', () {
    final src = File('lib/screens/profile/resident_profile/family_information_screen.dart').readAsStringSync();
    expect(src, contains('onRemove: member.serverRef == null ? () => _removeMember(member) : null'));
    expect(src, contains("tr('To remove, ask your barangay')"));
  });
}
