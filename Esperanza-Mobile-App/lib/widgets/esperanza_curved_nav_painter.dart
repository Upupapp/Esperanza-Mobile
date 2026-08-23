import 'package:flutter/rendering.dart';
import 'esperanza_nav_motion.dart';

/// Paints the navbar surface: a full-width bar, rounded only on its top two
/// corners (flush/square at the bottom, since it sits at the true screen
/// edge, not floating on a margin), with a cradle dipped into the top edge
/// beneath the active tab. Direct port of Servana's
/// `ServanaCurvedNavPainter` — same path construction, same draw order
/// (shadow first, along the identical shifted path, then fill, then a hairline
/// border) — only the class name changed.
class EsperanzaCurvedNavPainter extends CustomPainter {
  final double cradleCentreX;
  final Color surfaceColor;
  final Color shadowColor;
  final Color borderColor;
  final bool showCradle;

  const EsperanzaCurvedNavPainter({
    required this.cradleCentreX,
    required this.surfaceColor,
    required this.shadowColor,
    required this.borderColor,
    required this.showCradle,
  });

  static const double _cradleHalfWidth = 44;
  static const double _cradleDepth = 18;

  Path _buildPath(Size size) {
    const r = EsperanzaNavMotion.surfaceRadius;
    final path = Path()..moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);

    if (showCradle) {
      final left = cradleCentreX - _cradleHalfWidth;
      final right = cradleCentreX + _cradleHalfWidth;
      path.lineTo(left, 0);
      // Two mirrored cubics so the shoulders leave and rejoin the top edge
      // tangentially — a single arc would show a crease at the join.
      path.cubicTo(left + _cradleHalfWidth * 0.45, 0, cradleCentreX - _cradleHalfWidth * 0.62, _cradleDepth,
          cradleCentreX, _cradleDepth);
      path.cubicTo(cradleCentreX + _cradleHalfWidth * 0.62, _cradleDepth, right - _cradleHalfWidth * 0.45, 0, right,
          0);
    }

    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    // Only the top edge can cast a visible shadow — the bar sits at the
    // screen bottom, so the shadow is drawn along the same path, shifted up.
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path.shift(const Offset(0, -2)), shadowPaint);

    canvas.drawPath(path, Paint()..color = surfaceColor);

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant EsperanzaCurvedNavPainter oldDelegate) {
    return cradleCentreX != oldDelegate.cradleCentreX ||
        surfaceColor != oldDelegate.surfaceColor ||
        shadowColor != oldDelegate.shadowColor ||
        borderColor != oldDelegate.borderColor ||
        showCradle != oldDelegate.showCradle;
  }
}
