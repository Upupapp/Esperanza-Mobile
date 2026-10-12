import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/fade_page_route.dart';
import '../../widgets/opening_waves.dart';
import '../../widgets/seal_badge.dart';
import '../onboarding/onboarding_screen.dart';

/// The every-launch opening. It leads into the [OnboardingScreen] welcome
/// pages whenever no one is signed in (owner, 2026-10-12: they used to show
/// once per phone, and never again after the first launch), and straight to
/// [AuthGate] when someone is.
///
/// The owner's design ("Esperanza Onboarding Prototype", screen 1,
/// 2026-10-12): the municipal seal on navy, drawn in by two gold rings with a
/// point of light orbiting each, a gold glow behind it, the wave artwork
/// across the lower third, and a loading bar with "Loading Esperanza...".
/// The Android launch window shows the same seal on the same navy, so the
/// hand-off from the system to this screen does not jump.
///
/// One [AnimationController] carries the whole 2.7 s, its hold included, and
/// every element reads its own slice of it (the design's timings, in ms). A
/// raw `Timer` for the hold would not be tied to the frame scheduler, and a
/// widget test's `pumpAndSettle` would return while it was still pending,
/// stranding every test that starts the app here.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _full = 2700;

  /// Under reduce motion: everything shown at once, held briefly.
  static const _reducedHold = Duration(milliseconds: 1200);

  late final AnimationController _controller = AnimationController(vsync: this);
  bool _started = false;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.disableAnimationsOf(context);
    _controller.duration = _reduced ? _reducedHold : const Duration(milliseconds: _full);
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

    // Whether anyone is signed in: the saved session is read as the app
    // starts, and is almost always ready by now. Defence in depth: `_run()` is
    // never awaited, so anything that escapes here strands the citizen on the
    // splash with no way forward; on any trouble, the welcome pages show.
    var signedIn = false;
    try {
      final session = context.read<CitizenSessionService>();
      if (session.loading) {
        final loaded = Completer<void>();
        void check() {
          if (!session.loading && !loaded.isCompleted) loaded.complete();
        }

        session.addListener(check);
        await loaded.future.timeout(const Duration(seconds: 10), onTimeout: () {});
        session.removeListener(check);
      }
      signedIn = session.isSignedIn;
    } catch (_) {
      // Show the welcome pages rather than not navigating at all.
    }
    if (!mounted) return;

    // pushReplacement (never push): the next screen becomes the new *root*
    // route. See AuthGate's doc comment in main.dart for why that matters.
    //
    // Into the welcome pages the seal stays on screen and flies into the
    // header's (the shared hero tag), so that hand-off is slower — long
    // enough to see it travel.
    final reduce = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).pushReplacement(
      signedIn
          ? fadePageRoute(const AuthGate())
          : fadePageRoute(const OnboardingScreen(), duration: Duration(milliseconds: reduce ? 200 : 800)),
    );
  }

  /// This element's progress through its own slice of the timeline, from
  /// [startMs] to [endMs] — all the way through under reduce motion.
  double _slice(int startMs, int endMs, [Curve curve = Curves.linear]) {
    if (_reduced) return 1;
    final t = ((_controller.value * _full - startMs) / (endMs - startMs)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  static const _rise = Cubic(0.2, 0.8, 0.25, 1);
  static const _draw = Cubic(0.4, 0, 0.2, 1);
  static const _orbit = Cubic(0.45, 0.05, 0.55, 0.95);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // The design's seal group is 340 square on a 390x844 phone; a short or
    // narrow screen (landscape, a 320pt phone) gets it scaled down.
    final scale = math.min(1.0, math.min(screen.height / 844, screen.width / 360)).clamp(0.55, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy900,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final seal = _slice(0, 600, _rise);
            final orbA = _slice(1050, 2200, _orbit);
            final orbB = _slice(1150, 2300, _orbit);
            return Stack(
              fit: StackFit.expand,
              children: [
                // The waves drift 8px over 12s in the design; the splash is
                // gone long before, so this is its first 2.7s.
                CustomPaint(painter: SplashWavesPainter(drift: _reduced ? 0 : -1.8 * _controller.value)),
                Align(
                  // The group's centre sits 40 above the screen's.
                  alignment: Alignment(0, -80 / screen.height),
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox.square(
                      dimension: 340,
                      child: OverflowBox(
                        maxWidth: 360,
                        maxHeight: 360,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Opacity(
                              opacity: _slice(500, 1700, Curves.ease),
                              child: Container(
                                width: 360,
                                height: 360,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.gold400.withValues(alpha: 0.34),
                                      AppColors.gold400.withValues(alpha: 0.12),
                                      AppColors.gold400.withValues(alpha: 0),
                                    ],
                                    stops: const [0, 0.38, 0.64],
                                  ),
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: const Size.square(340),
                              painter: _SealRingsPainter(
                                inner: _slice(350, 1050, _draw),
                                outer: _slice(500, 1400, _draw),
                                orbitA: _reduced ? 240 : orbA * 600,
                                orbitB: _reduced ? 30 : 30 + orbB * 360,
                                orbAOpacity: _reduced ? 1 : _slice(1050, 1165),
                                orbBOpacity: _reduced ? 1 : _slice(1150, 1265),
                              ),
                            ),
                            Opacity(
                              opacity: seal,
                              // Announced from the first frame, not once it
                              // has faded in.
                              alwaysIncludeSemantics: true,
                              child: Transform.scale(
                                scale: 0.92 + 0.08 * seal,
                                child: const SizedBox.square(
                                  dimension: 196,
                                  // Flies into the welcome pages' header.
                                  child: Hero(
                                    tag: esperanzaSealHeroTag,
                                    flightShuttleBuilder: sealFlightShuttle,
                                    child: SealBadge(shadow: 1, semanticLabel: 'Official seal of the Municipality of Esperanza'),
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 118 * scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 180,
                        height: 4,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(color: AppColors.navy700, borderRadius: BorderRadius.circular(2)),
                        child: FractionallySizedBox(
                          widthFactor: _slice(100, 2400),
                          child: Container(
                            decoration: BoxDecoration(color: AppColors.gold400, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Loading Esperanza...', style: AppTypography.splashStatus.copyWith(color: AppColors.slate300)),
                    ],
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

/// The two gold rings that draw themselves round the seal, each with a point
/// of light travelling along it.
class _SealRingsPainter extends CustomPainter {
  /// How much of each ring is drawn, 0 to 1, clockwise from the top.
  final double inner;
  final double outer;

  /// Each light's angle in degrees, clockwise from the top.
  final double orbitA;
  final double orbitB;
  final double orbAOpacity;
  final double orbBOpacity;

  const _SealRingsPainter({
    required this.inner,
    required this.outer,
    required this.orbitA,
    required this.orbitB,
    required this.orbAOpacity,
    required this.orbBOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    Paint ring(double alpha, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = AppColors.gold400.withValues(alpha: alpha);

    canvas.drawCircle(c, 158, ring(0.18, 1));
    if (outer > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: 158), -math.pi / 2, 2 * math.pi * outer, false, ring(0.6, 1.2));
    }
    if (inner > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: 118), -math.pi / 2, 2 * math.pi * inner, false, ring(1, 1.6));
    }

    void light(double degrees, double radius, double dot, double opacity) {
      if (opacity <= 0) return;
      final a = degrees * math.pi / 180;
      final p = c + Offset(math.sin(a), -math.cos(a)) * radius;
      canvas.drawCircle(
        p,
        dot * 1.6,
        Paint()
          ..color = AppColors.gold400.withValues(alpha: 0.35 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        p,
        dot,
        Paint()
          ..color = AppColors.gold300.withValues(alpha: 0.85 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(p, dot / 2, Paint()..color = AppColors.gold200.withValues(alpha: opacity));
    }

    light(orbitA, 118, 10, orbAOpacity);
    light(orbitB, 158, 8, orbBOpacity);
  }

  @override
  bool shouldRepaint(_SealRingsPainter old) =>
      old.inner != inner ||
      old.outer != outer ||
      old.orbitA != orbitA ||
      old.orbitB != orbitB ||
      old.orbAOpacity != orbAOpacity ||
      old.orbBOpacity != orbBOpacity;
}
