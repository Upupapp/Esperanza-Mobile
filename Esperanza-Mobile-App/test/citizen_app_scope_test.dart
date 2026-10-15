// The citizen app's remaining scope (owner decisions, 2026-10-15): where and
// how to claim a ready request, the issued document with its verification QR
// and the scan of the signed paper, the encrypted sign-in token, and the
// offline copy of requests. Synthetic data.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/request_release.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/widgets/request_release_cards.dart';

import 'support/fake_api.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeKeystore implements SecureTokenStore {
  final values = <String, String>{};
  bool broken = false;

  @override
  Future<String?> read(String key) async => broken ? throw Exception('keystore') : values[key];
  @override
  Future<void> write(String key, String value) async => broken ? throw Exception('keystore') : values[key] = value;
  @override
  Future<void> delete(String key) async => broken ? throw Exception('keystore') : values.remove(key);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Ready to claim', () {
    test('reads the server\'s pickup details', () {
      final p = RequestPickup.fromApi({
        'office': 'Office of the Punong Barangay',
        'office_contact': '0917 000 0000',
        'office_hours': 'Mon-Fri, 8:00 AM - 5:00 PM',
        'ready_since': '2026-10-14T07:00:00Z',
        'fee_due': 50,
        'bring': ['valid_id', 'reference_number', 'fee'],
      })!;
      expect(p.feeDue, 50);
      expect(p.bring, ['valid_id', 'reference_number', 'fee']);
      expect(RequestPickup.fromApi(null), isNull);
    });

    testWidgets('says where to go, the hours, and what to bring, fee included', (tester) async {
      await _pump(
        tester,
        PickupCard(
          pickup: RequestPickup.fromApi({
            'office': 'Office of the Punong Barangay',
            'office_contact': '0917 000 0000',
            'office_hours': 'Mon-Fri, 8:00 AM - 5:00 PM',
            'fee_due': 50,
            'bring': ['valid_id', 'reference_number', 'fee'],
          })!,
          reference: 'DOK-2026-000123',
          accent: AppColors.brand700,
        ),
      );
      expect(find.text('Ready to claim'), findsOneWidget);
      expect(find.text('Office of the Punong Barangay'), findsOneWidget);
      expect(find.text('Mon-Fri, 8:00 AM - 5:00 PM'), findsOneWidget);
      expect(find.text('A valid ID'), findsOneWidget);
      expect(find.text('Your reference number, DOK-2026-000123'), findsOneWidget);
      expect(find.textContaining('The fee of ₱50'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Call 0917 000 0000')), findsOneWidget);
    });
  });

  group('Issued document', () {
    Map<String, dynamic> doc({
      bool revoked = false,
      String? scan = 'https://example.invalid/files/scan.pdf?signature=x',
    }) => {
      'control_number': 'BC-2026-000042',
      'serial': 'ABCD-EFGH',
      'verify_url': 'https://example.invalid/verify/?code=abcdefgh',
      'issued_on': '2026-10-14',
      'valid_until': '2027-04-14',
      'expired': false,
      'revoked': revoked,
      'revoked_reason': revoked ? 'Issued with the wrong purpose.' : null,
      'has_scan': scan != null || revoked,
      'scan_url': revoked ? null : scan,
    };

    testWidgets('a valid one shows its number, dates, the verification QR and the signed copy', (tester) async {
      await _pump(
        tester,
        IssuedDocumentsCard(documents: [IssuedDocumentInfo.fromApi(doc())!], accent: AppColors.brand700),
      );
      expect(find.text('BC-2026-000042'), findsOneWidget);
      expect(find.text('Valid'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('View signed copy'), findsOneWidget);
      expect(find.text('Check online'), findsOneWidget);
    });

    testWidgets('before the scan is attached, the paper is said to be the official copy', (tester) async {
      await _pump(
        tester,
        IssuedDocumentsCard(documents: [IssuedDocumentInfo.fromApi(doc(scan: null))!], accent: AppColors.brand700),
      );
      expect(find.text('View signed copy'), findsNothing);
      expect(find.textContaining('The paper copy you claim is the official document.'), findsOneWidget);
    });

    testWidgets('a revoked one says so and why, with no QR or copy to hand out', (tester) async {
      await _pump(
        tester,
        IssuedDocumentsCard(documents: [IssuedDocumentInfo.fromApi(doc(revoked: true))!], accent: AppColors.brand700),
      );
      expect(find.text('Revoked'), findsOneWidget);
      expect(find.textContaining('Issued with the wrong purpose.'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('View signed copy'), findsNothing);
      expect(find.text('Check online'), findsNothing);
    });
  });

  group('Secure sign-in', () {
    late _FakeKeystore keystore;
    setUp(() => ApiClient.secureStore = keystore = _FakeKeystore());
    tearDown(() => ApiClient.secureStore = null);

    test("the token is kept in the phone's secure store, never in plain storage", () async {
      await ApiClient().setToken('t0k3n-synthetic');
      expect(keystore.values['esperanza_api_token'], 't0k3n-synthetic');
      expect((await SharedPreferences.getInstance()).getString('esperanza_api_token'), isNull);
      expect(await ApiClient().getToken(), 't0k3n-synthetic', reason: 'A fresh launch reads it back.');

      await ApiClient().setToken(null);
      expect(keystore.values, isEmpty);
    });

    test('a token an older version kept in plain storage moves across once, without signing out', () async {
      SharedPreferences.setMockInitialValues({'esperanza_api_token': 'older-t0k3n'});
      expect(await ApiClient().getToken(), 'older-t0k3n');
      expect(keystore.values['esperanza_api_token'], 'older-t0k3n');
      expect((await SharedPreferences.getInstance()).getString('esperanza_api_token'), isNull);
    });

    test('a broken secure store falls back rather than signing the resident out', () async {
      keystore.broken = true;
      await ApiClient().setToken('t0k3n-synthetic');
      expect(await ApiClient().getToken(), 't0k3n-synthetic');
    });
  });

  group('Offline copy', () {
    final row = {
      'ref': 'DOK-2026-000123',
      'type': 'dokyu',
      'service': 'Barangay Clearance',
      'status': 'Processing',
      'submitted': '2026-10-14T01:00:00Z',
    };
    var down = false;
    setUp(() {
      down = false;
      FakeApi.installFull((r) {
        if (down) throw const FakeApiError(status: 503, code: 'UNAVAILABLE', messageEn: 'Unavailable');
        return r.path == '/citizen/requests' ? [row] : <dynamic>[];
      });
    });
    tearDown(FakeApi.restore);

    test('without a connection the last list is shown, marked with when it was saved', () async {
      final service = RequestsService();
      addTearDown(service.dispose);
      await service.loadRequests();
      expect(service.requestsSavedAt, isNull);
      await Future<void>.delayed(Duration.zero);

      down = true;
      final offline = RequestsService();
      addTearDown(offline.dispose);
      await offline.loadRequests();
      expect(offline.all.single.referenceNumber, 'DOK-2026-000123');
      expect(offline.all.single.status, 'Processing');
      expect(offline.requestsSavedAt, isNotNull);

      down = false;
      await offline.loadRequests();
      expect(offline.requestsSavedAt, isNull, reason: 'Live again once the server answers.');
    });

    test('signing out erases the copy, so the next person sees nothing of it', () async {
      final service = RequestsService();
      addTearDown(service.dispose);
      await service.loadRequests();
      await Future<void>.delayed(Duration.zero);
      service.clear();
      await Future<void>.delayed(Duration.zero);

      down = true;
      await expectLater(service.loadRequests(), throwsA(isA<ApiException>()));
      expect(service.all, isEmpty);
    });

    test('a refusal is not hidden behind the copy', () async {
      final service = RequestsService();
      addTearDown(service.dispose);
      await service.loadRequests();
      await Future<void>.delayed(Duration.zero);
      FakeApi.installFull((r) => throw const FakeApiError(status: 403, code: 'FORBIDDEN', messageEn: 'No.'));
      await expectLater(service.loadRequests(), throwsA(isA<ApiException>()));
    });
  });
}
