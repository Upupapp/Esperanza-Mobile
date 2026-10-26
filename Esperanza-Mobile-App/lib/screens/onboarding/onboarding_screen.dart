import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_typography.dart';
import '../../utils/ambient_motion.dart';
import '../../utils/esperanza_seal.dart';
import '../../utils/fade_page_route.dart';
import '../../widgets/gold_action_button.dart';
import '../../widgets/opening_waves.dart';
import '../../widgets/seal_badge.dart';
import 'onboarding_page_data.dart';

import '../../l10n/tr.dart';
/// How far the onboarding headline and wordmark follow the system text size.
const headlineMaxTextScale = 1.4;
const wordmarkMaxTextScale = 1.5;

/// The wordmark as the design sets it, on two lines.
const onboardingBrandLines = 'Municipalidad\nng Esperanza';

/// The three welcome screens, shown after the every-launch [SplashScreen]
/// whenever no one is signed in.
///
/// The owner's design ("Esperanza Onboarding Prototype", screens 2-4,
/// 2026-10-12), followed closely: a photograph across the top 57% with a slow
/// zoom, page one's gold-and-blue ribbon along its foot, the seal, wordmark
/// and Skip over it; below, a two-line headline (the second line gold), one
/// sentence, the page's three capabilities (icon tiles on page one, row cards
/// on two and three, each icon with its own small motion), the page dots and
/// a gold Next / Get Started with a shine passing over it.
///
/// Pages change by cross-fade: the photograph fades into the next, and the
/// copy fades with an 18px rise while its cards follow one after another. A
/// horizontal swipe anywhere turns the page, as do Next and the dots.
///
/// What is the app's, not the design's: Skip leaves the last page (a Skip
/// that does nothing the reader wants should not be focusable or announced),
/// Back steps back a page, the headline caps at 1.4x text, the dots have 44pt
/// tap targets, and everything decorative stops under reduce motion
/// ([AmbientMotion]). Skip and Get Started both lead to `AuthGate`, which
/// replaces this route.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  int _page = 0;

  /// False for the first frame, so page one rises in as the screen opens,
  /// as it does after the design's splash.
  bool _entered = false;
  bool _finishing = false;
  bool _precached = false;

  /// Seconds since the screen opened, for the ambient motion. Advanced by a
  /// ticker only while [AmbientMotion] allows it.
  final _clock = ValueNotifier<double>(0);
  late final Ticker _ambient = createTicker((elapsed) => _clock.value = elapsed.inMicroseconds / 1e6);

  Offset? _pointerDown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ambient = AmbientMotion.of(context);
    if (ambient && !_ambient.isActive) {
      _ambient.start();
    } else if (!ambient && _ambient.isActive) {
      _ambient.stop();
      _clock.value = 0;
    }
    if (_precached) return;
    _precached = true;
    // Decoded once, before the first page change asks for them.
    for (final scene in onboardingScenes) {
      precacheImage(AssetImage(scene.backgroundAsset), context);
    }
    precacheImage(ResizeImage(const AssetImage(esperanzaSealAsset), width: SealBadge.cacheWidth(context)), context);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _clock.dispose();
    super.dispose();
  }

  bool get _isLast => _page == onboardingScenes.length - 1;

  void _finish() {
    if (_finishing) return;
    // Nothing is saved: the pages open the app again for as long as no one
    // is signed in.
    setState(() => _finishing = true);
    // pushReplacement — AuthGate becomes the new root route, the same
    // invariant SplashScreen's own handoff preserves (see its doc comment).
    Navigator.of(context).pushReplacement(fadePageRoute(const AuthGate()));
  }

  void _go(int page) {
    final target = page.clamp(0, onboardingScenes.length - 1);
    if (target == _page || _finishing) return;
    AppHaptics.selection();
    setState(() => _page = target);
  }

  void _next() {
    if (_isLast) {
      AppHaptics.medium();
      _finish();
      return;
    }
    _go(_page + 1);
  }

  void _skip() {
    AppHaptics.light();
    _finish();
  }

  /// The design's swipe: more than 48 across, and clearly more across than
  /// down, so scrolling the copy never turns the page.
  void _onPointerUp(PointerUpEvent e) {
    final start = _pointerDown;
    _pointerDown = null;
    if (start == null) return;
    final d = e.position - start;
    if (d.dx.abs() > 48 && d.dx.abs() > d.dy.abs() * 1.3) {
      if (d.dx < 0 && !_isLast) _go(_page + 1);
      if (d.dx > 0 && _page > 0) _go(_page - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    // The design's vh-based sizes: a share of the screen height, kept
    // between its own bounds.
    double vh(double percent, double lo, double hi) => (size.height * percent / 100).clamp(lo, hi);
    final photoHeight = math.max(size.height * 0.57, 300.0);
    final headerTop = pad.top + 11;

    // Android's back button on page 2 or 3 used to close the app; it steps
    // back a page, and leaves onboarding only from the first.
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _go(_page - 1);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.navy900,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) => _pointerDown = e.position,
                onPointerUp: _onPointerUp,
                onPointerCancel: (_) => _pointerDown = null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      key: const Key('onboarding_photo'),
                      top: 0,
                      left: 0,
                      right: 0,
                      height: photoHeight,
                      child: _Photograph(page: _page, clock: _clock, reduce: reduce),
                    ),
                    Positioned(
                      top: headerTop,
                      left: 22,
                      right: 12,
                      child: _Header(onSkip: _isLast || _finishing ? null : _skip),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      top: headerTop + 56,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.navy900.withValues(alpha: 0),
                                AppColors.navy900.withValues(alpha: 0.85),
                                AppColors.navy900,
                              ],
                              // 0, 34 and 64px of the panel, as a share of
                              // a typical panel (~400).
                              stops: const [0, 0.085, 0.16],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Only the copy scrolls (at very large text on
                                // a small phone); the dots and the button stay
                                // put at the bottom.
                                Flexible(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        for (var i = 0; i < onboardingScenes.length; i++)
                                          _Pane(
                                            scene: onboardingScenes[i],
                                            index: i,
                                            active: _entered && i == _page,
                                            above: i < _page,
                                            reduce: reduce,
                                            clock: _clock,
                                            gap: vh(1.1, 6, 10),
                                            listGap: vh(1, 6, 8),
                                            topGap: vh(1.2, 6, 12),
                                            tileHeight: vh(12.5, 96, 108),
                                            rowHeight: vh(5.4, 42, 46),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: math.max(0, vh(1.5, 8, 12) - 10), bottom: math.max(0, vh(1.2, 6, 10) - 10)),
                                  child: _Dots(
                                    key: const Key('onboarding_progress'),
                                    page: _page,
                                    count: onboardingScenes.length,
                                    reduce: reduce,
                                    onSelect: _go,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(22, 0, 22, vh(2.6, 16, 22) + pad.bottom),
                                  child: GoldActionButton(
                                    key: Key(_isLast ? 'onboarding_get_started' : 'onboarding_next'),
                                    label: _isLast ? 'Get Started' : 'Next',
                                    textStyle: AppTypography.onboardingAction.copyWith(color: AppColors.navy900),
                                    arrow: !_isLast,
                                    nudge: true,
                                    height: vh(6.4, 50, 56),
                                    loading: _finishing,
                                    onPressed: _finishing ? null : _next,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ambient motion ─────────────────────────────────────────────────────────
//
// Each is a function of the screen's clock, in seconds, matching the
// design's CSS keyframes. At t = 0 every one is at rest, which is all a
// reduce-motion user or a widget test ever sees.

/// 0 → 1 → 0 over [period], eased in and out (the design's `alternate`
/// loops, and its 0%/50%/100% keyframes).
double _swing(double t, double period, {double delay = 0}) {
  if (t <= delay) return 0;
  final phase = ((t - delay) % period) / period;
  return Curves.easeInOut.transform(phase < 0.5 ? phase * 2 : 2 - phase * 2);
}

/// Piecewise keyframes ([at] as fractions of [period], [values] at each),
/// eased in and out between neighbours.
double _keyframes(double t, double period, List<double> at, List<double> values) {
  if (t <= 0) return values.first;
  final phase = (t % period) / period;
  for (var i = 1; i < at.length; i++) {
    if (phase <= at[i]) {
      final local = (phase - at[i - 1]) / (at[i] - at[i - 1]);
      return values[i - 1] + (values[i] - values[i - 1]) * Curves.easeInOut.transform(local);
    }
  }
  return values.last;
}

// ── The photograph ─────────────────────────────────────────────────────────

class _Photograph extends StatelessWidget {
  const _Photograph({required this.page, required this.clock, required this.reduce});

  final int page;
  final ValueNotifier<double> clock;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final fade = Duration(milliseconds: reduce ? 150 : 500);
    return ClipRect(
      child: ColoredBox(
        color: AppColors.navy800,
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < onboardingScenes.length; i++)
              AnimatedOpacity(
                key: Key('onboarding_background_$i'),
                opacity: i == page ? 1 : 0,
                duration: fade,
                curve: Curves.ease,
                child: Semantics(
                  label: i == page ? onboardingScenes[i].semanticDescription : null,
                  image: i == page,
                  excludeSemantics: true,
                  child: ValueListenableBuilder<double>(
                    valueListenable: clock,
                    // The design's slow zoom: 4% over 10 s and back.
                    builder: (context, t, child) => Transform.scale(
                      scale: 1 + 0.04 * _swing(t, 20),
                      alignment: const Alignment(0, -0.2),
                      child: child,
                    ),
                    child: Image.asset(
                      onboardingScenes[i].backgroundAsset,
                      fit: BoxFit.cover,
                      // object-position 50% 30%.
                      alignment: const Alignment(0, -0.4),
                      filterQuality: FilterQuality.medium,
                      // A missing plate must not show a white void behind white
                      // text. The palette's dark ink is the safe fallback.
                      errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.navy800),
                    ),
                  ),
                ),
              ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navy900.withValues(alpha: 0.55),
                      AppColors.navy900.withValues(alpha: 0),
                      AppColors.navy900.withValues(alpha: 0),
                      AppColors.navy900.withValues(alpha: 0.75),
                      AppColors.navy900,
                    ],
                    stops: const [0, 0.24, 0.52, 0.80, 0.93],
                  ),
                ),
              ),
            ),
            // Page one's ribbon along the foot of the photograph.
            Positioned(
              left: 0,
              right: 0,
              bottom: 50,
              height: 160,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: page == 0 ? 1 : 0,
                  duration: fade,
                  curve: Curves.ease,
                  child: ValueListenableBuilder<double>(
                    valueListenable: clock,
                    builder: (context, t, _) => CustomPaint(painter: OnboardingRibbonPainter(sway: -9 * _swing(t, 14))),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The header ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onSkip});

  /// Null on the final page, which removes Skip from the tree entirely — not
  /// merely fades it. A control at zero opacity is still focusable and still
  /// announced.
  final VoidCallback? onSkip;

  static final _shadow = [Shadow(color: AppColors.navy950.withValues(alpha: 0.55), blurRadius: 8, offset: const Offset(0, 1))];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          // Where the opening screen's seal lands (the shared hero tag).
          const SizedBox.square(
            dimension: 46,
            child: Hero(tag: esperanzaSealHeroTag, flightShuttleBuilder: sealFlightShuttle, child: SealBadge()),
          ),
          const SizedBox(width: 12),
          // Two lines, as the design sets it; capped at 1.5x text, beyond
          // which it read "Municipalid / ad ng Espe…" on a small phone.
          Expanded(
            child: Semantics(
              header: true,
              label: onboardingBrandName,
              excludeSemantics: true,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: wordmarkMaxTextScale,
                child: Text(
                  onboardingBrandLines,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.onboardingBrand.copyWith(color: AppColors.surface, shadows: _shadow),
                ),
              ),
            ),
          ),
          if (onSkip != null)
            TextButton(
              key: const Key('onboarding_skip'),
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.surface,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(tr('Skip'), style: AppTypography.onboardingSkip.copyWith(color: AppColors.surface, shadows: _shadow)),
            ),
        ],
      ),
    );
  }
}

// ── A page's copy ──────────────────────────────────────────────────────────

/// One page's headline, sentence and capabilities. All three are laid out in
/// one place (the design's single grid cell), so the panel keeps the height
/// of the tallest and the headline does not jump between pages; only the
/// active one is visible, touchable and announced.
class _Pane extends StatelessWidget {
  const _Pane({
    required this.scene,
    required this.index,
    required this.active,
    required this.above,
    required this.reduce,
    required this.clock,
    required this.gap,
    required this.listGap,
    required this.topGap,
    required this.tileHeight,
    required this.rowHeight,
  });

  final OnboardingSceneSpec scene;
  final int index;
  final bool active;

  /// A page already passed rises out (up); one ahead waits below.
  final bool above;
  final bool reduce;
  final ValueNotifier<double> clock;
  final double gap;
  final double listGap;
  final double topGap;
  final double tileHeight;
  final double rowHeight;

  static const _ease = Cubic(0.2, 0.8, 0.25, 1);

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: reduce ? 150 : 450);
    final offset = reduce || active ? 0.0 : (above ? -18.0 : 18.0);
    final features = scene.features;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Capped at 1.4x: at 2x a 30pt headline on a 320pt phone broke words
        // in half. The sentence below still scales fully.
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: headlineMaxTextScale,
          child: Text.rich(
            TextSpan(
              text: '${scene.headlineLead}\n',
              children: [TextSpan(text: scene.headlineAccent, style: const TextStyle(color: AppColors.gold400))],
            ),
            style: AppTypography.onboardingHeadline.copyWith(color: AppColors.surface),
          ),
        ),
        SizedBox(height: gap),
        Text(scene.subtext, style: AppTypography.onboardingBody.copyWith(color: AppColors.slate300)),
        SizedBox(height: gap + topGap),
        if (index == 0)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < features.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _RiseIn(
                      active: active,
                      order: i,
                      reduce: reduce,
                      child: _Tile(feature: features[i], order: i, minHeight: tileHeight, clock: clock),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) SizedBox(height: listGap),
            _RiseIn(
              active: active,
              order: i,
              reduce: reduce,
              child: _RowCard(feature: features[i], order: i, minHeight: rowHeight, clock: clock),
            ),
          ],
      ],
    );

    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: duration,
          curve: Curves.ease,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: offset),
            duration: duration,
            curve: _ease,
            builder: (context, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
            child: Semantics(liveRegion: active, child: content),
          ),
        ),
      ),
    );
  }
}

/// A card rising into place after its page arrives, one after another
/// (the design's 0.12 / 0.2 / 0.28 s).
class _RiseIn extends StatefulWidget {
  const _RiseIn({required this.active, required this.order, required this.reduce, required this.child});

  final bool active;
  final int order;
  final bool reduce;
  final Widget child;

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  static const _rise = 350;

  int get _delay => widget.reduce ? 0 : 120 + 80 * widget.order;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _delay + _rise),
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(_RiseIn old) {
    super.didUpdateWidget(old);
    _c.duration = Duration(milliseconds: _delay + (widget.reduce ? 150 : _rise));
    if (widget.active && !old.active) _c.forward(from: 0);
    if (!widget.active && old.active) _c.value = 0;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final total = _delay + (widget.reduce ? 150 : _rise);
        final t = Interval(_delay / total, 1, curve: const Cubic(0.2, 0.8, 0.25, 1)).transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, widget.reduce ? 0 : 10 * (1 - t)), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// The card's own surface: translucent navy with a faint white edge.
BoxDecoration _cardSurface(double radius) => BoxDecoration(
      color: AppColors.navy700.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.surface.withValues(alpha: 0.14)),
    );

/// Page one: an icon in its own square over a centred label.
class _Tile extends StatelessWidget {
  const _Tile({required this.feature, required this.order, required this.minHeight, required this.clock});

  final OnboardingFeature feature;
  final int order;
  final double minHeight;
  final ValueNotifier<double> clock;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: _cardSurface(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Moving(
            motion: feature.motion,
            order: order,
            clock: clock,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.navy900.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface.withValues(alpha: 0.1)),
              ),
              child: Icon(feature.icon, size: 26, color: AppColors.gold400),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            feature.label,
            textAlign: TextAlign.center,
            style: AppTypography.onboardingTile.copyWith(color: AppColors.surface),
          ),
        ],
      ),
    );
  }
}

/// Pages two and three: an icon and a label in a row.
class _RowCard extends StatelessWidget {
  const _RowCard({required this.feature, required this.order, required this.minHeight, required this.clock});

  final OnboardingFeature feature;
  final int order;
  final double minHeight;
  final ValueNotifier<double> clock;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: _cardSurface(16),
      child: Row(
        children: [
          _Moving(
            motion: feature.motion,
            order: order,
            clock: clock,
            child: Icon(feature.icon, size: 24, color: AppColors.gold400),
          ),
          const SizedBox(width: 16),
          Flexible(child: Text(feature.label, style: AppTypography.onboardingRow.copyWith(color: AppColors.surface))),
        ],
      ),
    );
  }
}

/// An icon's own small motion: a bob (offset by its place in the row), the
/// bell's swing, the megaphone's wobble, or a ring pulsing out of the shield.
class _Moving extends StatelessWidget {
  const _Moving({required this.motion, required this.order, required this.clock, required this.child});

  final FeatureMotion motion;
  final int order;
  final ValueNotifier<double> clock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: clock,
      child: child,
      builder: (context, t, child) {
        switch (motion) {
          case FeatureMotion.bob:
            return Transform.translate(offset: Offset(0, -3 * _swing(t, 3.4, delay: 0.6 * order)), child: child);
          case FeatureMotion.swing:
            final deg = _keyframes(t, 3.2, const [0, 0.15, 0.30, 0.45, 0.60, 0.75, 1], const [0, 14, -11, 7, -4, 0, 0]);
            return Transform.rotate(angle: deg * math.pi / 180, alignment: const Alignment(0, -0.76), child: child);
          case FeatureMotion.wobble:
            final deg = _keyframes(t, 3, const [0, 0.25, 0.5, 0.75, 1], const [0, -7, 0, 6, 0]);
            return Transform.rotate(angle: deg * math.pi / 180, alignment: const Alignment(-0.4, 0.2), child: child);
          case FeatureMotion.pulse:
            final p = t <= 0 ? 0.0 : Curves.easeOut.transform((t % 2.2) / 2.2);
            // The ring floats over the icon (4 beyond it all round) and takes
            // no room of its own, so the row keeps its height.
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (t > 0)
                  Positioned(
                    left: -4,
                    top: -4,
                    right: -4,
                    bottom: -4,
                    child: Transform.scale(
                      scale: 0.9 + p,
                      child: Opacity(
                        opacity: 0.75 * (1 - p),
                        child: DecoratedBox(
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold400, width: 2)),
                        ),
                      ),
                    ),
                  ),
                child!,
              ],
            );
        }
      },
    );
  }
}

// ── The dots ───────────────────────────────────────────────────────────────

class _Dots extends StatelessWidget {
  const _Dots({super.key, required this.page, required this.count, required this.reduce, required this.onSelect});

  final int page;
  final int count;
  final bool reduce;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: reduce ? 150 : 350);
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Page ${page + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            // 22 apart, as the design's 12px dots with 10 between; each one
            // a 44pt-tall target.
            Semantics(
              button: true,
              selected: i == page,
              label: 'Go to page ${i + 1} of $count',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: SizedBox(
                  width: 22,
                  height: 44,
                  child: Center(
                    child: AnimatedScale(
                      scale: i == page ? 1 : 0.84,
                      duration: duration,
                      curve: const Cubic(0.2, 0.8, 0.25, 1),
                      child: AnimatedContainer(
                        duration: duration,
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: i == page ? AppColors.gold400 : AppColors.navy600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
