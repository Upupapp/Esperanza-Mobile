import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// One tab's icon/activeIcon/label — same shape as the BottomNavigationBar
/// items it replaces, so swapping in [AnimatedBottomNavigation] didn't
/// require inventing new icons or copy.
class AnimatedBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const AnimatedBottomNavItem({required this.icon, required this.activeIcon, required this.label});
}

/// A bottom navigation bar whose surface itself deforms around the active
/// tab — a floating circular indicator *and* a smooth raised bump in the
/// bar's own top edge that travels together underneath it, both driven
/// from one shared animated horizontal position ([_indexAnimation]). This
/// is the key difference from an earlier iteration that only translated
/// the circle over an otherwise flat, static bar: here the bar's shape is
/// painted fresh every frame by [_NavBarPainter] from the *same* animated
/// value that positions the circle, so a long trip (e.g. Home ->
/// Emergency) reads as the whole surface flowing across the bar, not a
/// circle sliding over an unrelated rectangle.
///
/// Built entirely on Flutter's built-in `CustomPainter`/`AnimationController`
/// — the natural Flutter equivalent of an animated SVG path — rather than
/// a new dependency; this app already relies on the same class of
/// built-in animation APIs elsewhere (see widgets/segmented_tabs.dart's
/// AnimatedContainer).
class AnimatedBottomNavigation extends StatefulWidget {
  final List<AnimatedBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AnimatedBottomNavigation({super.key, required this.items, required this.currentIndex, required this.onTap});

  @override
  State<AnimatedBottomNavigation> createState() => _AnimatedBottomNavigationState();
}

class _AnimatedBottomNavigationState extends State<AnimatedBottomNavigation> with SingleTickerProviderStateMixin {
  // The colored bar itself only needs to be tall enough for icon+label,
  // but 64 was measured too tight at 1.3x accessibility text scale on
  // narrow phones (3px RenderFlex overflow in _NavTapTarget) — 72 matches
  // Material's own 80dp bottom-nav spec and leaves real margin.
  static const double _barHeight = 72;
  static const double _bubbleSize = 60;
  // How much of the bubble's own height dips down into the bar's flat
  // baseline — the rest floats above it, further reduced by the bump
  // rising to meet it (see _bumpHeight). Biasing most of the circle
  // above the baseline (rather than centering it on the boundary) is
  // what makes it read as a floating object the surface rises toward,
  // not a bar decoration.
  static const double _overlapIntoBar = 16;
  static const double _protrusion = _bubbleSize - _overlapIntoBar;

  // Geometry of the moving bump in the bar's top edge — the part of this
  // widget that makes the surface itself travel with the indicator
  // instead of staying flat. Width guidance from the nav spec: wider
  // than the circle (60px) so the circle feels seated inside it, roughly
  // 90-105px total across rest/in-flight.
  static const double _bumpHalfWidthAtRest = 44;
  static const double _bumpStretch = 10; // added while in flight, see build()
  static const double _bumpHeight = 26;

  late final AnimationController _controller;
  late Animation<double> _indexAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _indexAnimation = AlwaysStoppedAnimation(widget.currentIndex.toDouble());
  }

  @override
  void didUpdateWidget(covariant AnimatedBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      // Start from wherever the indicator actually is right now, not
      // from the previous tab's resting index — this way an interrupted
      // mid-flight tap (e.g. Home -> Emergency -> Dokyu before the first
      // trip finishes) redirects smoothly instead of jumping back to
      // where it started.
      final start = _indexAnimation.value;
      _indexAnimation = Tween<double>(begin: start, end: widget.currentIndex.toDouble()).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // The safe-area inset is added as *extra* bar height (and consumed by
    // bottom padding inside the tap targets) rather than eating into a
    // fixed-height box — nesting a SafeArea around a fixed-height box
    // silently shrinks the already-tight icon+label row on devices with
    // a tall home-indicator inset.
    final barVisualHeight = _barHeight + bottomInset;
    final totalHeight = barVisualHeight + _protrusion;
    final barTopY = _protrusion; // y of the bar's flat top edge, in this widget's own coordinate space

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / widget.items.length;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // The one shared animated value: everything that needs to
              // move together — the bar's bump and the floating circle —
              // is derived from this single number every frame, so they
              // can never drift out of sync.
              final animatedIndex = _indexAnimation.value;
              final centerX = segmentWidth * animatedIndex + segmentWidth / 2;

              // Subtle optional stretch (nav spec section "OPTIONAL
              // STRETCH EFFECT"): widest exactly mid-flight between two
              // tabs, back to its resting width once settled — derived
              // from the same animatedIndex, no extra controller needed.
              final distanceFromRest = (animatedIndex - animatedIndex.roundToDouble()).abs();
              final travel = (distanceFromRest * 2).clamp(0.0, 1.0);
              final bumpHalfWidth = _bumpHalfWidthAtRest + travel * _bumpStretch;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // The bar's surface — painted fresh every animation
                  // frame from `centerX`/`bumpHalfWidth`, so the raised
                  // section is not a static decoration but travels with
                  // the indicator. See _NavBarPainter for the actual
                  // path/bump geometry.
                  Positioned.fill(
                    child: CustomPaint(
                      key: const ValueKey('nav-bar-shape'),
                      painter: _NavBarPainter(
                        centerX: centerX,
                        barTopY: barTopY,
                        bumpHalfWidth: bumpHalfWidth,
                        bumpHeight: _bumpHeight,
                        barColor: AppColors.surface,
                      ),
                    ),
                  ),
                  // Inactive/active tab content — icons and labels stay
                  // at fixed X positions; only their own color/opacity
                  // reacts to selection. They never travel horizontally.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: barVisualHeight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: Row(
                        children: [
                          for (int i = 0; i < widget.items.length; i++)
                            Expanded(
                              child: _NavTapTarget(
                                item: widget.items[i],
                                selected: i == widget.currentIndex,
                                onTap: () => widget.onTap(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // The floating circle, positioned from the exact same
                  // `centerX` used to paint the bump beneath it — this is
                  // what keeps them physically locked together as one
                  // system while gliding, including across long,
                  // non-adjacent trips.
                  Positioned(
                    key: const ValueKey('nav-floating-indicator'),
                    top: 0,
                    left: centerX - _bubbleSize / 2,
                    width: _bubbleSize,
                    height: _bubbleSize,
                    child: IgnorePointer(
                      // Keyed by currentIndex so every tab change restarts
                      // this tween fresh: a brief dip below full size
                      // while the circle is in flight, then a gentle
                      // overshoot past 1.0 and back — a subtle
                      // spring/settle "landing" cue timed to arrive
                      // alongside the glide, independent of the shared
                      // position animation above (which stays a plain
                      // ease-out so it never drifts off-center).
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(widget.currentIndex),
                        tween: Tween(begin: 0.92, end: 1.0),
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brand500,
                            boxShadow: [
                              BoxShadow(color: AppColors.brand500.withValues(alpha: 0.26), blurRadius: 22, offset: const Offset(0, 10)),
                              BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(scale: animation, child: child),
                              ),
                              child: Icon(
                                widget.items[widget.currentIndex].activeIcon,
                                key: ValueKey(widget.currentIndex),
                                color: Colors.white,
                                size: 27,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Paints the bar's actual silhouette: flat everywhere except a smooth
/// symmetric bump — two mirrored cubic Béziers meeting at a rounded apex
/// — centered on [centerX], rising [bumpHeight] above the flat baseline
/// [barTopY]. This is what makes the navigation *surface itself* move
/// with the selected tab rather than staying a static rectangle under a
/// sliding circle. A soft, low-opacity blurred copy of the same path is
/// drawn first as a hand-tuned shadow (softer than Flutter's default
/// Material elevation shadow) so the whole bar+bump silhouette reads as
/// one elevated shape, not a flat panel with a circle floating in front
/// of it.
class _NavBarPainter extends CustomPainter {
  final double centerX;
  final double barTopY;
  final double bumpHalfWidth;
  final double bumpHeight;
  final Color barColor;

  const _NavBarPainter({
    required this.centerX,
    required this.barTopY,
    required this.bumpHalfWidth,
    required this.bumpHeight,
    required this.barColor,
  });

  Path _shape(Size size) {
    final apex = Offset(centerX, barTopY - bumpHeight);
    return Path()
      ..moveTo(0, barTopY)
      ..lineTo(centerX - bumpHalfWidth, barTopY)
      ..cubicTo(
        centerX - bumpHalfWidth * 0.5, barTopY,
        centerX - bumpHalfWidth * 0.32, apex.dy,
        apex.dx, apex.dy,
      )
      ..cubicTo(
        centerX + bumpHalfWidth * 0.32, apex.dy,
        centerX + bumpHalfWidth * 0.5, barTopY,
        centerX + bumpHalfWidth, barTopY,
      )
      ..lineTo(size.width, barTopY)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shape(size);

    canvas.save();
    canvas.translate(0, 5);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.restore();

    canvas.drawPath(path, Paint()..color = barColor);
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter oldDelegate) =>
      oldDelegate.centerX != centerX ||
      oldDelegate.barTopY != barTopY ||
      oldDelegate.bumpHalfWidth != bumpHalfWidth ||
      oldDelegate.bumpHeight != bumpHeight ||
      oldDelegate.barColor != barColor;
}

class _NavTapTarget extends StatelessWidget {
  final AnimatedBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTapTarget({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Fills the bar's own height and centers its content within it — the
    // floating bubble above needs no matching space reserved *inside*
    // this tap target, since it's a separate Positioned layer in the
    // parent Stack, not part of this Column's flow.
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The selected tab's own icon fades out — its icon is shown
          // inside the floating bubble above instead, so nothing renders
          // twice.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: selected ? 0 : 1,
            child: Icon(item.icon, size: 22, color: AppColors.slate400),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.brand600 : AppColors.slate400,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
