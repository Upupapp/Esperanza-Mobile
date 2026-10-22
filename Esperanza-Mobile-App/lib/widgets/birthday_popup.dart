import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/ambient_motion.dart';

import '../l10n/tr.dart';
/// The birthday pop-up over Home, after the owner's design (canvas "Balita
/// Birthday Theme", artboard "Birthday pop-up (login / after splash)",
/// 2026-10-16): a cake with lit candles, confetti falling over the page, and
/// "Happy birthday" from the Municipality.
///
/// Since 2026-10-21 the server decides when it shows (owner decision): on
/// the resident's birthday GET /citizen/popups/active sends a pop-up marked
/// `birthday`, once a year, and [OccasionGreetingPopup] draws it in this
/// design with the server's own title, message and picture. The phone no
/// longer works out the birthday for the pop-up; the private Balita card
/// still does.
class BirthdayPopup extends StatefulWidget {
  const BirthdayPopup({
    super.key,
    required this.title,
    this.message = '',
    this.imageUrl,
    this.imageAlt,
    this.onDontShowAgain,
  });

  /// "Happy birthday, Juan!", as the server wrote it.
  final String title;

  /// The server's wish; the Municipality's own when it sent none.
  final String message;

  /// A picture in place of the cake, when the server sends one.
  final String? imageUrl;
  final String? imageAlt;

  /// Offers "Huwag nang ipakita" when set.
  final VoidCallback? onDontShowAgain;

  static const transitionDuration = Duration(milliseconds: 550);

  /// The card pops up a beat after the scrim, overshooting a touch.
  static Widget transition(BuildContext context, Animation<double> animation, Animation<double> _, Widget child) {
    final pop = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.18, 1, curve: Cubic(0.2, 0.9, 0.3, 1.15)),
    );
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: const Interval(0.18, 0.7)),
      child: AnimatedBuilder(
        animation: pop,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 24 * (1 - pop.value)),
          child: Transform.scale(scale: 0.92 + 0.08 * pop.value, child: child),
        ),
        child: child,
      ),
    );
  }

  @override
  State<BirthdayPopup> createState() => _BirthdayPopupState();
}

/// "Huwag nang ipakita" (don't show this again), the quiet last action of a
/// pop-up the server marks dismissible. A full-size target.
class DontShowAgainButton extends StatelessWidget {
  const DontShowAgainButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppSizes.minTouchTarget),
        foregroundColor: AppColors.textMuted,
        textStyle: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600),
      ),
      child: const Text('Huwag nang ipakita', semanticsLabel: "Huwag nang ipakita. Don't show again"),
    );
  }
}

class _BirthdayPopupState extends State<BirthdayPopup> with TickerProviderStateMixin {
  // The confetti inside the card drifting in.
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))
    ..forward();
  // Confetti falling over the page, once.
  late final AnimationController _rain = AnimationController(vsync: this, duration: _ConfettiRain.length);
  // Candle flames and twinkling confetti: endless, so ambient motion only.
  late final AnimationController _loop = AnimationController(vsync: this, duration: _loopLength);

  static const _loopLength = Duration(milliseconds: 26400); // 1.1 s × 24 = 2.4 s × 11

  bool _motionStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_motionStarted && AmbientMotion.of(context)) {
      _motionStarted = true;
      _rain.forward();
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _rain.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final message = widget.message.trim().isEmpty
        ? 'The Municipality of Esperanza wishes you good health, happiness and a wonderful year ahead.'
        : widget.message.trim();
    final image = widget.imageUrl;
    final size = MediaQuery.sizeOf(context);
    final width = math.min(296.0, size.width - 2 * AppSpacing.xxl);
    double seconds() => _loop.value * _loopLength.inMilliseconds / 1000;
    final cake = ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) => CustomPaint(
          size: const Size(168, 148),
          painter: _Cake(seconds: _motionStarted ? seconds() : null),
        ),
      ),
    );

    return Stack(
      children: [
        if (_motionStarted)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: RepaintBoundary(child: CustomPaint(painter: _ConfettiRain(_rain))),
              ),
            ),
          ),
        Center(
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: width,
                constraints: BoxConstraints(maxHeight: size.height * 0.86),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy950.withValues(alpha: 0.35),
                      blurRadius: 60,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The cake (or the server's picture) on a warm
                          // glow, with confetti around the cake.
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              26,
                              AppSpacing.xl,
                              image == null ? 2 : AppSpacing.sm,
                            ),
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(0, 0.3),
                                radius: 0.85,
                                colors: [AppColors.gold100, AppColors.gold50, AppColors.surface],
                                stops: [0, 0.45, 0.8],
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                if (image == null) ...[
                                  Positioned.fill(
                                    left: -AppSpacing.xl,
                                    right: -AppSpacing.xl,
                                    top: -26,
                                    child: ExcludeSemantics(
                                      child: AnimatedBuilder(
                                        animation: Listenable.merge([_intro, _loop]),
                                        builder: (context, _) => CustomPaint(
                                          painter: _CardConfetti(
                                            arrive: const Interval(
                                              0.3,
                                              1,
                                              curve: Curves.easeOut,
                                            ).transform(_intro.value),
                                            seconds: _motionStarted ? seconds() : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  cake,
                                ] else
                                  // The picture whole, never cropped.
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: size.height * 0.36),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      child: Image.network(
                                        image,
                                        fit: BoxFit.contain,
                                        semanticLabel: widget.imageAlt ?? title,
                                        errorBuilder: (_, _, _) => cake,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, AppSpacing.sm, 22, 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'MALIGAYANG KAARAWAN',
                                  textAlign: TextAlign.center,
                                  semanticsLabel: 'Maligayang kaarawan',
                                  style: TextStyle(
                                    fontSize: AppTextSize.label,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: AppColors.gold700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: AppTextSize.section,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy900,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: AppTextSize.body,
                                    height: 1.5,
                                    color: AppColors.slate600,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _SalamatButton(onPressed: _close),
                                if (widget.onDontShowAgain case final dontShowAgain?)
                                  DontShowAgainButton(onPressed: dontShowAgain),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: IconButton(
                        onPressed: _close,
                        tooltip: tr('Close'),
                        constraints: const BoxConstraints.tightFor(
                          width: AppSizes.minTouchTarget,
                          height: AppSizes.minTouchTarget,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.slate600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SalamatButton extends StatelessWidget {
  const _SalamatButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gold300, AppColors.gold500],
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: const SizedBox(
              height: AppSizes.buttonHeightLg,
              child: Center(
                child: Text(
                  'Salamat!',
                  style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.navy900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confetti falling down the whole screen behind the card, once.
class _ConfettiRain extends CustomPainter {
  _ConfettiRain(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const length = Duration(milliseconds: 6500);

  // (left, width, height, round, colour, alpha, seconds, delay, path)
  static const _pieces = [
    (0.06, 8.0, 14.0, false, AppColors.gold400, 1.0, 3.6, 0.3, _Fall.left),
    (0.13, 8.0, 8.0, true, AppColors.surface, 1.0, 4.2, 0.6, _Fall.wave),
    (0.20, 6.0, 12.0, false, AppColors.rose500, 0.6, 3.4, 0.45, _Fall.right),
    (0.27, 9.0, 9.0, false, AppColors.brand400, 1.0, 4.0, 0.9, _Fall.left),
    (0.34, 7.0, 13.0, false, AppColors.gold500, 1.0, 3.8, 0.35, _Fall.wave),
    (0.41, 7.0, 7.0, true, AppColors.gold400, 1.0, 3.5, 1.1, _Fall.right),
    (0.48, 6.0, 12.0, false, AppColors.surface, 1.0, 4.3, 0.5, _Fall.left),
    (0.55, 8.0, 14.0, false, AppColors.rose500, 0.6, 3.7, 0.8, _Fall.wave),
    (0.62, 9.0, 9.0, false, AppColors.gold400, 1.0, 3.3, 0.4, _Fall.right),
    (0.69, 7.0, 7.0, true, AppColors.brand400, 1.0, 4.1, 1.0, _Fall.left),
    (0.76, 6.0, 12.0, false, AppColors.surface, 1.0, 3.6, 0.55, _Fall.wave),
    (0.83, 8.0, 14.0, false, AppColors.gold500, 1.0, 3.9, 0.7, _Fall.right),
    (0.90, 8.0, 8.0, true, AppColors.gold400, 1.0, 3.5, 0.35, _Fall.left),
    (0.10, 6.0, 11.0, false, AppColors.gold400, 1.0, 4.4, 1.6, _Fall.wave),
    (0.24, 7.0, 7.0, true, AppColors.surface, 1.0, 3.8, 1.9, _Fall.right),
    (0.38, 8.0, 13.0, false, AppColors.brand400, 1.0, 4.0, 1.5, _Fall.left),
    (0.52, 7.0, 7.0, false, AppColors.gold400, 1.0, 3.6, 2.0, _Fall.wave),
    (0.66, 6.0, 12.0, false, AppColors.rose500, 0.6, 4.2, 1.7, _Fall.right),
    (0.80, 8.0, 8.0, true, AppColors.gold500, 1.0, 3.7, 1.8, _Fall.left),
    (0.94, 6.0, 12.0, false, AppColors.surface, 1.0, 4.1, 1.55, _Fall.wave),
  ];

  static const _ease = Cubic(0.35, 0.1, 0.6, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final now = animation.value * length.inMilliseconds / 1000;
    for (final (left, w, h, round, colour, alpha, seconds, delay, path) in _pieces) {
      final t = (now - delay) / seconds;
      if (t <= 0 || t >= 1) continue;
      final (dx, turn, flip) = path.at(t, _ease);
      final y = -40 + (size.height + 96) * (path == _Fall.wave ? t : _segmented(t));
      final opacity = math.min(1.0, t / 0.06) * alpha;
      canvas.save();
      canvas.translate(size.width * left + dx + w / 2, y + h / 2);
      canvas.rotate(turn);
      // The 3D tumble, as a squash along one axis.
      final squash = math.cos(flip).abs().clamp(0.15, 1.0);
      canvas.scale(path == _Fall.right ? squash : 1, path == _Fall.left ? squash : 1);
      final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      final paint = Paint()..color = colour.withValues(alpha: opacity);
      if (round) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  // The left and right falls ease each half separately, like the design.
  static double _segmented(double t) =>
      t < 0.5 ? 0.5 * _ease.transform(t / 0.5) : 0.5 + 0.5 * _ease.transform((t - 0.5) / 0.5);

  @override
  bool shouldRepaint(_ConfettiRain old) => false;
}

enum _Fall {
  left,
  right,
  wave;

  /// Sideways drift, turn and tumble (radians) at [t] (0..1) of the fall.
  (double, double, double) at(double t, Curve ease) {
    const rad = math.pi / 180;
    switch (this) {
      case _Fall.left || _Fall.right:
        // Two legs, each eased: out to one side, then back across.
        final (drift, turns) = this == _Fall.left
            ? ([0.0, -26.0, 8.0], [0.0, 220.0, 460.0])
            : ([0.0, 28.0, -10.0], [0.0, -200.0, -420.0]);
        final leg = t < 0.5 ? 0 : 1;
        final u = ease.transform(t < 0.5 ? t / 0.5 : (t - 0.5) / 0.5);
        double along(List<double> keys) => keys[leg] + (keys[leg + 1] - keys[leg]) * u;
        return (along(drift), along(turns) * rad, 360 * (leg + u) * rad);
      case _Fall.wave:
        // Side to side: 0, 14, -14, 14, 0 at each quarter, evenly.
        const sway = [0.0, 14.0, -14.0, 14.0, 0.0];
        final q = (t * 4).clamp(0.0, 3.999);
        final i = q.floor();
        return (sway[i] + (sway[i + 1] - sway[i]) * (q - i), 480 * t * rad, 0);
    }
  }
}

/// The confetti dots around the cake, drifting in and then twinkling.
class _CardConfetti extends CustomPainter {
  _CardConfetti({required this.arrive, required this.seconds});

  final double arrive;
  final double? seconds;

  // (from left?, x, top, width, height, colour, alpha, turn in degrees)
  static const _dots = [
    (true, 30.0, 26.0, 7.0, 7.0, AppColors.gold400, 1.0, 0.0),
    (true, 70.0, 62.0, 4.0, 11.0, AppColors.brand400, 0.6, 30.0),
    (true, 112.0, 20.0, 5.0, 5.0, AppColors.rose500, 0.6, 0.0),
    (false, 112.0, 30.0, 4.0, 10.0, AppColors.gold400, 1.0, -24.0),
    (false, 66.0, 64.0, 6.0, 6.0, AppColors.brand400, 0.55, 0.0),
    (false, 34.0, 92.0, 4.0, 10.0, AppColors.gold400, 1.0, 16.0),
    (true, 40.0, 96.0, 5.0, 5.0, AppColors.gold400, 0.8, 0.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _dots.length; i++) {
      final (fromLeft, x, top, w, h, colour, alpha, turn) = _dots[i];
      var twinkle = 1.0;
      if (seconds case final s?) {
        final phase = ((s + (i.isOdd ? 1.2 : 0)) % 2.4) / 2.4;
        twinkle = 1 - 0.65 * (0.5 - 0.5 * math.cos(phase * 2 * math.pi));
      }
      final left = fromLeft ? x : size.width - x - w;
      canvas.save();
      canvas.translate(left + w / 2, top + h / 2 - 8 * (1 - arrive));
      canvas.rotate(turn * math.pi / 180);
      final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      final paint = Paint()..color = colour.withValues(alpha: alpha * arrive * twinkle);
      if (w == h) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CardConfetti old) => old.arrive != arrive || old.seconds != seconds;
}

/// The two-tier cake with three lit candles, drawn from the design's own
/// 160 × 140 drawing.
class _Cake extends CustomPainter {
  _Cake({required this.seconds});

  /// Seconds into the ambient loop, for the flames; null holds them still.
  final double? seconds;

  static final _pink = AppColors.rose500.withValues(alpha: 0.28);
  static final _pinkDeep = AppColors.rose500.withValues(alpha: 0.55);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 160;
    canvas.save();
    canvas.scale(k, size.height / 140);
    Paint fill(Color c) => Paint()..color = c;
    final white = AppColors.surface;

    // Plate.
    canvas.drawOval(Rect.fromCenter(center: const Offset(80, 127), width: 136, height: 18), fill(AppColors.slate300));
    final plate = Rect.fromCenter(center: const Offset(80, 124), width: 128, height: 15);
    canvas.drawOval(plate, fill(white));
    canvas.drawOval(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.slate200,
    );

    // Bottom tier.
    canvas.drawRRect(RRect.fromLTRBR(24, 80, 136, 124, const Radius.circular(10)), fill(white));
    canvas.drawRRect(RRect.fromLTRBR(24, 80, 136, 124, const Radius.circular(10)), fill(_pink));
    canvas.drawRect(const Rect.fromLTWH(24, 110, 112, 5), fill(_pinkDeep));
    canvas.drawPath(
      _drips(24, 136, 80, 90, 93, const [
        (131, 100, 127),
        (122, 104, 116),
        (111, 98, 105),
        (99, 106, 93),
        (88, 98, 82),
        (76, 104, 70),
        (65, 98, 59),
        (53, 103, 47),
        (42, 98, 37),
        (31, 102, 28),
        (26, 96, 24),
      ]),
      fill(white),
    );
    for (final (x, y, deg, colour) in [
      (38.0, 104.0, -25.0, AppColors.brand400),
      (58.0, 112.0, 30.0, AppColors.gold400),
      (86.0, 104.0, -15.0, white),
      (106.0, 113.0, 20.0, AppColors.brand400),
      (120.0, 102.0, -35.0, AppColors.gold400),
    ]) {
      canvas.save();
      canvas.translate(x + 3, y + 1.25);
      canvas.rotate(deg * math.pi / 180);
      canvas.drawRRect(RRect.fromLTRBR(-3, -1.25, 3, 1.25, const Radius.circular(1.2)), fill(colour));
      canvas.restore();
    }

    // Top tier.
    canvas.drawRRect(RRect.fromLTRBR(40, 46, 120, 84, const Radius.circular(9)), fill(AppColors.gold200));
    canvas.drawRect(const Rect.fromLTWH(40, 72, 80, 4), fill(AppColors.gold500.withValues(alpha: 0.55)));
    canvas.drawPath(
      _drips(40, 120, 46, 55, 58, const [
        (116, 64, 112),
        (108, 68, 104),
        (99, 62, 94),
        (89, 70, 84),
        (79, 62, 74),
        (69, 66, 64),
        (59, 62, 54),
        (49, 68, 46),
        (43, 62, 40),
      ]),
      fill(white),
    );
    for (final x in const [52.0, 80.0, 108.0]) {
      canvas.drawCircle(Offset(x, 68), 2.6, fill(AppColors.rose500));
    }
    // Shine.
    canvas.drawRRect(RRect.fromLTRBR(27, 83, 32, 113, const Radius.circular(2.5)), fill(white.withValues(alpha: 0.35)));
    canvas.drawRRect(RRect.fromLTRBR(43, 49, 47, 73, const Radius.circular(2)), fill(white.withValues(alpha: 0.4)));

    // Candles.
    canvas.drawRRect(RRect.fromLTRBR(63, 26, 69, 48, const Radius.circular(2)), fill(AppColors.brand400));
    canvas.drawRRect(RRect.fromLTRBR(77, 24, 83, 48, const Radius.circular(2)), fill(AppColors.gold400));
    canvas.drawRRect(RRect.fromLTRBR(91, 26, 97, 48, const Radius.circular(2)), fill(white));
    canvas.drawRRect(RRect.fromLTRBR(91, 26, 97, 48, const Radius.circular(2)), fill(_pinkDeep));
    final stripe = Paint()
      ..color = white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    for (final x in const [63.0, 77.0, 91.0]) {
      final lift = x == 77 ? -1.0 : 0.0;
      for (final y in const [31.0, 37.0, 43.0]) {
        canvas.drawLine(Offset(x, y + lift), Offset(x + 6, y - 2 + lift), stripe);
      }
    }

    // Flames, flickering one after another.
    for (final (i, x, base) in const [(0, 66.0, 24.0), (1, 80.0, 22.0), (2, 94.0, 24.0)]) {
      canvas.save();
      canvas.translate(x, base);
      if (seconds case final s?) {
        final (sx, sy, deg) = _flicker(((s - i * 0.35) % 1.1) / 1.1);
        canvas.rotate(deg * math.pi / 180);
        canvas.scale(sx, sy);
      }
      // Drawn with the flame's foot at the origin.
      final outer = Path()
        ..moveTo(0, -14)
        ..cubicTo(5, -9, 5, -3, 0, 0)
        ..cubicTo(-5, -3, -5, -9, 0, -14)
        ..close();
      final inner = Path()
        ..moveTo(0, -9)
        ..cubicTo(2, -6, 2, -3, 0, -1.5)
        ..cubicTo(-2, -3, -2, -6, 0, -9)
        ..close();
      canvas.drawPath(outer, fill(AppColors.amber500));
      canvas.drawPath(inner, fill(AppColors.gold200));
      canvas.restore();
    }
    canvas.restore();
  }

  /// The frosting: a rounded top that ends in drips along [dripY].
  static Path _drips(double l, double r, double top, double shoulder, double dripY, List<(double, double, double)> qs) {
    final p = Path()
      ..moveTo(l, shoulder)
      ..quadraticBezierTo(l, top, l + (shoulder - top), top)
      ..lineTo(r - (shoulder - top), top)
      ..quadraticBezierTo(r, top, r, shoulder)
      ..lineTo(r, dripY);
    for (final (cx, cy, x) in qs) {
      p.quadraticBezierTo(cx, cy, x, dripY);
    }
    return p..close();
  }

  /// scale x, scale y, turn, at [t] (0..1) of one flicker.
  static (double, double, double) _flicker(double t) {
    const keys = [(1.0, 1.0, 0.0), (0.92, 1.08, -4.0), (1.05, 0.94, 3.0), (0.96, 1.05, -2.0), (1.0, 1.0, 0.0)];
    final pos = t * 4;
    final i = pos.floor().clamp(0, 3);
    final u = Curves.easeInOut.transform(pos - i);
    final (ax, ay, ad) = keys[i];
    final (bx, by, bd) = keys[i + 1];
    return (ax + (bx - ax) * u, ay + (by - ay) * u, ad + (bd - ad) * u);
  }

  @override
  bool shouldRepaint(_Cake old) => old.seconds != seconds;
}
