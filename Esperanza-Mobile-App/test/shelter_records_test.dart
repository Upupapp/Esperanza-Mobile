// The resident's side of shelter and relief (owner, 2026-10-27, Phase 3):
// their own stays and relief (GET /citizen/sakuna/records), confirming an
// item came, a mistake sent as a support ticket, and a household list kept
// ready with consent while the LGU has it on (esperanza-backend
// CitizenSakunaController). Same endpoints and wording as the website's
// Emergency page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/sakuna/my_shelter_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/notification_feed.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/shelter_records_service.dart';
import 'package:esperanza_mobile/widgets/app_text_field.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _records({bool linked = true, String? answer}) => {
  'enabled': true,
  'linked': linked,
  'stays': linked
      ? [
          {
            'ref': 'EVF-2026-00001',
            'status': 'Processing',
            'center': 'Poblacion Elementary School',
            'checked_in': '2026-10-27T08:00:00+08:00',
            'member_count': 3,
            'members': [
              {'name': 'Liwayway Mirasol', 'relation': 'Head'},
              {'name': 'Datu Mirasol', 'relation': 'Son'},
            ],
          },
          {'status': 'Processing'}, // no ref: skipped, not a failed list
        ]
      : <dynamic>[],
  'relief': linked
      ? [
          {
            'ref': 'REL-2026-00001',
            'operation': 'Round 1',
            'item': 'Family Food Pack',
            'quantity': 2,
            'unit': 'pack',
            'released_at': '2026-10-27T10:00:00+08:00',
            'where': 'Poblacion Elementary School',
            'acknowledgement': answer,
            'can_acknowledge': answer == null,
          },
        ]
      : <dynamic>[],
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  test('records parse defensively: a row without a ref is skipped, an unknown answer is no answer', () {
    final r = ShelterRecords.fromJson({
      ..._records(),
      'relief': [
        {'ref': 'REL-1', 'item': 'Water', 'acknowledgement': 'maybe', 'can_acknowledge': 'yes'},
        {'item': 'No ref'},
      ],
    });
    expect(r.linked, isTrue);
    expect(r.stays.map((s) => s.ref), ['EVF-2026-00001']);
    expect(r.stays.single.members, ['Liwayway Mirasol', 'Datu Mirasol']);
    expect(r.relief.single.acknowledgement, isNull);
    expect(r.relief.single.line, 'Water');
    expect(ReliefItem.fromJson(_records()['relief'][0] as Map<String, dynamic>)!.line, '2 pack Family Food Pack');
  });

  test('confirming, reporting and the household list go to the citizen Sakuna routes', () async {
    final sent = <FakeApiRequest>[];
    FakeApi.installFull((r) {
      sent.add(r);
      if (r.path.endsWith('/acknowledge')) return {..._records()['relief'][0] as Map<String, dynamic>, 'acknowledgement': 'not_received'};
      if (r.path == '/citizen/sakuna/records/report') return {'ticket': 'TKT-2026-0007', 'status': 'Submitted'};
      if (r.path == '/citizen/sakuna/household') return {'enabled': true, 'household': r.body == null ? null : {'barangay': 'Poblacion', 'members': r.body!['members']}};
      throw const FakeApiError();
    });

    final item = await ShelterRecordsService.acknowledge('REL-2026-00001', received: false, note: '  away that day ');
    expect(sent.last.method, 'POST');
    expect(sent.last.path, '/citizen/sakuna/relief/REL-2026-00001/acknowledge');
    expect(sent.last.body, {'received': false, 'note': 'away that day'});
    expect(item!.acknowledgement, 'not_received');

    expect(await ShelterRecordsService.reportMistake('EVF-2026-00001', ' My son is not listed. '), 'TKT-2026-0007');
    expect(sent.last.body, {'ref': 'EVF-2026-00001', 'message': 'My son is not listed.'});

    final saved = await ShelterRecordsService.saveHousehold(
      consent: true,
      barangay: 'Poblacion',
      purok: ' Purok 5 ',
      members: [
        HouseholdPerson(name: 'Liwayway Mirasol', relation: 'Head', sex: 'Female', dob: DateTime(1988, 2, 14)),
        HouseholdPerson(name: '   '),
      ],
    );
    expect(sent.last.method, 'PUT');
    expect(sent.last.body, {
      'consent': true,
      'barangay': 'Poblacion',
      'sitio': null,
      'purok': 'Purok 5',
      'members': [
        {'name': 'Liwayway Mirasol', 'relation': 'Head', 'sex': 'Female', 'dob': '1988-02-14', 'vulnerability': null},
      ],
    });
    expect(saved!.members.single.name, 'Liwayway Mirasol');

    await ShelterRecordsService.withdrawHousehold();
    expect(sent.last.method, 'DELETE');
    expect(sent.last.path, '/citizen/sakuna/household');
  });

  testWidgets('the screen shows the stays and relief, and Received is sent and shown', (tester) async {
    var answered = false;
    final sent = <FakeApiRequest>[];
    FakeApi.installFull((r) {
      sent.add(r);
      if (r.path == '/citizen/sakuna/records') return _records(answer: answered ? 'received' : null);
      if (r.path == '/citizen/sakuna/household') return {'enabled': false, 'household': null};
      if (r.path.endsWith('/acknowledge')) {
        answered = true;
        return {..._records()['relief'][0] as Map<String, dynamic>, 'acknowledgement': 'received', 'can_acknowledge': false};
      }
      throw const FakeApiError();
    });

    await tester.pumpWidget(const MaterialApp(home: MyShelterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Poblacion Elementary School'), findsOneWidget);
    expect(find.text('2 pack Family Food Pack'), findsOneWidget);
    expect(find.text('Did your family receive this?'), findsOneWidget);
    // Off until the LGU's DPO agrees: no household list at all.
    expect(find.text('Household List for Evacuation'), findsNothing);

    await tester.ensureVisible(find.text('Received'));
    await tester.tap(find.text('Received'));
    await tester.pumpAndSettle();

    expect(sent.where((r) => r.method == 'POST').single.body, {'received': true});
    expect(find.text('Did your family receive this?'), findsNothing);
    expect(find.textContaining('You confirmed this was received'), findsOneWidget);
  });

  testWidgets('Not received asks for a note in a sheet that closes cleanly', (tester) async {
    // The sheet's text controller was disposed while the sheet was still
    // closing: a red error screen on the emulator (2026-10-27).
    final sent = <FakeApiRequest>[];
    FakeApi.installFull((r) {
      sent.add(r);
      if (r.path == '/citizen/sakuna/records') return _records();
      if (r.path == '/citizen/sakuna/household') return {'enabled': false, 'household': null};
      if (r.path.endsWith('/acknowledge')) {
        return {..._records()['relief'][0] as Map<String, dynamic>, 'acknowledgement': 'not_received', 'can_acknowledge': false};
      }
      throw const FakeApiError();
    });

    await tester.pumpWidget(const MaterialApp(home: MyShelterScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Not received'));
    await tester.tap(find.text('Not received'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'We were at the clinic.');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(sent.where((r) => r.method == 'POST').single.body, {'received': false, 'note': 'We were at the clinic.'});
  });

  // Every button on the screen does something (owner, 2026-10-28).
  testWidgets('Report a mistake opens a sheet, waits for a message, and sends a ticket', (tester) async {
    final sent = <FakeApiRequest>[];
    FakeApi.installFull((r) {
      sent.add(r);
      if (r.path == '/citizen/sakuna/records') return _records();
      if (r.path == '/citizen/sakuna/household') return {'enabled': false, 'household': null};
      if (r.path == '/citizen/sakuna/records/report') return {'ticket': 'TKT-2026-0007', 'status': 'Submitted'};
      throw const FakeApiError();
    });

    await tester.pumpWidget(const MaterialApp(home: MyShelterScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Report a mistake').first);
    await tester.tap(find.text('Report a mistake').first);
    await tester.pumpAndSettle();

    // Send stays off until there is something to send.
    await tester.tap(find.text('Send'));
    await tester.pump();
    expect(sent.where((r) => r.method == 'POST'), isEmpty);

    await tester.enterText(find.byType(TextField), 'My son is not listed.');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(sent.where((r) => r.method == 'POST').single.body, {'ref': 'EVF-2026-00001', 'message': 'My son is not listed.'});
    expect(find.textContaining('TKT-2026-0007'), findsOneWidget);
  });

  testWidgets('the household list: Prepare, Save only with consent, then Edit and Delete', (tester) async {
    // Tall enough that every control is on screen and really tapped.
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    HouseholdList? kept;
    final sent = <FakeApiRequest>[];
    FakeApi.installFull((r) {
      sent.add(r);
      if (r.path == '/citizen/sakuna/records') return _records(linked: false);
      if (r.path == '/citizen/sakuna/household') {
        if (r.method == 'PUT') {
          return {'enabled': true, 'household': {'barangay': r.body!['barangay'], 'purok': r.body!['purok'], 'members': r.body!['members']}};
        }
        if (r.method == 'DELETE') return {'enabled': true, 'household': null};
        return {'enabled': true, 'household': kept == null ? null : {'barangay': kept.barangay, 'members': [for (final m in kept.members) {'name': m.name}]}};
      }
      throw const FakeApiError();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => CitizenSessionService())],
        child: const MaterialApp(home: MyShelterScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Prepare my household list'));
    await tester.tap(find.text('Prepare my household list'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baras').last);
    await tester.pumpAndSettle();
    final name = find.descendant(of: find.ancestor(of: find.text('Full name'), matching: find.byType(AppTextField)), matching: find.byType(TextField));
    await tester.enterText(name, 'Liwayway Mirasol');
    await tester.pump();

    Future<void> reveal(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
    }

    // Without consent, Save list does nothing.
    final save = find.text('Save list');
    await reveal(save);
    await tester.tap(save);
    await tester.pump();
    expect(sent.where((r) => r.method == 'PUT'), isEmpty);

    // + Add a person adds a second card, and Remove takes it away again.
    await reveal(find.text('+ Add a person'));
    await tester.tap(find.text('+ Add a person'));
    await tester.pumpAndSettle();
    expect(find.text('Remove', skipOffstage: false), findsNWidgets(2));
    await reveal(find.text('Remove').last);
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(find.text('Remove', skipOffstage: false), findsNothing);

    await reveal(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    kept = HouseholdList.fromJson({'barangay': 'Baras', 'members': [{'name': 'Liwayway Mirasol'}]});
    await reveal(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final put = sent.where((r) => r.method == 'PUT').single;
    expect(put.body!['consent'], isTrue);
    expect(put.body!['barangay'], 'Baras');
    expect((put.body!['members'] as List).single['name'], 'Liwayway Mirasol');
    // Back on the screen, the saved list with Edit and Delete.
    expect(find.text('Edit'), findsOneWidget);

    kept = null;
    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last); // the confirmation
    await tester.pumpAndSettle();
    expect(sent.where((r) => r.method == 'DELETE'), hasLength(1));
    expect(find.text('Prepare my household list'), findsOneWidget);
  });

  testWidgets('an account without a registry link is told why it sees nothing', (tester) async {
    FakeApi.installFull((r) => r.path == '/citizen/sakuna/records' ? _records(linked: false) : {'enabled': true, 'household': null});

    await tester.pumpWidget(const MaterialApp(home: MyShelterScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('once your account is linked to the resident registry'), findsOneWidget);
    // On: the resident may prepare a list, which needs their consent.
    expect(find.text('Prepare my household list'), findsOneWidget);
  });

  test('the release notification opens the shelter and relief screen', () {
    final n = ServerNotification(
      id: 9,
      category: 'sakuna',
      title: 'Relief released to your family',
      body: 'b',
      pill: 'Released',
      ref: 'REL-2026-00001',
      link: '/citizen/emergency#my-records',
      unread: true,
      pinned: false,
      at: DateTime(2026, 10, 27),
    );
    expect(serverNotificationDestination(n), isA<MyShelterScreen>());
  });
}
