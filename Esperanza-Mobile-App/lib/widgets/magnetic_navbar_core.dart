import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nav_bar_clipper.dart';
import 'nav_item_data.dart';
import 'nav_style.dart';

/// Floating, centered "magnetic" pill nav bar whose top edge morphs into a
/// valley that travels to the selected tab, with the active bubble nested
/// in it, glowing, above it.
///
/// Reused directly from a reference implementation (adapted only for
/// Esperanza's colors and 5-tab layout — the animation mechanism itself is
/// unchanged): a single [AnimationController] drives the whole trip — the
/// valley's x-position (via [NavBarPainter]), the bubble's x-position, and
/// the active label's fade-out/fade-in all read off the same `t`, so the
/// notch and the bubble can never drift out of sync with each other. See
/// `screens/home/root_shell.dart` for how Esperanza's five tabs and
/// routes/access-control connect to this.
class MagneticNavbarCore extends StatefulWidget {
  final List<NavItemData> items;
  // Normalized (0..1) active-center position for each item, along the
  // pill's own width. Must be the same length as [items]. Proportional
  // (not fixed pixels), so it stays correct at any bar width.
  final List<double> tabCenterRatios;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MagneticNavbarCore({
    super.key,
    required this.items,
    required this.tabCenterRatios,
    required this.currentIndex,
    required this.onTap,
  }) : assert(items.length == tabCenterRatios.length, 'tabCenterRatios must have exactly one entry per item');

  @override
  State<MagneticNavbarCore> createState() => _MagneticNavbarCoreState();
}

class _MagneticNavbarCoreState extends State<MagneticNavbarCore> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  late int _fromIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _controller = AnimationController(vsync: this, duration: NavStyle.travelDuration);
    _t = CurvedAnimation(parent: _controller, curve: NavStyle.travelCurve);
  }

  @override
  void didUpdateWidget(covariant MagneticNavbarCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _fromIndex = oldWidget.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: NavStyle.bottomGap + bottomSafeInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final barWidth = screenWidth * NavStyle.barWidthFraction;
          final horizontalMargin = (screenWidth - barWidth) / 2;
          final slotWidth = barWidth / widget.items.length;
          // The active assembly's X is calibrated per tab
          // (widget.tabCenterRatios) rather than derived purely from equal
          // columns, so it can be tuned independently of the base row's
          // even tap-target layout below.
          double centerXFor(int i) => barWidth * widget.tabCenterRatios[i];

          const totalHeight = NavStyle.barHeight + NavStyle.protrusion;
          const circleRadius = NavStyle.circleSize / 2;
          // Decoupled from notchDepth: the bubble stays put while the pocket
          // beneath it deepens, opening up visible space between them.
          const bubbleCenterYInBar = -NavStyle.circleRise;

          return AnimatedBuilder(
            animation: _t,
            builder: (context, child) {
              final t = _t.value;
              final cx = lerpDouble(centerXFor(_fromIndex), centerXFor(widget.currentIndex), t)!;

              final showingNewContent = t >= 0.5;
              final contentIndex = showingNewContent ? widget.currentIndex : _fromIndex;
              // Label hides while the bubble is mid-flight and reappears
              // once it settles near either end, instead of two labels
              // crossfading illegibly on top of each other.
              final labelOpacity = (1 - 4 * t * (1 - t)).clamp(0.0, 1.0);

              return SizedBox(
                width: screenWidth,
                height: totalHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      key: const ValueKey('nav-bar-shape'),
                      left: horizontalMargin,
                      right: horizontalMargin,
                      bottom: 0,
                      height: NavStyle.barHeight,
                      // PhysicalShape (not a raw CustomPaint + manual
                      // canvas.drawShadow) — the engine gives a physical
                      // layer's elevation shadow genuine room to render
                      // beyond its own tight layout bounds, which a plain
                      // CustomPainter canvas call doesn't get. That's what
                      // was quietly clipping the bar's depth away.
                      child: PhysicalShape(
                        clipper: NavBarClipper(
                          notchCenterX: cx,
                          notchWidth: NavStyle.notchWidth,
                          notchDepth: NavStyle.notchDepth,
                          topRadius: NavStyle.topCornerRadius,
                          bottomRadius: NavStyle.bottomCornerRadius,
                        ),
                        color: AppColors.brand500,
                        elevation: NavStyle.barElevation,
                        shadowColor: AppColors.slate800,
                        child: Row(
                          children: List.generate(widget.items.length, (i) {
                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => widget.onTap(i),
                                child: SizedBox.expand(
                                  child: Align(
                                    alignment: Alignment(0, NavStyle.rowVerticalAlign),
                                    // A Stack (not a Column) so the invisible
                                    // label below never perturbs the icon's
                                    // own geometry — Stack centers each
                                    // child independently, so adding it
                                    // can't shift the icon up/down the way
                                    // stacking it in a Column would.
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // The slot the bubble currently owns
                                        // hides its base icon so there's
                                        // never a duplicate of the active
                                        // icon on screen; the tab's tap
                                        // target/position is kept.
                                        Opacity(
                                          opacity: i == contentIndex ? 0.0 : 1.0,
                                          child: Icon(
                                            widget.items[i].outlineIcon,
                                            size: NavStyle.inactiveIconSize,
                                            color: Colors.white,
                                          ),
                                        ),
                                        // Invisible (zero-opacity, but
                                        // real-sized so it stays hit-testable)
                                        // per-tab label — skipped for
                                        // contentIndex, which already has the
                                        // single floating visible label
                                        // below (avoids a duplicate Text
                                        // with the same content). Exists
                                        // purely so every inactive
                                        // destination stays reliably
                                        // identifiable and tappable by name
                                        // (find-by-text in tests, and any
                                        // future a11y tooling) without
                                        // rendering a second, visually
                                        // duplicate label.
                                        if (i != contentIndex) Opacity(opacity: 0, child: Text(widget.items[i].label)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    Positioned(
                      key: const ValueKey('nav-floating-indicator'),
                      left: horizontalMargin + cx - circleRadius,
                      top: NavStyle.protrusion + bubbleCenterYInBar - circleRadius,
                      width: NavStyle.circleSize,
                      height: NavStyle.circleSize,
                      child: GestureDetector(
                        onTap: () => widget.onTap(widget.currentIndex),
                        // Glow + border are paint-only (BoxShadow/Border
                        // never affect RenderBox size), so the box stays
                        // exactly circleSize x circleSize — the magnetic
                        // pocket keeps reacting to the true circle, not the
                        // decoration.
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppColors.brand500, width: NavStyle.activeCircleBorderWidth),
                            boxShadow: [
                              // Neutral drop shadow, mostly downward — reads
                              // as the circle sitting physically elevated
                              // above the blue bar, distinct from the
                              // colored glow below it.
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                              // Inner glow: tight, brighter — a defined
                              // luminous edge right at the circle.
                              BoxShadow(
                                color: AppColors.brand500.withValues(alpha: 0.55),
                                blurRadius: 8,
                                spreadRadius: 0.5,
                              ),
                              // Outer glow: broad, soft — the atmospheric
                              // halo that fades into the pocket's open space.
                              BoxShadow(
                                color: AppColors.brand500.withValues(alpha: 0.22),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            widget.items[contentIndex].filledIcon,
                            size: NavStyle.activeIconSize,
                            color: AppColors.brand500,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: horizontalMargin + cx - slotWidth / 2,
                      width: slotWidth,
                      top: NavStyle.protrusion + NavStyle.notchDepth + NavStyle.labelGap,
                      child: Opacity(
                        opacity: labelOpacity,
                        child: Text(
                          widget.items[contentIndex].label,
                          textAlign: TextAlign.center,
                          style: NavStyle.activeLabelStyle.copyWith(
                            // Sits on the bar's own blue surface (below the
                            // notch), not on the page background, so it
                            // needs white for contrast rather than blue.
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
