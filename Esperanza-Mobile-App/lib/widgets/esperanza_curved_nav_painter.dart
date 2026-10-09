import 'package:flutter/rendering.dart';

/// Paints the navbar surface. Originally a port of Servana's
/// `ServanaCurvedNavPainter` (a full-width bar, rounded on top, with a
/// cradle dipped under the active tab); since the 2026-10 design refresh it
/// is a floating frosted-glass pill, inset from the screen edges; the active
/// tab is a gold capsule inside it (no glow). [EsperanzaCurvedNavBar] blurs what is
/// behind it through [pillPath]; this painter lays the glass over that
/// blur: a soft navy shadow, a translucent white body lit from above, a
/// bright rim and a faint blue hairline.
class EsperanzaCurvedNavPainter extends CustomPainter {
  final double cradleCentreX;
  final Color surfaceColor;
  final Color shadowColor;
  final Color borderColor;

  /// The device's bottom inset: the pill floats above the gesture area
  /// rather than running under it.
  final double bottomInset;

  const EsperanzaCurvedNavPainter({
    required this.cradleCentreX,
    required this.surfaceColor,
    required this.shadowColor,
    required this.borderColor,
    this.bottomInset = 0,
  });

  /// Side margin of the floating pill. Small enough that the outer tabs'
  /// labels ("Emergency") stay inside it on a 280pt phone.
  static const double sideMargin = 8;
  static const double topMargin = 4;
  static const double pillRadius = 30;

  /// Space between the pill and the bottom of the screen: clear of the
  /// gesture handle when there is one.
  static double bottomGap(double bottomInset) => bottomInset > 0 ? bottomInset + 4 : 10;

  /// The pill's outline. A plain stadium: the dipped cradle of the old
  /// full-width bar ran into the rounded corners under the outer tabs, and
  /// the design has none; the active tab is marked by its gold capsule
  /// instead. [cradleCentreX] is kept as the one centre the capsule and the
  /// surface agree on. Shared with the blur clip so glass and paint are
  /// always the same shape.
  static Path pillPath(Size size, {double bottomInset = 0}) {
    final rect = Rect.fromLTRB(sideMargin, topMargin, size.width - sideMargin, size.height - bottomGap(bottomInset));
    return Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(pillRadius)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = pillPath(size, bottomInset: bottomInset);
    final bounds = path.getBounds();

    // A deep, soft float shadow under the whole pill.
    canvas.drawPath(
      path.shift(const Offset(0, 8)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Frosted body: translucent white, brighter at the top.
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Frosted but mostly opaque (2026-10 refinement): the content
          // scrolling under it softens through, the icons stay crisp.
          colors: [surfaceColor.withValues(alpha: 0.92), surfaceColor.withValues(alpha: 0.84)],
        ).createShader(bounds),
    );

    // Inner light along the top rim, the glass catching light.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = surfaceColor.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();

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
        bottomInset != oldDelegate.bottomInset;
  }
}

/// Clips the backdrop blur to the pill.
class EsperanzaNavPillClipper extends CustomClipper<Path> {
  final double bottomInset;

  const EsperanzaNavPillClipper({required this.bottomInset});

  @override
  Path getClip(Size size) => EsperanzaCurvedNavPainter.pillPath(size, bottomInset: bottomInset);

  @override
  bool shouldReclip(EsperanzaNavPillClipper old) => old.bottomInset != bottomInset;
}
