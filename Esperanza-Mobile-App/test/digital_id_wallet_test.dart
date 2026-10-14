// The Unified Digital ID Wallet (GET /citizen/wallet): the Resident ID and
// its QR only while active, suspended or not issued otherwise; identity,
// residency and the Resident ID each with a status of its own; kept IDs as
// "Uploaded — Not checked" with no identity or agency check claimed; and the
// Add ID form, which sends the type and photos but never a status.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/identity_capture.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/wallet_service.dart';
import 'package:esperanza_mobile/widgets/app_text_field.dart';
import 'package:esperanza_mobile/widgets/status_chip.dart';

import 'support/fake_api.dart';
import 'support/wallet_fixture.dart';

Future<List<String>> _pump(WidgetTester tester, Map<String, dynamic> Function() wallet) async {
  // Tall enough that the whole page is built, timeline included.
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final calls = <String>[];
  FakeApi.installFull((r) {
    calls.add('${r.method} ${r.path}');
    if (r.path == '/citizen/wallet') return wallet();
    if (r.method == 'POST' && r.path.endsWith('/archive')) return {'id': 41};
    throw const FakeApiError();
  });
  addTearDown(FakeApi.restore);
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  await tester.runAsync(() async {
    await pumpEventQueue();
    await session.login(MockCatalog.demoAccounts.last);
  });
  await tester.pumpWidget(
    ChangeNotifierProvider<CitizenSessionService>.value(value: session, child: const MaterialApp(home: DigitalIdScreen())),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
  return calls;
}

/// Tap the ID on the deck, then Details in the full-size viewer.
Future<void> _openDetails(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Details'));
  await tester.pumpAndSettle();
}

Finder _row(String title) => find.ancestor(of: find.text(title), matching: find.byType(Column)).first;

void main() {
  group('Resident ID', () {
    testWidgets('identity passed, residency pending: no Resident ID and no QR yet', (tester) async {
      await _pump(tester, () => walletJson(residency: 'Pending Review', state: 'not_issued'));
      expect(find.text('Resident ID not issued yet'), findsOneWidget);
      expect(find.textContaining('Your identity is verified.'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      // On the card and in the timeline.
      expect(find.text('Not issued yet'), findsNWidgets(2));
    });

    testWidgets('identity and residency both approved: the card and its QR', (tester) async {
      await _pump(tester, () => walletJson());
      expect(find.text('Valid · Verified by LGU'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('a failed check never reads as passed', (tester) async {
      await _pump(tester, () => walletJson(identity: 'Failed', residency: 'Pending Review', state: 'not_issued'));
      expect(find.text('Failed'), findsOneWidget);
      expect(find.textContaining('Your identity is not verified yet.'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('identity revoked after approval: suspended, no QR, and why', (tester) async {
      await _pump(tester, () => walletJson(identity: 'Revoked', source: 'lgu_officer', state: 'suspended', suspendedBecause: 'identity_revoked'));
      expect(find.text('Resident ID suspended'), findsOneWidget);
      expect(find.textContaining('withdrew the verification of your identity'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Revoked'), findsOneWidget);
      // Residency stays as the LGU decided it.
      expect(find.widgetWithText(StatusChip, 'Approved'), findsOneWidget);
    });

    testWidgets('residency approval revoked: suspended, identity still verified', (tester) async {
      await _pump(
        tester,
        () => walletJson(residency: 'Rejected', approvalRevoked: true, state: 'suspended', suspendedBecause: 'approval_revoked'),
      );
      expect(find.text('Resident ID suspended'), findsOneWidget);
      expect(find.textContaining('withdrew the approval of your residency, so'), findsOneWidget);
      expect(find.text('The LGU withdrew the approval of your residency.'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });
  });

  testWidgets('identity, residency and the Resident ID each show their own status', (tester) async {
    await _pump(tester, () => walletJson(residency: 'Pending Review', state: 'not_issued', documents: [walletDocumentJson()]));
    expect(find.descendant(of: _row('Identity'), matching: find.text('Verified')), findsOneWidget);
    expect(find.text('Checked by the automated ID and selfie check'), findsOneWidget);
    expect(find.text('Checked ID: Identity Card, ending 1234'), findsOneWidget);
    expect(find.widgetWithText(StatusChip, 'Pending Review'), findsOneWidget);
    expect(find.text('Not issued yet'), findsNWidgets(2));
    // The kept ID's own badge on the deck.
    expect(find.text('Not checked'), findsOneWidget);
  });

  group('My IDs', () {
    testWidgets('a kept ID claims no identity or agency check, and can be removed', (tester) async {
      var removed = false;
      final calls = await _pump(tester, () => walletJson(documents: removed ? const [] : [walletDocumentJson()]));
      expect(find.text('PhilHealth ID'), findsOneWidget);
      expect(find.text('Not checked'), findsOneWidget);

      await _openDetails(tester, 'PhilHealth ID');
      expect(find.text('Checks on this ID'), findsOneWidget);
      expect(find.text('Uploaded — Not checked'), findsOneWidget);
      expect(find.text('Not checked'), findsOneWidget);
      expect(find.text('Not available'), findsOneWidget);

      removed = true;
      await tester.ensureVisible(find.text('Remove from wallet'));
      await tester.tap(find.text('Remove from wallet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(calls, contains('POST /citizen/papeles/41/archive'));
      expect(find.text('No IDs added yet'), findsOneWidget);
    });

    testWidgets('a photo that will not load is tried again, then offers Tap to try again', (tester) async {
      // flutter_test answers every image request with a 400, like a dropped
      // connection that never recovers.
      await _pump(tester, () => walletJson(documents: [walletDocumentJson()..['front_url'] = 'https://test.invalid/files/front']));
      await _openDetails(tester, 'PhilHealth ID');
      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
          await tester.pump(const Duration(seconds: 2));
        }
      }

      await settle();
      final retry = find.text('This image could not be loaded. Tap to try again.');
      expect(retry, findsOneWidget);
      await tester.tap(retry);
      await tester.pump();
      // Trying again: the message gives way while it does.
      expect(retry, findsNothing);
      await settle();
      expect(retry, findsOneWidget);
    });

    testWidgets('the deck steps through the IDs, and a tapped ID opens full size and flips to its back', (tester) async {
      await _pump(
        tester,
        () => walletJson(
          documents: [
            walletDocumentJson(),
            walletDocumentJson(id: 42, idKind: 'sss', name: 'SSS ID', issuer: 'Social Security System', hasBack: true),
          ],
        ),
      );
      expect(find.text('1 of 2'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Next ID'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next ID'));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2'), findsOneWidget);

      // The SSS ID is in front now: open it, flip it, close it.
      await tester.tap(find.bySemanticsLabel(RegExp(r'^SSS ID, Not checked\. 2 of 2')));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^SSS ID, front\.')));
      await tester.pumpAndSettle();
      expect(find.text('SSS ID · Back'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsNothing);
      expect(find.text('Checks on this ID'), findsNothing);
    });

    testWidgets('an ID verified by the LGU carries the seal on the deck', (tester) async {
      await _pump(tester, () => walletJson(documents: [walletDocumentJson(documentStatus: 'verified_by_lgu')]));
      expect(find.byKey(const ValueKey('verified-seal')), findsOneWidget);
      expect(find.text('Not checked'), findsNothing);
    });

    testWidgets('the card shows what the ID says, and the holder corrects it', (tester) async {
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var number = '12-345678901-2';
      final patches = <Map<String, dynamic>?>[];
      Map<String, dynamic> doc() => walletDocumentJson(
        details: {'id_number': number, 'holder_name': 'Halimbawa Sintetiko', 'birthdate': '1995-01-15', 'sex': 'Female', 'details': <String, dynamic>{}},
      );
      FakeApi.installFull((r) {
        if (r.path == '/citizen/wallet') return walletJson(documents: [doc()]);
        if (r.method == 'PATCH' && r.path == '/citizen/wallet/ids/41') {
          patches.add(r.body);
          number = r.body!['id_number'] as String;
          return doc();
        }
        throw const FakeApiError();
      });
      addTearDown(FakeApi.restore);
      SharedPreferences.setMockInitialValues({});
      final session = CitizenSessionService();
      await tester.runAsync(() async {
        await pumpEventQueue();
        await session.login(MockCatalog.demoAccounts.last);
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<CitizenSessionService>.value(value: session, child: const MaterialApp(home: DigitalIdScreen())),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      // The PhilHealth card: its number labelled as PhilHealth labels it, the name, the birth date.
      expect(find.text('PIN'), findsOneWidget);
      expect(find.text('12-345678901-2'), findsOneWidget);
      expect(find.text('Halimbawa Sintetiko'), findsOneWidget);
      expect(find.text('Jan 15, 1995'), findsOneWidget);
      expect(find.text('Esperanza wallet copy · not an official ID'), findsWidgets);

      await _openDetails(tester, 'PhilHealth ID');
      await tester.ensureVisible(find.text('Edit details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      final field = find.descendant(of: find.widgetWithText(AppTextField, 'ID number (PIN)'), matching: find.byType(TextField));
      await tester.enterText(field, '12-345678901-3');
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(patches.single!['id_number'], '12-345678901-3');
      expect(patches.single!['holder_name'], 'Halimbawa Sintetiko');
      expect(patches.single!.containsKey('status'), isFalse);
      // Back on the wallet, the card shows the correction.
      expect(find.text('12-345678901-3'), findsOneWidget);
    });

    testWidgets('a returned upload says so with the reason, and nothing else changes', (tester) async {
      await _pump(
        tester,
        () => walletJson(documents: [walletDocumentJson(documentStatus: 'returned_by_lgu', lguRemarks: 'The photo is too blurry to read.')]),
      );
      expect(find.text('Returned'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      await _openDetails(tester, 'PhilHealth ID');
      expect(find.text('Reason: The photo is too blurry to read.'), findsOneWidget);
      expect(find.text('Use Replace below to send a clearer photo.'), findsOneWidget);
    });

    testWidgets('an ID verified by the LGU says so, and claims no identity or agency check', (tester) async {
      await _pump(tester, () => walletJson(documents: [walletDocumentJson(documentStatus: 'verified_by_lgu')]));
      await _openDetails(tester, 'PhilHealth ID');
      expect(find.text('Verified by the LGU'), findsOneWidget);
      expect(find.textContaining('It carries the Esperanza seal in your wallet.'), findsOneWidget);
      expect(find.text('Not checked'), findsOneWidget);
      expect(find.text('Not available'), findsOneWidget);
    });
  });

  group('Add ID', () {
    Future<void> pumpForm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final types = walletIdTypes.map((t) => WalletIdType.fromApi(Map<String, dynamic>.from(t))!).toList();
      await tester.pumpWidget(MaterialApp(home: AddWalletIdScreen(types: types)));
      await tester.pumpAndSettle();
    }

    testWidgets('lists every ID type, Other included', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.text('Choose the type of ID'));
      await tester.pumpAndSettle();
      for (final name in ['Philippine National ID (PhilSys)', 'PhilHealth ID', 'SSS ID', 'OWWA ID', "Driver's License", 'Other']) {
        expect(find.text(name), findsWidgets, reason: name);
      }
    });

    testWidgets('Other needs its own name and issuer, and every ID needs a front', (tester) async {
      final sent = <String>[];
      FakeApi.installFull((r) {
        sent.add(r.path);
        return walletDocumentJson();
      });
      addTearDown(FakeApi.restore);
      await pumpForm(tester);

      await tester.tap(find.text('Add to wallet'));
      await tester.pumpAndSettle();
      expect(find.text('Choose the type of ID.'), findsOneWidget);

      await tester.tap(find.text('Choose the type of ID'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to wallet'));
      await tester.pumpAndSettle();
      expect(find.text('Enter the name of the ID.'), findsWidgets);
      expect(find.text('Enter who issued the ID.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Barangay Health Worker ID');
      await tester.enterText(find.byType(TextField).at(1), 'Municipal Health Office');
      await tester.tap(find.text('Add to wallet'));
      await tester.pumpAndSettle();
      expect(find.text('Add a photo of the front of the ID.'), findsOneWidget);
      expect(sent, isEmpty);
    });
  });

  // Owner decisions, 2026-10-14: Didit's check is a mark of its own, never
  // the LGU's seal; the kinds Didit reads are scanned on its screen.
  group('Checked by Didit', () {
    testWidgets('a card Didit checked says so, without the seal', (tester) async {
      await _pump(
        tester,
        () => walletJson(
          documents: [
            walletDocumentJson(
              idKind: 'philippine_national_id',
              name: 'Philippine National ID (PhilSys)',
              documentStatus: 'checked_by_didit',
              checkSource: 'registration',
              numberLast4: '3456',
            ),
          ],
        ),
      );
      expect(find.text('Checked'), findsOneWidget);
      expect(find.byKey(const ValueKey('verified-seal')), findsNothing);
      // A card from a check that kept only the last four shows those.
      expect(find.text('•••• 3456'), findsOneWidget);

      await _openDetails(tester, 'Philippine National ID (PhilSys)');
      expect(find.text('Checked by Didit'), findsOneWidget);
      expect(find.text('Only LGU staff can verify it for the Esperanza seal.'), findsOneWidget);
      expect(find.textContaining('Didit checked this ID when you verified your account'), findsOneWidget);
      expect(find.text('Only the last four digits were kept. Use Edit details to add the full number.'), findsOneWidget);
    });

    Future<Future<bool?>> pushForm(WidgetTester tester, {List<String> diditKinds = const ['philippine_national_id']}) async {
      tester.view.physicalSize = const Size(390, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final types = walletIdTypes.map((t) => WalletIdType.fromApi(Map<String, dynamic>.from(t))!).toList();
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      final pushed = Navigator.of(tester.element(find.byType(SizedBox))).push<bool>(
        MaterialPageRoute(builder: (_) => AddWalletIdScreen(types: types, diditKinds: diditKinds)),
      );
      await tester.pumpAndSettle();
      return pushed;
    }

    Future<void> choose(WidgetTester tester, String name) async {
      await tester.tap(find.text('Choose the type of ID'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    void fakeScan(List<String> calls, Map<String, dynamic> result) {
      FakeApi.installFull((r) {
        calls.add('${r.method} ${r.path}');
        if (r.path == '/citizen/wallet/ids/check') return {'session_id': 'sess-1', 'session_token': 'token-1', 'url': null};
        if (r.path == '/citizen/wallet/ids/check/sess-1/sync') return result;
        throw const FakeApiError();
      });
      addTearDown(FakeApi.restore);
      IdentityCapture.launcher = (token) async {
        calls.add('didit $token');
        return const DiditLaunchResult(DiditLaunchOutcome.completed);
      };
      addTearDown(() => IdentityCapture.launcher = (_) async => const DiditLaunchResult(DiditLaunchOutcome.cancelled));
    }

    testWidgets('a kind Didit reads is scanned on its screen; the card comes from what the server read', (tester) async {
      final calls = <String>[];
      fakeScan(calls, {
        'session_id': 'sess-1',
        'outcome': 'checked',
        'reasons': <String>[],
        'document': walletDocumentJson(
          idKind: 'philippine_national_id',
          name: 'Philippine National ID (PhilSys)',
          documentStatus: 'checked_by_didit',
          checkSource: 'wallet',
        ),
      });
      final pushed = await pushForm(tester);
      await choose(tester, 'Philippine National ID (PhilSys)');

      expect(find.text('Scan with Didit'), findsOneWidget);
      expect(find.text('Front (required)'), findsNothing, reason: 'No photo upload while Didit scans it.');

      await tester.tap(find.text('Scan with Didit'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(calls, ['POST /citizen/wallet/ids/check', 'didit token-1', 'POST /citizen/wallet/ids/check/sess-1/sync']);
      expect(await pushed, isTrue);
      expect(find.text('Added to your wallet, checked by Didit.'), findsOneWidget);
    });

    testWidgets('a declined scan says why in plain words and offers the upload instead', (tester) async {
      fakeScan([], {'session_id': 'sess-1', 'outcome': 'declined', 'reasons': ['SCREEN_CAPTURE_DETECTED'], 'document': null});
      await pushForm(tester);
      await choose(tester, 'Philippine National ID (PhilSys)');
      await tester.tap(find.text('Scan with Didit'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Scan the ID itself, not a photo, screen or photocopy of it.'), findsOneWidget);
      await tester.tap(find.text('Upload photos instead'));
      await tester.pumpAndSettle();
      expect(find.text('Front (required)'), findsOneWidget);
      expect(find.text('Scan with Didit'), findsNothing);
    });

    testWidgets('a kind Didit does not read, or Didit not set up, stays an upload', (tester) async {
      await pushForm(tester);
      await choose(tester, 'PhilHealth ID');
      expect(find.text('Front (required)'), findsOneWidget);
      expect(find.text('Scan with Didit'), findsNothing);
    });

    test('the wallet reads checked_by_didit and the kinds Didit can scan', () {
      final wallet = CitizenWallet.fromApi(
        walletJson(
          diditKinds: ['passport', 'umid'],
          documents: [walletDocumentJson(documentStatus: 'checked_by_didit', checkSource: 'wallet')],
        ),
      );
      expect(wallet.diditKinds, ['passport', 'umid']);
      expect(wallet.documents.single.status, WalletDocumentStatus.checkedByDidit);
      expect(wallet.documents.single.fromDidit, isTrue);
      expect(wallet.documents.single.checkedAt, isNotNull);
    });
  });

  group('WalletService.addId', () {
    late String body;
    setUp(() {
      api = ApiClient(
        baseUrl: 'https://test.invalid',
        httpClient: MockClient((request) async {
          body = request.body;
          return http.Response(
            '{"data": {"id": 7, "id_kind": "philhealth", "name": "PhilHealth ID", "document_status": "uploaded_not_checked"}}',
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
    });
    tearDown(FakeApi.restore);

    test('a listed ID sends its type and photos, never a name, issuer or status', () async {
      final doc = await WalletService.addId(
        idKind: 'philhealth',
        front: (bytes: [1, 2, 3], filename: 'front.jpg'),
        back: (bytes: [4, 5, 6], filename: 'back.jpg'),
        name: 'Something else',
        issuer: 'Someone else',
        replaces: 3,
      );
      expect(doc.status, WalletDocumentStatus.uploadedNotChecked);
      expect(body, contains('name="id_kind"'));
      expect(body, contains('name="front"'));
      expect(body, contains('name="back"'));
      expect(body, contains('name="replaces"'));
      expect(body, isNot(contains('name="name"')));
      expect(body, isNot(contains('name="issuer"')));
      expect(body, isNot(contains('status')));
    });

    test('Other sends the resident\'s own name and issuer, trimmed', () async {
      await WalletService.addId(
        idKind: 'other',
        front: (bytes: [1], filename: 'front.jpg'),
        name: '  Barangay Health Worker ID ',
        issuer: 'Municipal Health Office',
      );
      expect(body, contains('Barangay Health Worker ID\r\n'));
      expect(body, contains('name="issuer"'));
    });
  });
}
