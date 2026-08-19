import 'package:flutter/material.dart';

/// Dimensions, timings and curves for the magnetic-repulsion bottom
/// navigation bar (see `magnetic_navbar_core.dart`). Geometry is
/// proportional (fractions of screen width) so the bar keeps the same
/// silhouette on different screen sizes — a floating centered pill rather
/// than a full-width bar — instead of relying on fixed pixel coordinates
/// tuned for one device.
///
/// Values here are preserved from the source reference implementation
/// exactly — only colors (which live in `AppColors`, referenced directly
/// from `magnetic_navbar_core.dart`) and the tab set/labels (see
/// `screens/home/root_shell.dart`) were adapted for Esperanza.
class NavStyle {
  NavStyle._();

  // Floating pill container
  static const double barWidthFraction = 0.72; // of screen width
  static const double barHeight = 72.0;
  static const double topCornerRadius = 4.0;
  static const double bottomCornerRadius = 34.0;
  static const double bottomGap = 22.0; // gap between pill and screen bottom / safe area
  // Matches BottomNavigationBar's own default Material elevation — a
  // well-established "floating bottom bar" depth, subtle rather than heavy.
  static const double barElevation = 8.0;

  // Extra breathing room above the navbar for any other floating element
  // (e.g. a screen's own FloatingActionButton) that needs to visibly clear
  // it, not just avoid literally overlapping it. Pair with
  // `MediaQuery.paddingOf(context).bottom` — RootShell's Scaffold uses
  // `extendBody: true`, which publishes a bottom MediaQuery padding that
  // already exactly matches this navbar's full rendered height (see
  // RootShell's own doc comment), so screens nested inside it never need
  // to duplicate barHeight/protrusion/bottomGap math themselves — they
  // just add this one gap on top of that inherited value.
  static const double floatingElementGap = 16.0;

  // Material's standard extended-FAB footprint — combine with
  // `floatingElementGap` (twice: once between the FAB and the navbar,
  // once between other content and the FAB) to size a bottom reservation
  // for anything — like an empty state — that needs to visibly clear both
  // the navbar *and* a floating action button sitting above it, not just
  // the navbar alone.
  static const double floatingActionButtonHeight = 56.0;

  // Morphing notch that the active bubble sits in. Its width is derived
  // from an explicit "exclusion radius" around the circle — how far the
  // dark surface must stay from the circle's edge before it's allowed to
  // return flat — rather than being an independent tuned number.
  static const double circleClearance = 30.0;
  static const double notchWidth = circleSize + circleClearance * 2;
  static const double notchDepth = 26.0;

  // Active bubble
  static const double circleSize = 60.0;
  // How far the bubble's center sits above the bar's flat top edge. Kept as
  // its own constant (rather than derived from notchDepth) so deepening the
  // pocket doesn't drag the bubble down with it. Set so exactly 1/8 of the
  // circle's diameter sits below that flat line: circleRise = radius - (
  // diameter / 8).
  static const double circleRise = circleSize / 2 - circleSize / 8;
  // Extra headroom above the pill so the bubble can protrude without
  // clipping. Must clear circleRise + circleRadius.
  static const double protrusion = 56.0;
  // Gap between the pocket floor and the active label's baseline.
  static const double labelGap = 4.0;
  // Vertical alignment (-1 top .. 1 bottom) of the base icon row within the
  // bar. Pulled down from center so the row has its own stable baseline
  // below the active label instead of sitting underneath it.
  static const double rowVerticalAlign = 0.6;

  // Active-circle outline — purely decorative (a Border on the circle's
  // own BoxDecoration, paint-only), so it never changes the circle's true
  // layout diameter.
  static const double activeCircleBorderWidth = 2.5;

  // Icon sizing
  static const double inactiveIconSize = 20.0;
  static const double activeIconSize = 22.0;

  // Motion — the notch + bubble travel together, driven by one controller.
  static const Duration travelDuration = Duration(milliseconds: 360);
  static const Curve travelCurve = Curves.easeInOutCubic;

  static const TextStyle activeLabelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.1);
}
