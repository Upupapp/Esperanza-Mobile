// QA sweep 2026-11-18, app-1: Digital ID, the resident profile forms, the
// Profile page, Valid ID Verification, the Filipino "Name" and the camera
// and gallery pickers. Synthetic identities only.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/l10n/filipino_text.dart';
import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/models/resident_profile.dart';
import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/screens/profile/id_verification_screen.dart';
import 'package:esperanza_mobile/screens/profile/profile_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/family_member_form_sheet.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/household_information_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/personal_information_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/identity_capture.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/services/wallet_service.dart';
import 'package:esperanza_mobile/utils/protected_action.dart';
import 'package:esperanza_mobile/widgets/app_text_field.dart';

import 'support/fake_api.dart';
import 'support/wallet_fixture.dart';

/// A real 1x1 PNG, so a MemoryImage of it decodes.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');

Future<CitizenSessionService> _loginSession(WidgetTester tester, CitizenAccount account) async {
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(account);
  return session;
}

Future<ResidentProfileService> _loadedProfiles(WidgetTester tester) async {
  final profiles = ResidentProfileService();
  var attempts = 0;
  while (!profiles.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('ResidentProfileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return profiles;
}

Widget _providers(CitizenSessionService session, ResidentProfileService profiles, Widget home) => MultiProvider(
  providers: [
    ChangeNotifierProvider<CitizenSessionService>.value(value: session),
    ChangeNotifierProvider<ResidentProfileService>.value(value: profiles),
  ],
  child: MaterialApp(home: home),
);

/// A plain page with one button that opens [page] over it, as the app does.
Widget _opener(Widget Function() page) => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page())),
        child: const Text('Open'),
      ),
    ),
  ),
);

/// Digital ID over the fake API, signed in. Returns every request made.
Future<List<FakeApiRequest>> _pumpWallet(WidgetTester tester, dynamic Function(FakeApiRequest r) handler) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final calls = <FakeApiRequest>[];
  FakeApi.installFull((r) {
    calls.add(r);
    return handler(r);
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

/// Lets requests and image loads finish, and the photo's own tries run out.
Future<void> _settleImages(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(seconds: 2));
  }
}

/// The Didit card the wallet test uses, with photo links.
Map<String, dynamic> _diditCard({required int id, required String status, String kind = 'philippine_national_id'}) =>
    walletDocumentJson(
      id: id,
      idKind: kind,
      name: 'ID $id',
      documentStatus: status,
      checkSource: 'registration',
      lguRemarks: status == 'returned_by_lgu' ? 'The photo is too blurry to read.' : null,
    )..['front_url'] = 'https://test.invalid/files/front-$id';

class _FakePicker extends ImagePickerPlatform {
  _FakePicker(this.onPick);

  final Future<XFile?> Function(ImageSource source) onPick;

  @override
  Future<XFile?> getImageFromSource({required ImageSource source, ImagePickerOptions options = const ImagePickerOptions()}) =>
      onPick(source);
}

const _permissionsChannel = MethodChannel('flutter.baseflow.com/permissions/methods');

/// What the phone answers permission_handler: [status] for every check
/// (0 denied, 1 granted, 4 permanently denied) and whether Android would
/// still show its prompt ([mayAskAgain]).
void _phonePermissions(WidgetTester tester, {int status = 0, bool mayAskAgain = true}) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_permissionsChannel, (call) async {
    switch (call.method) {
      case 'checkPermissionStatus':
        return status;
      case 'shouldShowRequestPermissionRationale':
        return mayAskAgain;
    }
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_permissionsChannel, null));
}

void _picker(WidgetTester tester, Future<XFile?> Function(ImageSource source) onPick) {
  final previous = ImagePickerPlatform.instance;
  ImagePickerPlatform.instance = _FakePicker(onPick);
  addTearDown(() => ImagePickerPlatform.instance = previous);
}

void main() {
  group('Digital ID', () {
    testWidgets('a Didit card the LGU verified or returned is never sent a face position', (tester) async {
      final fetched = <String>[];
      final previous = WalletService.fetchImage;
      WalletService.fetchImage = (url) async {
        fetched.add(url);
        return null;
      };
      addTearDown(() => WalletService.fetchImage = previous);

      final calls = await _pumpWallet(tester, (r) {
        if (r.path == '/citizen/wallet') {
          return walletJson(
            documents: [
              _diditCard(id: 9101, status: 'verified_by_lgu'),
              _diditCard(id: 9102, status: 'returned_by_lgu', kind: 'umid'),
              _diditCard(id: 9103, status: 'checked_by_didit', kind: 'passport'),
            ],
          );
        }
        throw const FakeApiError();
      });

      // Only the card no officer has decided on is looked at for a face.
      expect(fetched, ['https://test.invalid/files/front-9103']);
      expect(calls.where((r) => r.method == 'PATCH'), isEmpty);
    });

    testWidgets('a Save with nothing changed keeps every field Didit read, in its stored order', (tester) async {
      Map<String, dynamic> passport() => walletDocumentJson(
        id: 9201,
        idKind: 'passport',
        name: 'Philippine Passport',
        documentStatus: 'verified_by_lgu',
        checkSource: 'registration',
        details: {
          'id_number': 'P1234567A',
          'holder_name': 'Halimbawa Sintetiko',
          'birthdate': '1995-01-15',
          'sex': 'Female',
          // As Didit stores them: not the form's order, and one field
          // (civil status) a passport's form does not show.
          'details': {'place_of_birth': 'Esperanza', 'nationality': 'Filipino', 'civil_status': 'Single'},
        },
      );
      final patches = <Map<String, dynamic>?>[];
      await _pumpWallet(tester, (r) {
        if (r.path == '/citizen/wallet') return walletJson(documents: [passport()]);
        if (r.method == 'PATCH' && r.path == '/citizen/wallet/ids/9201') {
          patches.add(r.body);
          return passport();
        }
        throw const FakeApiError();
      });

      await _openDetails(tester, 'Philippine Passport');
      await tester.ensureVisible(find.text('Edit details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      final details = patches.single!['details'] as Map<String, dynamic>;
      expect(details.keys.toList(), ['place_of_birth', 'nationality', 'civil_status']);
      expect(details, {'place_of_birth': 'Esperanza', 'nationality': 'Filipino', 'civil_status': 'Single'});
    });

    testWidgets('a refresh that fails keeps the Resident ID and its QR on screen, and says so', (tester) async {
      var online = true;
      await _pumpWallet(tester, (r) {
        if (r.path == '/citizen/wallet') {
          if (!online) throw const FakeApiError(status: 503, code: 'UNAVAILABLE');
          return walletJson();
        }
        throw const FakeApiError();
      });
      expect(find.byType(QrImageView), findsOneWidget);

      online = false;
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator).first).show();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget, reason: 'the card the resident was showing stays');
      expect(find.text('Valid · Verified by LGU'), findsOneWidget);
      expect(find.text('Try Again'), findsNothing, reason: 'no error page in place of the card');
      expect(find.byType(SnackBar), findsOneWidget, reason: 'the failed refresh is said');
    });

    testWidgets('trying a photo again first fetches a fresh signed link', (tester) async {
      var reads = 0;
      await _pumpWallet(tester, (r) {
        if (r.path == '/citizen/wallet') {
          reads++;
          return walletJson(
            documents: [walletDocumentJson()..['front_url'] = 'https://test.invalid/files/front?signature=$reads'],
          );
        }
        throw const FakeApiError();
      });
      await _openDetails(tester, 'PhilHealth ID');
      await _settleImages(tester);
      final retry = find.text('This image could not be loaded. Tap to try again.');
      expect(retry, findsOneWidget);

      final before = reads;
      await tester.tap(retry);
      await _settleImages(tester);

      expect(reads, before + 1, reason: 'a link that ran out is never tried again as it is');
      expect(
        find.byWidgetPredicate(
          (w) => w is Image && w.image is NetworkImage && (w.image as NetworkImage).url.endsWith('signature=${before + 1}'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Resident profile forms', () {
    testWidgets('saving Household Information keeps the monthly income from Personal Information', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final account = MockCatalog.demoAccounts.first;
      final session = await _loginSession(tester, account);
      final profiles = await _loadedProfiles(tester);
      profiles.profileFor(account);
      final income = ResidentProfileOptions.monthlyIncome[3];
      await profiles.setMonthlyIncome(account.id, income);

      await tester.pumpWidget(_providers(session, profiles, _opener(() => const HouseholdInformationScreen())));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save for Later'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save for Later'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget, reason: 'saved and closed');
      expect(profiles.profileFor(account).household.monthlyIncome, income);
    });

    testWidgets('editing a family member keeps what the sheet does not show', (tester) async {
      final member = Individual(
        individualId: 'IND-REG-9301',
        serverRef: 'IND-REG-9301',
        firstName: 'Lito',
        middleName: 'Santos',
        lastName: 'Sintetiko',
        sex: 'Male',
        birthdate: DateTime(2012, 3, 4),
        civilStatus: 'Single',
        relationshipToHead: 'Son',
        educationalAttainment: 'Elementary',
        mobile: '09170000001',
        familyId: 'FAM-9301',
        householdId: 'HH-9301',
      );
      Individual? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    saved = await showModalBottomSheet<Individual>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => FamilyMemberFormSheet(existing: member),
                    );
                  },
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        ),
      );

      Future<void> openAndSave({String? rename}) async {
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        final name = find.descendant(of: find.widgetWithText(AppTextField, 'Full name'), matching: find.byType(TextField));
        // The whole name, though it is kept in parts.
        expect(tester.widget<TextField>(name).controller!.text, 'Lito Santos Sintetiko');
        if (rename != null) await tester.enterText(name, rename);
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
      }

      await openAndSave();
      expect(saved!.educationalAttainment, 'Elementary');
      expect(saved!.mobile, '09170000001');
      expect(saved!.serverRef, 'IND-REG-9301');
      expect(saved!.familyId, 'FAM-9301');
      expect(saved!.householdId, 'HH-9301');
      expect([saved!.firstName, saved!.middleName, saved!.lastName], ['Lito', 'Santos', 'Sintetiko']);

      saved = null;
      await openAndSave(rename: 'Lito Sintetiko Jr.');
      expect(saved!.fullName, 'Lito Sintetiko Jr.');
      expect(saved!.educationalAttainment, 'Elementary', reason: 'a new name changes nothing else');
      expect(saved!.mobile, '09170000001');
    });

    for (final latest in [
      {'status': 'Pending Review', 'remarks': null},
      {'status': 'Rejected', 'remarks': 'The face is not clear.'},
    ]) {
      testWidgets('a first photo ${latest['status']} at the LGU is not shown as the photo, and says where it stands', (
        tester,
      ) async {
        final account = MockCatalog.demoAccounts.first;
        final seeded = ResidentProfile.seedFrom(account)..personal.photoBytesBase64 = base64Encode(_png);
        SharedPreferences.setMockInitialValues({
          'esperanza_resident_profiles': jsonEncode({account.id: seeded.toJson()}),
        });
        final session = await _loginSession(tester, account);
        FakeApi.install((path, query) {
          if (path == '/citizen/profile/photo') return {'url': null, 'latest': latest, 'can_change': true};
          throw const FakeApiError();
        });
        addTearDown(FakeApi.restore);
        await tester.runAsync(() => session.uploadProfilePhoto(const [1, 2, 3]));
        final profiles = await _loadedProfiles(tester);

        await tester.pumpWidget(_providers(session, profiles, const PersonalInformationScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Remove photo'), findsNothing, reason: 'it would clear only the phone\'s copy');
        expect(
          find.text(
            latest['status'] == 'Rejected'
                ? 'Your new photo was not approved: The face is not clear.'
                : 'New photo sent. It shows here once the LGU approves it.',
          ),
          findsOneWidget,
        );
        final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first).backgroundImage;
        final shown = avatar is ResizeImage ? avatar.imageProvider : avatar;
        expect(shown, isNot(isA<MemoryImage>()), reason: 'the unapproved photo is not the photo');
      });
    }

    for (final entry in <String, Widget Function()>{
      'Profile': () => const ProfileScreen(),
      'Personal Information': () => const PersonalInformationScreen(),
      'Household Information': () => const HouseholdInformationScreen(),
    }.entries) {
      testWidgets('${entry.key} survives the session ending while it is open', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final account = MockCatalog.demoAccounts.first;
        final session = await _loginSession(tester, account);
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

  group('Valid ID Verification', () {
    for (final failure in <String, DiditLauncher>{
      'a dropped connection': (_) async => const DiditLaunchResult(DiditLaunchOutcome.failed, 'networkError'),
      'an error from the SDK itself': (_) async => throw PlatformException(code: 'sdk_error'),
    }.entries) {
      testWidgets('a Didit check that ends in ${failure.key} says so', (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        FakeApi.installFull((r) {
          if (r.path == '/citizen/verification/session') return {'session_id': 'sess-9401', 'session_token': 'tok-9401'};
          return {
            'id_types': ['PhilSys National ID'],
            'can_submit': true,
            'submission': null,
            'identity': {'status': null, 'reasons': <String>[], 'awaiting_check': false},
            'capture': 'hosted',
          };
        });
        addTearDown(FakeApi.restore);
        final previous = IdentityCapture.launcher;
        IdentityCapture.launcher = failure.value;
        addTearDown(() => IdentityCapture.launcher = previous);

        await tester.pumpWidget(
          ChangeNotifierProvider(create: (_) => CitizenSessionService(), child: const MaterialApp(home: IdVerificationScreen())),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start Verification'));
        await tester.pumpAndSettle();

        expect(find.text('Verification did not finish. Check your connection and try again.'), findsOneWidget);
        expect(find.text('Start Verification'), findsOneWidget, reason: 'they can start again');
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Filipino', () {
    test('the Name label reads Pangalan, never the evacuation table\'s Centre', () {
      expect(filipinoText['NAME'], 'PANGALAN');
      expect(filipinoText['Name'], 'Pangalan');
    });
  });

  group('Camera and gallery', () {
    XFile? picked;
    var done = false;

    Future<void> pumpPicker(WidgetTester tester, ImageSource source) async {
      // The explanation was answered before; this is what comes after it.
      SharedPreferences.setMockInitialValues({'protected_action_ack.camera': true, 'protected_action_ack.photos': true});
      picked = null;
      done = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    picked = await pickImageProtected(context, source: source);
                    done = true;
                  },
                  child: const Text('Pick'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
    }

    testWidgets('closing the gallery is a cancel, never "Permission was not granted"', (tester) async {
      // What the phone reports for photos when nothing ever asked for them.
      _phonePermissions(tester, status: 0);
      _picker(tester, (_) async => null);

      await pumpPicker(tester, ImageSource.gallery);

      expect(done, isTrue);
      expect(picked, isNull);
      expect(find.text('Photo Access Required'), findsNothing);
      expect(find.textContaining('Permission was not granted'), findsNothing);
    });

    testWidgets('refusing the camera prompt says so, and the tap is not lost to an error', (tester) async {
      _phonePermissions(tester, status: 0, mayAskAgain: true);
      _picker(tester, (_) async => throw PlatformException(code: 'camera_access_denied'));

      await pumpPicker(tester, ImageSource.camera);

      expect(tester.takeException(), isNull);
      expect(find.text('Camera Access Required'), findsOneWidget);
      expect(
        find.text('Permission was not granted. You can continue using the app, but this feature requires access to your camera.'),
        findsOneWidget,
      );
    });

    testWidgets('a camera the phone will no longer ask for leads to Settings', (tester) async {
      // Android stops asking after a second refusal.
      _phonePermissions(tester, status: 0, mayAskAgain: false);
      _picker(tester, (_) async => throw PlatformException(code: 'camera_access_denied'));

      await pumpPicker(tester, ImageSource.camera);

      expect(tester.takeException(), isNull);
      expect(find.text('Permission Required'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });
  });
}
