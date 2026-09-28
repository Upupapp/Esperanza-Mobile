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
import 'package:esperanza_mobile/screens/profile/government_id_viewer.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/profile_photo_preview_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/theme/app_typography.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:esperanza_mobile/widgets/image_viewer_scaffold.dart';

import 'support/fake_api.dart';

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
    testWidgets('the title is set in Inter and fits on one line', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GovernmentIdViewer(record: MockCatalog.verifiedDemoGovernmentId)),
      );
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.titleTextStyle?.fontFamily, AppTypography.sans);
      final title = tester.widget<Text>(find.text(MockCatalog.verifiedDemoGovernmentId.idType));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(find.text(ImageViewerScaffold.zoomHint), findsOneWidget);
    });

    testWidgets('a screen reader hears what the image is', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(home: GovernmentIdViewer(record: MockCatalog.verifiedDemoGovernmentId)),
      );
      expect(find.bySemanticsLabel('Your submitted ${MockCatalog.verifiedDemoGovernmentId.idType}'), findsOneWidget);
      semantics.dispose();
    });

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

    testWidgets('it says the photo stays on the phone', (tester) async {
      await pump(tester, ResidentProfileService());
      expect(find.textContaining(ProfilePhotoPreviewScreen.deviceOnlyText), findsOneWidget);
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

  group('demo Digital ID wallet', () {
    Future<List<String>> pump(WidgetTester tester, {required bool Function() fails}) async {
      _size(tester, const Size(390, 1100));
      final calls = <String>[];
      FakeApi.installFull((r) {
        calls.add(r.path);
        if (fails()) throw const FakeApiError(status: 503, code: 'UNAVAILABLE');
        return {
          'account_no': 'ESP-2026-9002',
          'qr': 'esperanza:v1:ESP-2026-9002:sig',
          'name': 'Perlita Quiambao',
          'barangay': 'Baras',
          'status': 'Verified',
          'valid': true,
          'issued_at': '2026-09-01',
        };
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
      return calls;
    }

    testWidgets('when the live card fails, the wallet says so and Try Again reaches the live card', (tester) async {
      var down = true;
      final calls = await pump(tester, fails: () => down);
      expect(find.textContaining('could not be loaded, so the sample IDs'), findsOneWidget);
      expect(find.text('Barangay Resident ID'), findsOneWidget);

      down = false;
      await tester.tap(find.text('Try Again'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(calls.where((p) => p == '/citizen/digital-id'), hasLength(2));
      expect(find.textContaining('could not be loaded'), findsNothing);
      expect(find.text('ESP-2026-9002'), findsWidgets);
    });

    testWidgets('a screen reader can move to the next ID without swiping', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, fails: () => true);
      expect(find.text('1 of 2'), findsOneWidget);
      final card = find.bySemanticsLabel(RegExp(r'^Barangay Resident ID, front side'));
      final node = tester.getSemantics(card);
      final next = node.getSemanticsData().customSemanticsActionIds!.map(CustomSemanticsAction.getAction);
      expect(next.map((a) => a!.label), ['Next ID']);
      tester.semantics.customAction(find.semantics.byLabel(RegExp(r'^Barangay Resident ID, front side')), next.single!);
      await tester.pumpAndSettle();
      expect(find.text('2 of 2'), findsOneWidget);
      semantics.dispose();
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
    final paragraph = tester.renderObject<RenderParagraph>(find.text(onboardingBrandName));
    expect(paragraph.didExceedMaxLines, isFalse);
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
