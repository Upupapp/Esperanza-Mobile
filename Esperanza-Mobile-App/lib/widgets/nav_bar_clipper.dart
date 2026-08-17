import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Clips the floating nav bar down to its silhouette: a rounded pill whose
/// top edge dips into a smooth valley centered at [notchCenterX]. The
/// active bubble sits in that valley, so the valley's position IS the
/// active indicator — there's no separate "circle on top of a plain
/// rectangle".
///
/// Used as a [PhysicalShape] clipper (not a raw [CustomPainter] with a
/// manual `canvas.drawShadow` call) specifically so the bar's elevation
/// shadow is never confined to this shape's own tight layout bounds —
/// `PhysicalShape`/`PhysicalModel` are handled specially by the engine's
/// layer system to give their shadow real room to render beyond the
/// widget's box, the same mechanism every other elevated Material surface
/// in Flutter relies on. A plain `CustomPainter` canvas call doesn't get
/// that treatment, which is what quietly clipped the bar's depth away.
class NavBarClipper extends CustomClipper<Path> {
  final double notchCenterX;
  final double notchWidth;
  final double notchDepth;
  final double topRadius;
  final double bottomRadius;

  NavBarClipper({
    required this.notchCenterX,
    required this.notchWidth,
    required this.notchDepth,
    required this.topRadius,
    required this.bottomRadius,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final halfWidth = notchWidth / 2;
    // The trough is NEVER clamped — it always sits exactly under the
    // circle/label (which read the same unclamped x), so the pocket can
    // never visually drift away from the active assembly. Only defends
    // against a pathological cx outside the bar entirely.
    final cx = notchCenterX.clamp(topRadius, w - topRadius);
    final flatLeft = topRadius;
    final flatRight = w - topRadius;

    // One continuous "bump" model, translated by cx, describes the pocket
    // on both sides independently. Away from the corners each side gets the
    // full halfWidth — generous, matching clearance around the circle.
    // Only when a side would run past the rounded corner does ITS OWN scale
    // shrink to fit exactly the room available (never past the corner, so
    // the corner itself never deforms) while the *other*, unconstrained
    // side keeps its full open width — an outer tab still reads as wide as
    // a middle one on its inward-facing side, per the reference.
    final leftScale = math.min(halfWidth, cx - flatLeft);
    final rightScale = math.min(halfWidth, flatRight - cx);

    // (1-t²)² is a smooth "bump": 1 at the center, easing down to exactly 0
    // — with zero slope, so no kink — at |t|=1. Fitting it to whatever room
    // is actually available on each side is what makes a compressed side
    // still read as a complete, gentle curve instead of a steep cutoff.
    double depthAt(double x) {
      final scale = x <= cx ? leftScale : rightScale;
      if (scale <= 0) return 0;
      final t = ((x - cx) / scale).clamp(-1.0, 1.0);
      final bump = (1 - t * t);
      return notchDepth * bump * bump;
    }

    final path = Path()..moveTo(flatLeft, 0);
    const step = 2.5;
    for (double x = flatLeft; x < flatRight; x += step) {
      path.lineTo(x, depthAt(x));
    }
    path
      ..lineTo(flatRight, 0)
      ..quadraticBezierTo(w, 0, w, topRadius)
      ..lineTo(w, h - bottomRadius)
      ..quadraticBezierTo(w, h, w - bottomRadius, h)
      ..lineTo(bottomRadius, h)
      ..quadraticBezierTo(0, h, 0, h - bottomRadius)
      ..lineTo(0, topRadius)
      ..quadraticBezierTo(0, 0, topRadius, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant NavBarClipper oldClipper) {
    return oldClipper.notchCenterX != notchCenterX ||
        oldClipper.notchWidth != notchWidth ||
        oldClipper.notchDepth != notchDepth ||
        oldClipper.topRadius != topRadius ||
        oldClipper.bottomRadius != bottomRadius;
  }
}
