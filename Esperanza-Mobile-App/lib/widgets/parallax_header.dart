import 'package:flutter/material.dart';

/// A header/banner whose decorative [background] shifts slightly slower
/// than the page scrolls past it — a subtle parallax effect for hero
/// sections, kept reusable so it isn't reimplemented per screen.
///
/// Deliberately scoped to a single bounded box (not a whole-page
/// CustomScrollView/SliverAppBar rework): existing screens keep their
/// plain ListView/SingleChildScrollView and only pass in the
/// [ScrollController] already driving that scroll view. [foreground] (the
/// actual text/avatar/buttons) never moves — only [background] does, so
/// readability and tap targets are unaffected.
///
/// Sized by [foreground]'s own natural height (via Stack's default
/// sizing — [background] is `Positioned`, so it never affects Stack's
/// size), not a hard-coded height: a fixed height here previously caused
/// a universal "BOTTOM OVERFLOWED" once the hero's button row wrapped to
/// two lines on narrower widths, the same "fixed size vs. variable
/// content" bug hardened against everywhere else in this app. Background
/// is intentionally rendered [_overshoot] px past every edge so shifting
/// it for the parallax effect can never reveal a gap underneath.
class ParallaxHeader extends StatelessWidget {
  final ScrollController scrollController;
  final Widget background;
  final Widget foreground;
  final double parallaxFactor;
  final double maxScrollForEffect;
  final BorderRadius? borderRadius;

  const ParallaxHeader({
    super.key,
    required this.scrollController,
    required this.background,
    required this.foreground,
    this.parallaxFactor = 0.3,
    this.maxScrollForEffect = 200,
    this.borderRadius,
  });

  static const _overshoot = 60.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          Positioned(
            top: -_overshoot,
            bottom: -_overshoot,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: scrollController,
              builder: (context, child) {
                double offset = 0;
                if (scrollController.hasClients && scrollController.positions.length == 1) {
                  offset = scrollController.offset.clamp(0, maxScrollForEffect) * parallaxFactor;
                }
                return Transform.translate(offset: Offset(0, -offset), child: child);
              },
              child: background,
            ),
          ),
          foreground,
        ],
      ),
    );
  }
}
