// The small screens' review: the full-screen image viewers, the profile
// photo preview, the demo Digital ID wallet and the onboarding wordmark.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/screens/onboarding/onboarding_page_data.dart';
import 'package:esperanza_mobile/screens/onboarding/onboarding_screen.dart';
import 'package:esperanza_mobile/screens/profile/digital_id_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/profile_photo_preview_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:esperanza_mobile/widgets/image_viewer_scaffold.dart';

import 'support/fake_api.dart';
import 'support/wallet_fixture.dart';

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FailingProfiles extends ResidentProfileService {
  @override
  Future<void> updateProfilePhoto(String accountId, {required photoBytes, required bool startCooldown}) =>
      Future.error(StateError('storage full'));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(FakeApi.restore);

  group('full-screen image viewer', () {
    testWidgets('an image that cannot load says so instead of a black screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewerScaffold(
            title: 'Missing',
            image: AssetImage('assets/images/missing.png'),
            semanticLabel: 'x',
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text(ImageViewerScaffold.unavailableText), findsOneWidget);
      // Nothing to zoom, so no zoom hint.
      expect(find.text(ImageViewerScaffold.zoomHint), findsNothing);
    });
  });

  group('profile photo preview', () {
    Future<void> pump(WidgetTester tester, ResidentProfileService profiles, {Size size = const Size(390, 844)}) async {
      _size(tester, size);
      final session = CitizenSessionService();
      await tester.runAsync(() => session.login(MockCatalog.demoAccounts.last));
      profiles.profileFor(session.account!);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CitizenSessionService>.value(value: session),
            ChangeNotifierProvider<ResidentProfileService>.value(value: profiles),
          ],
          child: MaterialApp(
            home: ProfilePhotoPreviewScreen(bytes: kTransparentPng, source: ImageSource.camera),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a failed save gives the buttons back and says why', (tester) async {
      await pump(tester, _FailingProfiles());
      await tester.tap(find.widgetWithText(AppButton, 'Save Profile Photo'));
      await tester.pump();
      await tester.pump();
      expect(find.text(ProfilePhotoPreviewScreen.saveFailedText), findsOneWidget);
      expect(tester.widget<AppButton>(find.widgetWithText(AppButton, 'Save Profile Photo')).onPressed, isNotNull);
      expect(tester.widget<AppButton>(find.widgetWithText(AppButton, 'Retake')).onPressed, isNotNull);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('it says the photo goes to the LGU for approval', (tester) async {
      await pump(tester, ResidentProfileService());
      expect(find.textContaining(ProfilePhotoPreviewScreen.sentText), findsOneWidget);
    });

    testWidgets('on a short phone with large text it scrolls rather than overflowing', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, ResidentProfileService(), size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      final save = find.widgetWithText(AppButton, 'Save Profile Photo');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(save).dy, lessThanOrEqualTo(568));
    });
  });

  group('Digital ID wallet', () {
    testWidgets('when the wallet fails it says so, shows no sample ID, and Try Again reaches it', (tester) async {
      _size(tester, const Size(390, 1100));
      var down = true;
      final calls = <String>[];
      FakeApi.installFull((r) {
        calls.add(r.path);
        if (down) throw const FakeApiError(status: 503, code: 'UNAVAILABLE', messageEn: 'The service is unavailable.');
        return walletJson(accountNo: 'ESP-2026-9002', name: 'Perlita Quiambao');
      });
      final session = CitizenSessionService();
      await tester.runAsync(() => session.login(MockCatalog.demoAccounts.last));
      await tester.pumpWidget(
        ChangeNotifierProvider<CitizenSessionService>.value(
          value: session,
          child: const MaterialApp(home: DigitalIdScreen()),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('The service is unavailable.'), findsOneWidget);
      expect(find.text('Barangay Resident ID'), findsNothing);
      expect(find.text('PWD ID'), findsNothing);

      down = false;
      await tester.tap(find.text('Try Again'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(calls.where((p) => p == '/citizen/wallet'), hasLength(2));
      expect(find.text('ESP-2026-9002'), findsWidgets);
    });
  });

  testWidgets('on a 320pt phone the onboarding wordmark shows the whole name', (tester) async {
    // The real faces: the test font is far wider than Lora.
    await tester.runAsync(() async {
      for (final (family, path) in [('Lora', 'assets/fonts/Lora.ttf'), ('Inter', 'assets/fonts/Inter.ttf')]) {
        await (FontLoader(family)..addFont(Future.value(ByteData.view(File(path).readAsBytesSync().buffer)))).load();
      }
    });
    _size(tester, const Size(320, 568));
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(find.text(onboardingBrandLines));
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  group('onboarding, second pass', () {
    testWidgets('Android back on page 2 goes to page 1 instead of closing the app', (tester) async {
      _size(tester, const Size(390, 844));
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
      expect(find.text(onboardingScenes[1].headline).hitTestable(), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text(onboardingScenes[0].headline).hitTestable(), findsOneWidget);
    });

    testWidgets('at double text size the headline and wordmark stop growing before words break', (tester) async {
      _size(tester, const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();
      double scaleOf(Finder f) => MediaQuery.textScalerOf(tester.element(f)).scale(10) / 10;
      expect(scaleOf(find.text(onboardingScenes[0].headline)), headlineMaxTextScale);
      expect(scaleOf(find.text(onboardingBrandLines)), wordmarkMaxTextScale);
      // The supporting line still follows the system size in full.
      expect(scaleOf(find.text(onboardingScenes[0].subtext)), 2.0);
    });
  });
}

/// A 1x1 transparent PNG: enough for the preview to decode.
final kTransparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);
