import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/esperanza_art.dart';
import '../../utils/fade_page_route.dart';
import '../onboarding/onboarding_screen.dart';

/// The every-launch opening animation — distinct from the one-time
/// [OnboardingScreen] flow. The painted Esperanza scene (sun, hills, the
/// municipal hall, the gold ribbon; see esperanza_art.dart): one
/// [AnimationController] grows the sun's rays in, then fades the
/// "Esperanza Mobile" wordmark and tagline in — simple opacity and a very
/// subtle scale, using only Flutter's built-in animation classes.
///
/// Total time on screen — animation plus a short hold so the finished
/// branding is actually visible before handing off — lands around 1.9s,
/// within the "don't make users wait" target.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // The full ~1.9s on-screen time — fade-in plus a still hold at the end
  // so the finished branding is actually visible before handing off — all
  // lives on one AnimationController/Ticker rather than a separate
  // Future.delayed hold tacked on afterwards. A raw Timer isn't tied to
  // the frame scheduler, so widget-test `pumpAndSettle()` (which only
  // waits out scheduled frames/tickers, not arbitrary timers) would
  // consider the app "settled" and return while that timer was still
  // pending, permanently stranding every test that pumps the app on this
  // screen. Folding the hold into the controller's own duration keeps it
  // tied to the ticker pumpAndSettle already knows how to wait for.
  static const _animationDuration = Duration(milliseconds: 1900);

  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration);
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.46, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.46, curve: Curves.easeOutCubic),
      ),
    );
    // Starts once the logo is most of the way in, rather than waiting for
    // it to fully finish — reads as one connected sequence instead of two
    // separate beats. Finishes at 0.76, leaving the last ~24% of the
    // duration as a still hold with the finished branding fully visible.
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.76, curve: Curves.easeOut),
    );
    _run();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    await _controller.forward();
    if (!mounted) return;

    // Defence in depth: `_run()` is started from initState and never awaited,
    // so anything that escapes here strands the citizen on the splash with no
    // way forward. OnboardingService.isComplete() is itself guarded; this keeps
    // the invariant true for whatever else lands in this method later.
    var onboardingDone = false;
    try {
      onboardingDone = await OnboardingService.isComplete();
    } catch (_) {
      // Show onboarding rather than not navigating at all.
    }
    if (!mounted) return;

    // pushReplacement (never push) — the branding fades into whichever
    // screen comes next while keeping exactly one route on the stack, so
    // that screen becomes the new *root* route. See AuthGate's doc
    // comment in main.dart for why that invariant matters.
    Navigator.of(context).pushReplacement(fadePageRoute(onboardingDone ? const AuthGate() : const OnboardingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // The design's opening scene (2026-10): navy sky, a gold sun whose rays
    // grow in, the municipal hall in clay on its hill and the gold ribbon,
    // with the wordmark and tagline fading in between sun and hall.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      backgroundColor: AppColors.navy950,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: EsperanzaScenePainter(
                  sun: 0.17,
                  ground: 0.80,
                  hallWidth: 0.64,
                  progress: _logoOpacity.value,
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: const Alignment(0, -0.18),
                  child: Opacity(
                    opacity: _titleOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Esperanza Mobile',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.display,
                                fontSize: AppTextSize.display,
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface,
                                height: 1.1,
                                shadows: [Shadow(color: AppColors.navy950, blurRadius: 18)],
                              ),
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Your Gateway to a Brighter Community',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: AppTextSize.body, color: AppColors.slate200, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
