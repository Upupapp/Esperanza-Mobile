import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// The wave artwork of the opening screens, drawn from the owner's design
/// ("Esperanza Onboarding Prototype", 2026-10-12) path for path: a blue swoosh,
/// a soft gold sweep and a navy band, on the splash and under page one's
/// photograph. The design's colours are mapped to the nearest [AppColors]
/// token (CLAUDE.md: never a colour outside that set).

/// A path's own box, which is what an SVG gradient spans by default
/// (`objectBoundingBox`).
Shader _across(Path p, List<Color> colors, List<double> stops) =>
    LinearGradient(colors: colors, stops: stops).createShader(p.getBounds());

Shader _down(Path p, List<Color> colors, List<double> stops) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: stops,
    ).createShader(p.getBounds());

Paint _stroke(Color c, double width, {double blur = 0}) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..color = c;
  if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  return paint;
}

/// The splash's background: a dark crescent at the top, three faint rings
/// round the seal, and the wave across the lower third. Drawn in the design's
/// 390x844 frame and scaled to cover the screen (`xMidYMid slice`).
class SplashWavesPainter extends CustomPainter {
  /// The slow sideways drift, in logical pixels (0 to -8).
  final double drift;

  const SplashWavesPainter({this.drift = 0});

  @override
  void paint(Canvas canvas, Size size) {
    // The design's SVG box overhangs the screen by 8 on each side so the
    // drift never shows an edge.
    final boxW = size.width + 16;
    final s = math.max(boxW / 390, size.height / 844);
    canvas.save();
    canvas.translate(-8 + drift + (boxW - 390 * s) / 2, (size.height - 844 * s) / 2);
    canvas.scale(s);

    canvas.drawPath(
      Path()
        ..moveTo(-20, 150)
        ..cubicTo(120, 70, 300, 90, 410, 190)
        ..lineTo(410, -20)
        ..lineTo(-20, -20)
        ..close(),
      Paint()..color = AppColors.navy800,
    );
    canvas.drawPath(
      Path()
        ..moveTo(150, -20)
        ..cubicTo(360, 110, 430, 300, 400, 470),
      _stroke(AppColors.navy700, 2),
    );
    const c = Offset(195, 382);
    canvas.drawCircle(c, 200, _stroke(AppColors.gold400.withValues(alpha: 0.14), 1));
    canvas.drawCircle(c, 248, _stroke(AppColors.brand700.withValues(alpha: 0.35), 1));
    canvas.drawCircle(c, 300, _stroke(AppColors.navy600.withValues(alpha: 0.3), 1));

    canvas.translate(0, 24);
    final swoosh = Path()
      ..moveTo(400, 470)
      ..cubicTo(330, 478, 260, 540, 150, 585)
      ..cubicTo(240, 604, 330, 598, 400, 585)
      ..close();
    canvas.drawPath(
      swoosh,
      Paint()
        ..shader = _down(swoosh, [
          AppColors.brand500.withValues(alpha: 0.6),
          AppColors.brand800.withValues(alpha: 0.75),
          AppColors.brand900.withValues(alpha: 0.9),
        ], const [0, 0.5, 1]),
    );
    final edge = Path()
      ..moveTo(400, 470)
      ..cubicTo(330, 478, 260, 540, 150, 585);
    canvas.drawPath(edge, _stroke(AppColors.brand400.withValues(alpha: 0.3), 8, blur: 3.5));
    canvas.drawPath(edge, _stroke(AppColors.brand300.withValues(alpha: 0.95), 1.8));

    final gold = Path()
      ..moveTo(-10, 500)
      ..cubicTo(60, 520, 130, 560, 230, 592)
      ..cubicTo(160, 612, 70, 620, -10, 640)
      ..close();
    canvas.drawPath(
      gold,
      Paint()
        ..color = AppColors.gold300.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      gold,
      Paint()
        ..shader = _across(gold, [
          AppColors.gold200.withValues(alpha: 0.95),
          AppColors.gold300.withValues(alpha: 0.85),
          AppColors.gold400.withValues(alpha: 0.4),
          AppColors.gold400.withValues(alpha: 0),
        ], const [0, 0.3, 0.7, 1]),
    );

    final band = Path()
      ..moveTo(-10, 560)
      ..cubicTo(90, 548, 180, 580, 260, 592)
      ..cubicTo(330, 602, 370, 596, 400, 586)
      ..lineTo(400, 622)
      ..cubicTo(320, 636, 230, 640, 150, 624)
      ..cubicTo(80, 610, 30, 606, -10, 612)
      ..close();
    canvas.drawPath(
      band,
      Paint()
        ..shader = _across(band, [
          AppColors.brand800.withValues(alpha: 0.78),
          AppColors.brand900.withValues(alpha: 0.92),
        ], const [0, 1]),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, 560)
        ..cubicTo(90, 548, 180, 580, 260, 592)
        ..cubicTo(330, 602, 370, 596, 400, 586),
      _stroke(AppColors.brand300.withValues(alpha: 0.75), 1.5),
    );

    canvas.drawPath(
      Path()
        ..moveTo(-10, 612)
        ..cubicTo(90, 596, 180, 630, 270, 622)
        ..cubicTo(340, 616, 380, 606, 400, 596)
        ..lineTo(400, 720)
        ..lineTo(-10, 720)
        ..close(),
      Paint()..color = AppColors.navy900,
    );
    final sheen = Path()
      ..moveTo(120, 668)
      ..cubicTo(220, 644, 330, 648, 400, 634)
      ..lineTo(400, 656)
      ..cubicTo(330, 668, 220, 672, 120, 684)
      ..close();
    canvas.drawPath(
      sheen,
      Paint()
        ..shader = _across(sheen, [
          AppColors.navy700.withValues(alpha: 0),
          AppColors.navy700.withValues(alpha: 0.55),
          AppColors.navy700.withValues(alpha: 0.7),
        ], const [0, 0.5, 1]),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SplashWavesPainter old) => old.drift != drift;
}

/// The ribbon along the foot of page one's photograph. Drawn in the design's
/// 390x180 frame and stretched to the box it is given (`preserveAspectRatio
/// none`).
class OnboardingRibbonPainter extends CustomPainter {
  /// The slow sideways sway, in frame units (0 to -9).
  final double sway;

  const OnboardingRibbonPainter({this.sway = 0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390, size.height / 180);
    canvas.translate(sway, 0);

    final swoosh = Path()
      ..moveTo(390, 46)
      ..cubicTo(335, 52, 285, 96, 205, 124)
      ..cubicTo(270, 138, 330, 136, 390, 126)
      ..close();
    canvas.drawPath(
      swoosh,
      Paint()
        ..shader = _down(swoosh, [
          AppColors.brand500.withValues(alpha: 0.55),
          AppColors.brand800.withValues(alpha: 0.68),
          AppColors.brand900.withValues(alpha: 0.85),
        ], const [0, 0.45, 1]),
    );
    final edge = Path()
      ..moveTo(390, 46)
      ..cubicTo(335, 52, 285, 96, 205, 124);
    canvas.drawPath(edge, _stroke(AppColors.brand400.withValues(alpha: 0.3), 8, blur: 3.5));
    canvas.drawPath(edge, _stroke(AppColors.brand300.withValues(alpha: 0.95), 1.8));

    final gold = Path()
      ..moveTo(0, 66)
      ..cubicTo(40, 58, 90, 88, 150, 110)
      ..cubicTo(190, 122, 220, 126, 250, 130)
      ..cubicTo(190, 144, 90, 152, 0, 164)
      ..close();
    canvas.drawPath(
      gold,
      Paint()
        ..color = AppColors.gold300.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(
      gold,
      Paint()
        ..shader = _across(gold, [
          AppColors.gold200.withValues(alpha: 0.9),
          AppColors.gold300.withValues(alpha: 0.78),
          AppColors.gold400.withValues(alpha: 0.35),
          AppColors.gold400.withValues(alpha: 0),
        ], const [0, 0.28, 0.68, 1]),
    );

    final band = Path()
      ..moveTo(0, 112)
      ..cubicTo(80, 100, 160, 122, 240, 132)
      ..cubicTo(310, 141, 350, 136, 390, 126)
      ..lineTo(390, 152)
      ..cubicTo(320, 162, 240, 164, 160, 152)
      ..cubicTo(90, 142, 40, 138, 0, 144)
      ..close();
    canvas.drawPath(
      band,
      Paint()
        ..shader = _across(band, [
          AppColors.brand800.withValues(alpha: 0.5),
          AppColors.brand900.withValues(alpha: 0.72),
        ], const [0, 1]),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 112)
        ..cubicTo(80, 100, 160, 122, 240, 132)
        ..cubicTo(310, 141, 350, 136, 390, 126),
      _stroke(AppColors.brand300.withValues(alpha: 0.75), 1.5),
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, 142)
        ..cubicTo(90, 130, 170, 160, 250, 154)
        ..cubicTo(320, 149, 360, 141, 390, 132)
        ..lineTo(390, 180)
        ..lineTo(0, 180)
        ..close(),
      Paint()..color = AppColors.navy900,
    );
    final sheen = Path()
      ..moveTo(100, 174)
      ..cubicTo(210, 150, 320, 154, 390, 142)
      ..lineTo(390, 162)
      ..cubicTo(320, 172, 210, 174, 100, 180)
      ..close();
    canvas.drawPath(
      sheen,
      Paint()
        ..shader = _across(sheen, [
          AppColors.navy700.withValues(alpha: 0),
          AppColors.navy700.withValues(alpha: 0.9),
          AppColors.navy700,
        ], const [0, 0.5, 1]),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(OnboardingRibbonPainter old) => old.sway != sway;
}

/// The foot of the sign-in screen's photograph: a gold sweep in from each
/// side over a navy curve with a fine blue edge. The design's 390x120 frame,
/// stretched to the box it is given.
class SignInPhotoEdgePainter extends CustomPainter {
  const SignInPhotoEdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390, size.height / 120);

    final left = Path()
      ..moveTo(0, 42)
      ..cubicTo(90, 40, 180, 92, 260, 104)
      ..cubicTo(180, 118, 90, 114, 0, 118)
      ..close();
    canvas.drawPath(
      left,
      Paint()
        ..shader = _across(left, [
          AppColors.gold300.withValues(alpha: 0.95),
          AppColors.gold400.withValues(alpha: 0.5),
          AppColors.gold400.withValues(alpha: 0),
        ], const [0, 0.6, 1]),
    );
    final right = Path()
      ..moveTo(390, 30)
      ..cubicTo(340, 42, 300, 76, 230, 100)
      ..cubicTo(300, 106, 350, 96, 390, 84)
      ..close();
    canvas.drawPath(
      right,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            AppColors.gold300.withValues(alpha: 0.95),
            AppColors.gold400.withValues(alpha: 0.35),
            AppColors.gold400.withValues(alpha: 0),
          ],
          stops: const [0, 0.7, 1],
        ).createShader(right.getBounds()),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 66)
        ..cubicTo(110, 36, 230, 124, 390, 68)
        ..lineTo(390, 121)
        ..lineTo(0, 121)
        ..close(),
      Paint()..color = AppColors.navy900,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 66)
        ..cubicTo(110, 36, 230, 124, 390, 68),
      _stroke(AppColors.brand400.withValues(alpha: 0.5), 1.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SignInPhotoEdgePainter old) => false;
}

/// Behind the sign-in form: soft navy shapes swelling in from both edges.
/// The design's 390x600 frame, stretched to the box below the photograph.
/// Quieter than the design (owner, 2026-10-12): the shapes at half their
/// strength, and no gold glow in the lower-left corner.
class SignInBackdropPainter extends CustomPainter {
  const SignInBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390, size.height / 600);
    Path bulge(double x0, double y0, double c1x, double c1y, double c2x, double c2y, double x1, double y1) => Path()
      ..moveTo(x0, y0)
      ..cubicTo(c1x, c1y, c2x, c2y, x1, y1)
      ..close();
    final deep = Paint()..color = AppColors.navy800.withValues(alpha: 0.45);
    final soft = Paint()..color = AppColors.navy700.withValues(alpha: 0.35);
    canvas.drawPath(bulge(-30, 40, 90, 90, 70, 300, -30, 400), deep);
    canvas.drawPath(bulge(420, 110, 320, 170, 330, 360, 420, 450), deep);
    canvas.drawPath(bulge(-30, 330, 60, 350, 60, 470, -30, 520), soft);
    canvas.drawPath(bulge(420, 300, 350, 330, 350, 440, 420, 500), soft);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SignInBackdropPainter old) => false;
}
