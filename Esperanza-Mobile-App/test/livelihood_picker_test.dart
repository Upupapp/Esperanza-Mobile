// The occupation as the two DRRM dropdowns (owner, 2026-10-28/29): the list
// comes from the server (GET /livelihood-classes), the same one the website
// uses; a choice is a code, and "Others, specify" needs the words.
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/resident_profile.dart';
import 'package:esperanza_mobile/services/livelihood_service.dart';
import 'package:esperanza_mobile/widgets/livelihood_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

List<Map<String, dynamic>> _list() => [
      {
        'code': 'B',
        'label': 'Informal Employment',
        'items': [
          {'code': 'B-2', 'label': 'Vendor / Marketseller', 'heading_code': null, 'heading': null, 'other': false},
          {'code': 'B-3-1', 'label': 'Tricycle Driver', 'heading_code': 'B-3', 'heading': 'Transport Worker', 'other': false},
          {'code': 'B-3-5', 'label': 'Others', 'heading_code': 'B-3', 'heading': 'Transport Worker', 'other': true},
          {'label': 'no code: skipped, not fatal'},
        ],
      },
      {
        'code': 'C',
        'label': 'Agriculture, Fisheries and Natural Resources',
        'items': [
          {'code': 'C-1', 'label': 'Farmer / Farm Laborer', 'heading_code': null, 'heading': null, 'other': false},
        ],
      },
    ];

/// The list request completes on the real clock; the loading bar would never
/// let pumpAndSettle finish while it waits.
Future<void> _loaded(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

void main() {
  setUp(() {
    LivelihoodService.reset();
    FakeApi.install((path, query) => path == '/livelihood-classes' ? _list() : <dynamic>[]);
  });
  tearDown(FakeApi.restore);

  test('the list is read from the server, a malformed row skipped', () async {
    final groups = await LivelihoodService.load();
    expect(groups.map((g) => g.code), ['B', 'C']);
    expect(groups.first.items.map((i) => i.code), ['B-2', 'B-3-1', 'B-3-5']);
    expect(LivelihoodService.item('B-3-1')!.fullLabel, 'Transport Worker › Tricycle Driver');
    expect(LivelihoodService.item('B-3-5')!.isOther, isTrue);
  });

  testWidgets('choosing a group, then an item; Others asks for the words', (tester) async {
    String code = '';
    String other = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LivelihoodPicker(code: '', other: '', previousText: 'tricycle', onChanged: (c, o) => (code = c, other = o)),
        ),
      ),
    ));
    await _loaded(tester);
    expect(find.textContaining('Recorded before as:'), findsOneWidget, reason: 'the old words are shown until a choice is made');

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('B · Informal Employment').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transport Worker › Others').last);
    await tester.pumpAndSettle();
    expect(code, 'B-3-5');
    expect(find.text('Specify the occupation'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Bangkero');
    await tester.pump();
    expect((code, other), ('B-3-5', 'Bangkero'));
    expect(find.textContaining('Recorded before as:'), findsNothing);
  });

  testWidgets('a list that cannot load leaves the occupation alone and offers a retry', (tester) async {
    FakeApi.install((path, query) => throw const FakeApiError(status: 503, code: 'UNAVAILABLE'));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LivelihoodPicker(code: 'C-1', other: '', onChanged: (_, _) {}))));
    await _loaded(tester);
    expect(find.text('The occupation list could not load. Try again later.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  test('the classification travels with the account and the profile record', () {
    final account = CitizenAccount.fromJson({
      'id': 'ESP-RES-2026-000001', 'firstName': 'Synthetic', 'lastName': 'Resident', 'email': '', 'mobile': '',
      'barangay': 'Poblacion', 'purok': '', 'address': '', 'birthdate': '', 'sex': '', 'civilStatus': '',
      'occupation': 'Tricycle Driver', 'profileCompleteness': 0, 'status': 'Approved',
      'livelihood': {'code': 'B-3-1', 'full_label': 'Transport Worker › Tricycle Driver', 'other': null, 'status': 'classified'},
    });
    expect(account.livelihood!.isClassified, isTrue);
    expect(CitizenAccount.fromJson(account.toJson()).livelihood!.code, 'B-3-1');

    final member = Individual(individualId: 'IND-1', firstName: 'Synthetic', livelihoodCode: 'B-3-5', livelihoodOther: 'Bangkero', livelihoodChanged: true);
    final again = Individual.fromJson(member.toJson());
    expect((again.livelihoodCode, again.livelihoodOther, again.livelihoodChanged), ('B-3-5', 'Bangkero', true));
  });
}
