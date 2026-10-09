// Identity checks (Didit) on the phone, kept apart from residency
// (esperanza-backend IdentityVerification, owner rulings 2026-10-09).
//
// The server is faked (test/support/fake_api.dart): these tests prove the app
// reads and shows what the server says, not that any check ran.
//
//  - the six identity statuses are their own closed set, never AppStatus;
//  - a revoked identity makes an APPROVED account Unverified on the phone, as
//    it is on the server - the old status-only rule would have shown Verified;
//  - a failed check says what to fix and offers new photos; a check needing
//    staff offers nothing to do.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/access_level.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/id_verification.dart';
import 'package:esperanza_mobile/models/identity_status.dart';
import 'package:esperanza_mobile/screens/profile/id_verification_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/identity_capture.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';

import 'support/fake_api.dart';

/// The backend's CitizenAccount::IDENTITY_STATUSES, in its order.
const _serverStatuses = ['Pending', 'In Progress', 'Verified', 'Failed', 'Requires Review', 'Revoked'];

Map<String, dynamic> _profile({required String status, String? identity, required String access}) => {
  'account_no': 'ESP-RES-2026-90001',
  'first_name': 'Synthetic',
  'last_name': 'Resident',
  'email': 'synthetic@esperanza-test.invalid',
  'mobile': '',
  'barangay': 'Baras',
  'status': status,
  'identity_status': identity,
  'access_level': access,
  'profile_completeness': 80,
};

Map<String, dynamic> _idView({required String identity, List<String> reasons = const [], String submission = 'Pending Review'}) => {
  'id_types': ['PhilSys National ID'],
  'can_submit': true,
  'submission': {'id_type': 'PhilSys National ID', 'status': submission},
  'identity': {
    'status': identity,
    'reasons': reasons,
    'awaiting_check': identity == 'Pending' || identity == 'In Progress',
  },
};

/// A tall screen, so the whole ID screen (the form sits below the cards) is
/// built: a ListView does not build what is off screen.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);
  tearDown(() => IdentityCapture.launcher = (_) async => const DiditLaunchResult(DiditLaunchOutcome.cancelled));

  test('the identity statuses are the server\'s six, and nothing else parses', () {
    expect([for (final s in IdentityStatus.values) s.label], _serverStatuses);
    for (final label in _serverStatuses) {
      expect(IdentityStatusX.fromLabel(label)?.label, label);
    }
    // Residency words are not identity words.
    expect(IdentityStatusX.fromLabel('Approved'), isNull);
    expect(IdentityStatusX.fromLabel('Pending Review'), isNull);
    expect(IdentityStatusX.fromLabel(null), isNull);
  });

  group('access follows the server', () {
    test('an approved account whose identity was revoked is Unverified, and its identity fields stay locked', () async {
      FakeApi.installFull((r) => _profile(status: 'Approved', identity: 'Revoked', access: 'Unverified'));
      final session = CitizenSessionService();
      await session.refresh();

      expect(session.account!.status, 'Approved', reason: 'residency is untouched by a revocation');
      expect(session.account!.identityStatus, 'Revoked');
      expect(session.accessLevel, AccessLevel.unverified);
      expect(session.identityLocked, isTrue, reason: 'a revoked holder must not retype their name before an officer looks again');
    });

    test('approved with a verified identity is Verified', () async {
      FakeApi.installFull((r) => _profile(status: 'Approved', identity: 'Verified', access: 'Verified'));
      final session = CitizenSessionService();
      await session.refresh();
      expect(session.accessLevel, AccessLevel.verified);
    });

    test('a verified identity alone does not make a pending account Verified', () async {
      FakeApi.installFull((r) => _profile(status: 'Pending Review', identity: 'Verified', access: 'Unverified'));
      final session = CitizenSessionService();
      await session.refresh();
      expect(session.accessLevel, AccessLevel.unverified);
    });

    test('an account cached by an older build still works from its status', () async {
      final session = CitizenSessionService();
      await session.login(MockCatalog.demoAccounts.first);
      final cached = CitizenAccount.fromJson(MockCatalog.demoAccounts.first.toJson()..remove('serverAccessLevel')..remove('identityStatus'));
      expect(cached.serverAccessLevel, isNull);
      expect(cached.identityStatus, isNull);
    });
  });

  group('the ID screen', () {
    test('a failed check lets the resident resend even though the ID record still waits', () {
      final failed = IdVerificationView.fromApi(_idView(identity: 'Failed', reasons: ['FACE_MISMATCH']));
      expect(failed.canSendNew, isTrue);
      expect(failed.identity.reasons, ['FACE_MISMATCH']);
      expect(IdVerificationView.fromApi(_idView(identity: 'Requires Review')).canSendNew, isFalse);
      expect(IdVerificationView.fromApi(_idView(identity: 'Verified')).canSendNew, isFalse);
    });

    testWidgets('a failed check says what to fix and offers new photos', (tester) async {
      _tall(tester);
      FakeApi.installFull((r) => _idView(identity: 'Failed', reasons: ['FACE_MISMATCH', 'SOMETHING_NEW']));
      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: IdVerificationScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('• Your selfie did not match the photo on your ID.'), findsOneWidget);
      expect(find.textContaining('SOMETHING_NEW'), findsNothing, reason: 'an unknown code is not shown raw');
      expect(find.text('Send a New ID'), findsOneWidget);
      expect(find.text('Send for Verification'), findsOneWidget);
    });

    testWidgets('a check needing staff offers nothing to do', (tester) async {
      _tall(tester);
      FakeApi.installFull((r) => _idView(identity: 'Requires Review'));
      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: IdVerificationScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Requires Review'), findsOneWidget);
      expect(find.text('Send for Verification'), findsNothing);
      expect(find.textContaining('LGU staff will review your ID and selfie'), findsWidgets);
    });

    testWidgets('a revoked identity shows the LGU withdrew it and offers new photos', (tester) async {
      _tall(tester);
      FakeApi.installFull((r) => _idView(identity: 'Revoked', submission: 'Accepted'));
      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: IdVerificationScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Revoked'), findsOneWidget);
      expect(find.textContaining('withdrawn the verification of your identity'), findsOneWidget);
      expect(find.text('Send for Verification'), findsOneWidget);
    });

    testWidgets('sending needs a selfie: the face match and liveness check run on it', (tester) async {
      FakeApi.installFull((r) => {
        'id_types': ['PhilSys National ID'],
        'can_submit': true,
        'submission': null,
      });
      _tall(tester);
      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: IdVerificationScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selfie'), findsOneWidget);
      expect(find.text('Selfie (optional)'), findsNothing);
    });
  });

  group("Didit's capture screen (identity_capture = hosted)", () {
    test("the app follows the server's capture mode, and falls back to its own form", () async {
      FakeApi.installFull((r) => {'default_language': 'fil', 'identity_capture': 'hosted'});
      expect(await IdentityCapture.mode(), IdentityCapture.hosted);
      FakeApi.installFull((r) => {'default_language': 'fil', 'identity_capture': 'own'});
      expect(await IdentityCapture.mode(), IdentityCapture.own);
      FakeApi.installFull((r) => throw const FakeApiError(status: 500, code: 'DOWN'));
      expect(await IdentityCapture.mode(), IdentityCapture.own, reason: "offline: the app's own steps work against either server");
    });

    testWidgets('the ID screen opens Didit, then shows the result the SERVER read', (tester) async {
      _tall(tester);
      final calls = <String>[];
      var synced = false;
      FakeApi.installFull((r) {
        calls.add('${r.method} ${r.path}');
        if (r.path == '/citizen/verification/session') return {'session_id': 'sess-9', 'session_token': 'tok-9', 'url': null};
        if (r.path.endsWith('/sync')) synced = true;
        return {
          ..._idView(identity: synced ? 'Verified' : 'Failed', submission: 'Pending Review'),
          'capture': 'hosted',
        };
      });
      String? launchedWith;
      IdentityCapture.launcher = (token) async {
        launchedWith = token;
        // The SDK says "completed" - and that is NOT the result.
        return const DiditLaunchResult(DiditLaunchOutcome.completed);
      };

      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: IdVerificationScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Send for Verification'), findsNothing, reason: 'no ID form: Didit captures it');
      expect(find.text('Start Verification'), findsOneWidget);

      await tester.tap(find.text('Start Verification'));
      await tester.pumpAndSettle();

      expect(launchedWith, 'tok-9');
      expect(calls, containsAllInOrder(['POST /citizen/verification/session', 'POST /citizen/verification/session/sess-9/sync']));
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets("closing Didit's screen early reads nothing and says how to resume", (tester) async {
      _tall(tester);
      final calls = <String>[];
      FakeApi.installFull((r) {
        calls.add(r.path);
        if (r.path == '/citizen/verification/session') return {'session_id': 'sess-10', 'session_token': 'tok-10'};
        return {
          'id_types': ['PhilSys National ID'],
          'can_submit': true,
          'submission': null,
          'identity': {'status': null, 'reasons': [], 'awaiting_check': false},
          'capture': 'hosted',
        };
      });
      IdentityCapture.launcher = (_) async => const DiditLaunchResult(DiditLaunchOutcome.cancelled);

      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: IdVerificationScreen())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Verification'));
      await tester.pumpAndSettle();

      expect(calls.where((p) => p.endsWith('/sync')), isEmpty);
      expect(find.text('Start Verification'), findsOneWidget, reason: 'they can start again');
    });
  });
}
