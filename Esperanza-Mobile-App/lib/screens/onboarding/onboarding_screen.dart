import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/esperanza_seal.dart';
import '../../utils/fade_page_route.dart';
import '../../widgets/app_button.dart';
import 'onboarding_page_data.dart';
import 'widgets/onboarding_parallax_layer.dart';
import 'widgets/onboarding_progress.dart';

/// The three first-run welcome screens, shown once (see [OnboardingService])
/// straight after the every-launch [SplashScreen].
///
/// **The pattern is the Servana client's welcome experience**, rebuilt on
/// Esperanza's palette, seal and voice: a full-bleed photograph per scene
/// under a navy scrim whose stops interpolate continuously through the swipe,
/// the photograph lagging the page for depth, and white copy set low over the
/// dark half of the frame where it is always legible. The retired design put
/// a boxed illustration above dark-on-light copy; this one lets the
/// photograph carry the page.
///
/// **What the previous design could not do.** Each page used to be a single
/// flattened PNG — the whole interface, headline and all, baked into one
/// 1.4 MB image. Screen two advertised **"Business Permit — Approved"**, an
/// outcome nothing here produces: there is no backend. Its ~0.65 aspect ratio
/// against a phone's ~0.46 forced `BoxFit.contain`, letterboxing every device,
/// and each image carried an empty grey panel where a control had been mocked
/// up and never built. None of the text scaled, none of it reached a screen
/// reader, and none of it could be tested.
///
/// The invariants around it are unchanged and deliberately so: splash runs
/// every launch, onboarding runs once, Skip and Get Started both complete it,
/// and completion is persisted before `AuthGate` replaces this route.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  /// The settled page. Driven by `onPageChanged`; the per-frame scroll
  /// position is read straight off the controller inside `AnimatedBuilder`s,
  /// so a swipe never calls `setState`.
  int _page = 0;
  bool _finishing = false;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Decoded at display width, once. Without this the first swipe reaches a
    // page whose photograph has not decoded and shows the Scaffold instead.
    final cacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    for (final scene in onboardingScenes) {
      precacheImage(
        backgroundProvider(scene.backgroundAsset, cacheWidth),
        context,
      );
    }
    precacheImage(const AssetImage(esperanzaSealAsset), context);
  }

  /// One provider shape for precache and render alike. Two different shapes
  /// populate two different image-cache entries, and the precache silently
  /// buys nothing.
  static ImageProvider backgroundProvider(String asset, int cacheWidth) =>
      ResizeImage.resizeIfNeeded(cacheWidth, null, AssetImage(asset));

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await OnboardingService.markComplete();
    if (!mounted) return;
    // pushReplacement — AuthGate becomes the new root route, the same
    // invariant SplashScreen's own handoff preserves (see its doc comment).
    Navigator.of(context).pushReplacement(fadePageRoute(const AuthGate()));
  }

  void _next() {
    if (_page >= onboardingScenes.length - 1) {
      AppHaptics.medium();
      _finish();
      return;
    }
    AppHaptics.selection();
    if (MediaQuery.disableAnimationsOf(context)) {
      // Someone who asked the platform for no animation should not wait out a
      // 340 ms slide to reach the next page.
      _pageController.jumpToPage(_page + 1);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skip() {
    AppHaptics.light();
    _finish();
  }

  /// The scrim's three stops, interpolated between the neighbouring scenes so
  /// the overlay never snaps at a page boundary — Servana's trick, and the
  /// reason the transition reads as one continuous surface.
  List<double> _stops() {
    final progress = OnboardingParallaxLayer.progressOf(_pageController);
    final lo = progress.floor().clamp(0, onboardingScenes.length - 1);
    final hi = progress.ceil().clamp(0, onboardingScenes.length - 1);
    final a = onboardingScenes[lo].gradientStops;
    if (lo == hi) return a;
    final b = onboardingScenes[hi].gradientStops;
    final t = progress - lo;
    return [for (var i = 0; i < 3; i++) a[i] + (b[i] - a[i]) * t];
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isLast = _page == onboardingScenes.length - 1;
    final scene = onboardingScenes[_page];
    final cacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    return Scaffold(
      // Navy, not white: this is only ever visible for a stray frame, and
      // against these dark plates a white flash is the jarring one.
      backgroundColor: AppColors.navy950,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background photographs ────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingScenes.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => OnboardingParallaxLayer(
              transformKey: Key('onboarding_background_$i'),
              controller: _pageController,
              pageIndex: i,
              factor: OnboardingParallax.background,
              verticalFactor: OnboardingParallax.backgroundVertical,
              enabled: !reduceMotion,
              child: Semantics(
                label: onboardingScenes[i].semanticDescription,
                image: true,
                child: SizedBox.expand(
                  child: Image(
                    image: backgroundProvider(
                      onboardingScenes[i].backgroundAsset,
                      cacheWidth,
                    ),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                    // A missing plate must not show a white void behind white
                    // text. The palette's darkest ink is the safe fallback.
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: AppColors.navy950),
                  ),
                ),
              ),
            ),
          ),

          // ── Scrim ─────────────────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.navy950.withValues(alpha: 0.05),
                        AppColors.navy900.withValues(alpha: 0.55),
                        AppColors.navy950.withValues(alpha: 0.94),
                      ],
                      stops: reduceMotion
                          ? onboardingScenes[_page].gradientStops
                          : _stops(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Top scrim ─────────────────────────────────────────────────
          //
          // The main scrim is deliberately near-transparent at the top so the
          // photograph opens the frame. That leaves the seal and wordmark
          // sitting on whatever the picture happens to be — a bright ambulance
          // on page three — so white text has no guaranteed contrast. This
          // short gradient gives the identity bar its own ground without
          // darkening the picture.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navy950.withValues(alpha: 0.60),
                      AppColors.navy950.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Interface ─────────────────────────────────────────────────
          //
          // A Column, NOT a full-screen scroll view.
          //
          // The first version wrapped this whole layer in a
          // SingleChildScrollView so it could never overflow. A `Scrollable`
          // hit-tests opaquely across its entire box, so it sat over the
          // PageView and swallowed every pointer before the pager could see
          // one — swiping between pages did nothing at all, on a device as
          // much as in a test, and only the Next button worked. Measured:
          // `position.pixels` stayed at exactly 0.0 through a 240px drag.
          //
          // The middle of the screen now belongs to an `Align` that
          // shrink-wraps the copy to the bottom. An Align hit-tests only its
          // child, so pointers in the empty space above it fall straight
          // through to the photograph behind, and the swipe works.
          //
          // The bottom block is still not a swipe surface, and that is
          // accepted rather than overlooked: a `Scrollable` hit-tests opaquely
          // whatever its physics say — `NeverScrollableScrollPhysics` was
          // tried and changes nothing — and it has to stay a scroll view so
          // the copy survives text scale 2.0 on a short handset. So the
          // photograph is the swipe surface, which is how every onboarding of
          // this shape behaves, and `Next` works everywhere.
          // `onboarding_redesign_test.dart` pins the photograph area as
          // swipeable so a future full-screen scroll view cannot quietly take
          // it away again.
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _IdentityBar(onSkip: isLast || _finishing ? null : _skip),
                    // Only the copy scrolls; the button never does.
                    //
                    // A first attempt put the CTA inside the scroll view
                    // too, and at 320x568 with text scale 2.0 it landed at
                    // y=1437 on a 568-tall screen — reachable only by
                    // scrolling, which is not what "keep the primary action
                    // reachable" means.
                    //
                    // `Align` rather than a `Spacer`: when the copy is
                    // shorter than the space, the scroll view shrink-wraps
                    // and sits at the bottom, and the empty region above it
                    // belongs to the Align — which hit-tests only its child,
                    // so pointers there fall through to the photograph and
                    // the swipe survives.
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _FeatureChips(
                                scene: scene,
                                controller: _pageController,
                                pageIndex: _page,
                                reduceMotion: reduceMotion,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _CopyBlock(
                                key: ValueKey('copy_${scene.id}'),
                                scene: scene,
                                reduceMotion: reduceMotion,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
                      child: AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        child: isLast
                            ? AppButton(
                                key: const Key('onboarding_get_started'),
                                label: 'Get Started',
                                fullWidth: true,
                                size: AppButtonSize.lg,
                                loading: _finishing,
                                onPressed: _finishing ? null : _next,
                              )
                            : AppButton(
                                key: const Key('onboarding_next'),
                                label: 'Next',
                                icon: Icons.arrow_forward_rounded,
                                iconTrailing: true,
                                fullWidth: true,
                                size: AppButtonSize.lg,
                                onPressed: _finishing ? null : _next,
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: OnboardingProgress(
                        key: const Key('onboarding_progress'),
                        controller: _pageController,
                        page: _page,
                        count: onboardingScenes.length,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seal, municipality, and Skip — over the photograph, never moving with it.
class _IdentityBar extends StatelessWidget {
  const _IdentityBar({required this.onSkip});

  /// Null on the final page, which removes Skip from the tree entirely — not
  /// merely fades it. A control at zero opacity is still focusable and still
  /// announced, and "Skip" offered to someone already on the last page is a
  /// control that does nothing they want.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 16, not 24: at text scale 2.0 on a 320px handset the wordmark and Skip
      // together need every pixel of the gutter.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold300, width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                esperanzaSealAsset,
                fit: BoxFit.cover,
                cacheWidth: (30 * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                excludeFromSemantics: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          // Flexible + ellipsis: this exact Row overflowed once already, when
          // the wordmark's natural width exceeded what was left beside Skip on
          // a narrow phone. At text scale 2.0 it would again.
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                onboardingBrandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.wordmark.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (onSkip != null)
            ConstrainedBox(
              // 48x48, which a bare TextButton does not guarantee at every
              // text scale.
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: TextButton(
                key: const Key('onboarding_skip'),
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: Text(
                  'Skip',
                  style: AppTypography.label.copyWith(color: AppColors.surface),
                ),
              ),
            )
          else
            // Holds the bar's height steady when Skip goes, so the seal and
            // wordmark do not shift up on the last page.
            const SizedBox(height: 48),
        ],
      ),
    );
  }
}

/// Headline and supporting line, low in the frame over the dark half.
class _CopyBlock extends StatelessWidget {
  const _CopyBlock({
    super.key,
    required this.scene,
    required this.reduceMotion,
  });

  final OnboardingSceneSpec scene;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final block = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scene.headline,
            style: AppTypography.hero.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            scene.subtext,
            style: AppTypography.body.copyWith(
              color: AppColors.surface.withValues(alpha: 0.82),
              height: 1.55,
            ),
          ),
          if (scene.note != null) ...[
            const SizedBox(height: AppSpacing.md),
            // A limit, marked as one — icon and words, never colour alone.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 15,
                  color: AppColors.gold300,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    scene.note!,
                    style: AppTypography.captionSmallRegular.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (reduceMotion) return block;
    return _SceneSwitcher(child: block);
  }
}

/// Three capability chips, sitting just above the headline.
class _FeatureChips extends StatelessWidget {
  const _FeatureChips({
    required this.scene,
    required this.controller,
    required this.pageIndex,
    required this.reduceMotion,
  });

  final OnboardingSceneSpec scene;
  final PageController controller;
  final int pageIndex;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [for (final f in scene.features) _Chip(feature: f)],
      ),
    );

    return OnboardingParallaxLayer(
      transformKey: const Key('onboarding_chips'),
      controller: controller,
      pageIndex: pageIndex,
      factor: OnboardingParallax.chips,
      enabled: !reduceMotion,
      child: reduceMotion ? row : _SceneSwitcher(child: row),
    );
  }
}

/// Glass chip: translucent white over the photograph, with a hairline edge so
/// it still reads against a bright sky.
class _Chip extends StatelessWidget {
  const _Chip({required this.feature});

  final OnboardingFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The icon is the second channel that keeps these distinguishable
          // without relying on colour.
          Icon(feature.icon, size: 15, color: AppColors.surface),
          const SizedBox(width: AppSpacing.sm - 2),
          Flexible(
            child: Text(
              feature.label,
              maxLines: 2,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cross-fade with a short rise, keyed on the scene so a page change replays
/// it. Finite by construction — an `AnimatedSwitcher` settles and stops, which
/// is what keeps `pumpAndSettle` honest.
class _SceneSwitcher extends StatelessWidget {
  const _SceneSwitcher({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.07),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
