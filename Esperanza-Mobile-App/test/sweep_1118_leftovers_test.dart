// QA sweep 2026-11-18, the fixers' leftovers: sign-out erases what open
// screens brought back while the server was being told (140, 143); the
// resident profile pages survive the session ending (139); the drawer's
// avatar never shows a photo the LGU has not approved (141); the bottom
// nav and the launcher's Dokyu/Tulong answer a screen reader's double-tap
// (148); a family member's unknown education and contact are not erased
// (45); a Submit with no answer never takes an older request as filed
// (135, 138); a refused booking names its field (178). Synthetic
// identities only.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/resident_profile.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/family_information_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/resident_profile_overview_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/review_submit_screen.dart';
import 'package:esperanza_mobile/screens/shared/new_request_screen.dart' show FiledRequestCheck;
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/appointments_service.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/services/sign_out.dart';
import 'package:esperanza_mobile/widgets/esperanza_drawer.dart';
import 'package:esperanza_mobile/widgets/esperanza_nav_item.dart';
import 'package:esperanza_mobile/widgets/nav_item_data.dart';
import 'package:esperanza_mobile/widgets/service_launcher_menu.dart';

import 'support/fake_api.dart';

/// A real 1x1 PNG, so a MemoryImage of it decodes.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');

CitizenAccount _account() => CitizenAccount(
  id: 'ESP-TEST-LEFTOVERS',
  firstName: 'Test',
  lastName: 'Resident',
  email: 'test@example.com',
  mobile: '0900 000 0000',
  barangay: 'Poblacion',
  purok: 'Purok 1',
  address: 'Purok 1, Brgy. Poblacion',
  birthdate: '1970-01-01',
  sex: '—',
  civilStatus: '—',
  occupation: '—',
  profileCompleteness: 100,
  status: 'Approved',
);

Future<void> _until(WidgetTester tester, bool Function() ready, String what) async {
  var attempts = 0;
  while (!ready()) {
    attempts++;
    if (attempts > 100) throw StateError('$what never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
}

Future<CitizenSessionService> _signedIn(WidgetTester tester, CitizenAccount account) async {
  final session = CitizenSessionService();
  await _until(tester, () => !session.loading, 'CitizenSessionService');
  await session.login(account);
  return session;
}

Future<ResidentProfileService> _loadedProfiles(WidgetTester tester) async {
  final profiles = ResidentProfileService();
  await _until(tester, () => profiles.loaded, 'ResidentProfileService');
  return profiles;
}

Widget _providers(CitizenSessionService session, ResidentProfileService profiles, Widget home) => MultiProvider(
  providers: [
    ChangeNotifierProvider<CitizenSessionService>.value(value: session),
    ChangeNotifierProvider<ResidentProfileService>.value(value: profiles),
  ],
  child: MaterialApp(home: home),
);

void main() {
  tearDown(FakeApi.restore);

  group('Sign-out (140, 143)', () {
    testWidgets('what open screens bring back while the server is told is erased too', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final account = _account();
      final session = await _signedIn(tester, account);
      final profiles = await _loadedProfiles(tester);
      final masterFile = MasterFileService();
      final notifications = NotificationsService();
      await _until(tester, () => masterFile.loaded, 'MasterFileService');
      await _until(tester, () => notifications.loaded, 'NotificationsService');
      final requests = RequestsService();
      final balita = BalitaService();
      profiles.profileFor(account); // the open Profile page

      var bellReads = 0;
      FakeApi.installFull((r) {
        if (r.method == 'POST' && r.path == '/auth/logout') {
          // Still signed in here: Profile rebuilds and seeds the profile
          // again, and live updates reload the bell.
          profiles.profileFor(account).personal.birthdate = DateTime(1999, 9, 9);
          notifications.loadServer().catchError((Object _) {});
          return <String, dynamic>{};
        }
        if (r.path == '/citizen/notifications') {
          bellReads++;
          return [
            {'id': 1, 'title': 'Synthetic notice for the signed-out resident'},
          ];
        }
        throw const FakeApiError();
      });

      await SignOut.signOut(
        session,
        requests: requests,
        profiles: profiles,
        masterFile: masterFile,
        notifications: notifications,
        balita: balita,
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }

      expect(session.isSignedIn, isFalse);
      expect(bellReads, 1, reason: 'the bell did reload while the server was told');
      expect(notifications.serverNotifications, isEmpty);

      // The next resident's save writes the store: nothing of the one who left.
      await profiles.forgetAccount('ESP-TEST-NEXT-RESIDENT');
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('esperanza_resident_profiles') ?? '{}') as Map;
      expect(stored.containsKey(account.id), isFalse);
      expect(profiles.profileFor(account).personal.birthdate, isNot(DateTime(1999, 9, 9)));
    });

    test('a bell load under way when the account is forgotten does not bring it back', () async {
      SharedPreferences.setMockInitialValues({});
      FakeApi.installFull((r) {
        if (r.path == '/citizen/notifications') {
          return [
            {'id': 1, 'title': 'Synthetic notice'},
          ];
        }
        throw const FakeApiError();
      });
      final notifications = NotificationsService();
      addTearDown(notifications.dispose);
      await notifications.loadServer();
      expect(notifications.serverNotifications, hasLength(1), reason: 'the fixture loads');

      final load = notifications.loadServer();
      final forget = notifications.forgetAccount('ESP-TEST-LEFTOVERS');
      await Future.wait([load, forget]);

      expect(notifications.serverNotifications, isEmpty);
    });
  });

  group('Resident profile pages (139)', () {
    for (final entry in <String, Widget Function()>{
      'Resident Profile': () => const ResidentProfileOverviewScreen(),
      'Family Information': () => const FamilyInformationScreen(),
      'Review & Submit': () => const ReviewSubmitScreen(),
    }.entries) {
      testWidgets('${entry.key} survives the session ending while it is open', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final session = await _signedIn(tester, MockCatalog.demoAccounts.first);
        final profiles = await _loadedProfiles(tester);
        await tester.pumpWidget(_providers(session, profiles, entry.value()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await session.logout();
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });

  test("a family member's education and contact the phone does not hold are left out, not sent as none (45)", () async {
    SharedPreferences.setMockInitialValues({});
    final account = _account();
    final service = ResidentProfileService();
    addTearDown(service.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    service.profileFor(account);
    await service.addFamilyMember(
      account.id,
      Individual(individualId: 'IND-SYN-1', firstName: 'Lito', relationshipToHead: 'Son', hasEsperanzaAccount: false),
    );
    await service.addFamilyMember(
      account.id,
      Individual(
        individualId: 'IND-SYN-2',
        firstName: 'Lita',
        relationshipToHead: 'Daughter',
        hasEsperanzaAccount: false,
        educationalAttainment: 'Elementary',
        mobile: '09170000001',
      ),
    );

    FakeApiRequest? sent;
    FakeApi.installFull((r) {
      if (r.method != 'PUT') throw const FakeApiError();
      sent = r;
      return {
        'individual': {'ref': 'RES-2026-0001', 'verification': 'For Validation'},
      };
    });
    await service.submit(account.id);

    final members = ((sent!.body!['family'] as Map)['members'] as List).cast<Map>();
    final lito = members.firstWhere((m) => m['name'] == 'Lito');
    expect(lito.containsKey('education'), isFalse, reason: 'the server keeps what its registry holds');
    expect(lito.containsKey('contact'), isFalse);
    final lita = members.firstWhere((m) => m['name'] == 'Lita');
    expect(lita['education'], 'Elementary');
    expect(lita['contact'], '09170000001');
    expect((sent!.body!['personal'] as Map).containsKey('education'), isTrue, reason: "the resident's own is asked here");
  });

  test('a Submit with no answer takes nothing as filed when the list was never read (135, 138)', () async {
    FakeApi.installFull((r) {
      if (r.path == '/citizen/requests') {
        // Filed earlier in the hour (on the website, say): not this Submit.
        return [
          {
            'ref': 'DOK-2026-09001',
            'type': 'dokyu',
            'service': 'Synthetic Clearance',
            'status': 'Submitted',
            'submitted': DateTime.now().toUtc().toIso8601String(),
          },
        ];
      }
      throw const FakeApiError();
    });
    final requests = RequestsService();
    addTearDown(requests.dispose);
    final check = FiledRequestCheck.of(requests);

    const timedOut = ApiException(retryable: true, messageEn: 'The request timed out.');
    expect(await check.find(timedOut, requests, serviceName: 'Synthetic Clearance'), isNull);
  });

  test("a refused booking names the field's own reason (178)", () {
    const refused = ApiException(
      status: 422,
      messageEn: 'Some fields need correcting.',
      fields: {
        'notes': ['The notes may not be greater than 300 characters.'],
      },
    );
    expect(AppointmentsService.explain(refused), 'The notes may not be greater than 300 characters.');
    expect(
      AppointmentsService.explain(const ApiException(status: 409, code: 'SLOT_NOT_OFFERED', messageEn: 'Conflict.')),
      AppointmentsService.refusals['SLOT_NOT_OFFERED'],
    );
  });

  group("The drawer's avatar (141)", () {
    Future<ImageProvider?> drawerAvatar(WidgetTester tester, Map<String, Object?>? latest) async {
      final account = MockCatalog.demoAccounts.first;
      final seeded = ResidentProfile.seedFrom(account)..personal.photoBytesBase64 = base64Encode(_png);
      SharedPreferences.setMockInitialValues({
        'esperanza_resident_profiles': jsonEncode({account.id: seeded.toJson()}),
      });
      final session = await _signedIn(tester, account);
      if (latest != null) {
        FakeApi.install((path, query) {
          if (path == '/citizen/profile/photo') return {'url': null, 'latest': latest, 'can_change': true};
          throw const FakeApiError();
        });
        await tester.runAsync(() => session.uploadProfilePhoto(const [1, 2, 3]));
      }
      final profiles = await _loadedProfiles(tester);
      await tester.pumpWidget(_providers(session, profiles, const Scaffold(body: EsperanzaDrawer())));
      await tester.pumpAndSettle();
      final avatar = tester
          .widget<CircleAvatar>(find.descendant(of: find.byType(EsperanzaDrawer), matching: find.byType(CircleAvatar)).first)
          .backgroundImage;
      return avatar is ResizeImage ? avatar.imageProvider : avatar;
    }

    testWidgets('shows the photo picked on this phone when none is waiting at the LGU', (tester) async {
      expect(await drawerAvatar(tester, null), isA<MemoryImage>());
    });

    for (final latest in [
      {'status': 'Pending Review', 'remarks': null},
      {'status': 'Rejected', 'remarks': 'The face is not clear.'},
    ]) {
      testWidgets('does not show a first photo ${latest['status']} at the LGU', (tester) async {
        expect(await drawerAvatar(tester, latest), isNot(isA<MemoryImage>()));
      });
    }
  });

  group("A screen reader's double-tap (148)", () {
    tearDown(() {
      if (ServiceLauncherMenu.isOpen) ServiceLauncherMenu.dismiss();
    });

    testWidgets('opens a bottom-nav tab', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 72,
                child: Row(
                  children: [
                    EsperanzaNavItem(
                      item: const NavItemData(outlineIcon: Icons.home_outlined, filledIcon: Icons.home, label: 'Home'),
                      isActive: false,
                      onTap: () => taps++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Home'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets("picks the launcher's Dokyu", (tester) async {
      final semantics = tester.ensureSemantics();
      late BuildContext ctx;
      ServiceLauncherTarget? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                ctx = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      ServiceLauncherMenu.show(ctx, onSelect: (target) => picked = target);
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.bySemanticsLabel('Dokyu'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(picked, ServiceLauncherTarget.dokyu);
      semantics.dispose();
    });
  });
}
