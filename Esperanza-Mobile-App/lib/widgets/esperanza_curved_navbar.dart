import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../theme/app_elevation.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'esperanza_center_action.dart';
import 'esperanza_curved_nav_painter.dart';
import 'esperanza_nav_item.dart';
import 'esperanza_nav_motion.dart';
import 'nav_item_data.dart';
import 'service_launcher_menu.dart';

/// Esperanza's bottom navigation bar — a direct structural/behavioral port
/// of the Servana Client App's `ServanaCurvedMainNavigation`
/// (design_reference/ServanaClientAPP-main/ServanaClientAPP-main/lib/common/
/// presentation/navigation/servana_curved_main_navigation.dart), the actual
/// source this was copied from. Same full-width, rounded-top-only bar with
/// a single travelling cradle+bubble, same 5-slot layout with a reserved
/// centre gap for the launcher — only Servana's own destinations/icons/
/// colors were swapped for Esperanza's.
///
/// Slot layout (mirrors Servana's Home/Bookings/[gap]/Messages/Profile):
/// 0 Home, 1 Balita, 2 [reserved — the centre "+" launcher lives here,
/// never a Row cell], 3 Events, 4 Emergency.
class EsperanzaCurvedNavBar extends StatelessWidget {
  final List<NavItemData> items;

  /// Index into [items] (0..3) of the active real tab, or null while the
  /// centre launcher owns the active state instead.
  final int? activeIndex;

  /// Non-null while Dokyu/Tulong (reached via the centre launcher) is the
  /// current screen — drives the cradle position and swaps the "+" circle
  /// for that destination's own icon/color, same as a tab's active bubble.
  final ServiceLauncherTarget? activeLauncherTarget;

  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterPressed;

  const EsperanzaCurvedNavBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.activeLauncherTarget,
    required this.onTabSelected,
    required this.onCenterPressed,
  });

  static const int _slotCount = 5;

  static int _slotOf(int itemIndex) => itemIndex < 2 ? itemIndex : itemIndex + 1;

  /// Centre x of [slot] (0..4): five equal slots across the pill, inset
  /// from its rounded ends by [EsperanzaNavMotion.tabInset].
  static double slotCentreX(double width, int slot) {
    const inset = EsperanzaNavMotion.tabInset;
    return inset + (slot + 0.5) * (width - 2 * inset) / _slotCount;
  }

  /// The label's line height at the user's text size (as
  /// [EsperanzaNavItem] sets it).
  static double labelHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(AppTextSize.fine) * EsperanzaNavItem.labelLineHeight;

  static const Color _surface = AppColors.surface;
  // A visible hairline, not AppColors.border (slate100 — nearly invisible
  // against a white/light page background, which is what made the bar's
  // own top edge — and by extension the moving active bubble/cradle
  // riding along it — hard to read against the page). brand100 is a
  // subtle Esperanza-blue tint rather than a neutral gray, still light
  // enough to stay a hairline, not a new visible container. Applies to
  // the whole painted outline (see EsperanzaCurvedNavPainter), but the
  // bar's bottom/side edges sit flush against the screen edge, so the top
  // — the only edge with page content actually visible behind it — is
  // where this reads.
  static const Color _border = AppColors.slate200;
  // Was a raw 0x1A0B1B4A literal commented "navy900 @ 10%" — but 0B1B4A is not
  // navy900 (0B1730). Now actually derived from the token. See AppElevation.
  static final Color _shadow = AppElevation.navbarShadow.withValues(alpha: 0.18);

  @override
  Widget build(BuildContext context) {
    final reduced = EsperanzaNavMotion.reduced(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return RepaintBoundary(
      child: SizedBox(
        height: EsperanzaNavMotion.barHeight + bottomInset,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final targetSlot = activeLauncherTarget != null ? 2 : _slotOf(activeIndex ?? 0);
            final activeCentreX = slotCentreX(width, targetSlot);

            // Each tab centres its icon row and label in the pill, so the
            // space above and below is the same; the capsule sits on the
            // icon row. At very large text the row gives way first, so the
            // capsule is kept inside the pill's top edge.
            const rowTop = EsperanzaCurvedNavPainter.topMargin;
            final rowHeight = constraints.maxHeight - rowTop - EsperanzaCurvedNavPainter.bottomGap(bottomInset);
            final content = EsperanzaNavMotion.bubbleHeight + EsperanzaNavMotion.labelGap + labelHeight(context);
            final bubbleTop = rowTop + ((rowHeight - content) / 2).clamp(0.0, double.infinity);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Surface — the painted bar shape with its cradle.
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: activeCentreX, end: activeCentreX),
                    duration: EsperanzaNavMotion.selectionFor(context),
                    curve: EsperanzaNavMotion.selectionCurve,
                    builder: (context, x, _) {
                      // Frosted glass (2026-10 design): what scrolls behind
                      // the pill is blurred, clipped to the pill itself, and
                      // the painter lays the translucent glass over it.
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipPath(
                            clipper: EsperanzaNavPillClipper(bottomInset: bottomInset),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          CustomPaint(
                            key: const ValueKey('nav-bar-shape'),
                            painter: EsperanzaCurvedNavPainter(
                              cradleCentreX: x,
                              surfaceColor: _surface,
                              shadowColor: _shadow,
                              borderColor: _border,
                              bottomInset: bottomInset,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 2. Tab cells — spans the pill only, clear of its rounded
                // ends; the extra bottomInset height below is the safe area.
                Positioned(
                  left: EsperanzaNavMotion.tabInset,
                  right: EsperanzaNavMotion.tabInset,
                  top: EsperanzaCurvedNavPainter.topMargin,
                  bottom: EsperanzaCurvedNavPainter.bottomGap(bottomInset),
                  child: Row(
                    children: [
                      EsperanzaNavItem(
                        item: items[0],
                        isActive: activeIndex == 0,
                        onTap: () => onTabSelected(0),
                      ),
                      EsperanzaNavItem(
                        item: items[1],
                        isActive: activeIndex == 1,
                        onTap: () => onTabSelected(1),
                      ),
                      const Expanded(child: SizedBox()), // reserved centre gap
                      EsperanzaNavItem(
                        item: items[2],
                        isActive: activeIndex == 2,
                        onTap: () => onTabSelected(2),
                      ),
                      EsperanzaNavItem(
                        item: items[3],
                        isActive: activeIndex == 3,
                        onTap: () => onTabSelected(3),
                      ),
                    ],
                  ),
                ),

                // 3. Travelling active capsule, inside the pill around the
                // active icon — hidden while the launcher is active, since
                // the larger "+" circle already occupies that role.
                if (activeIndex != null)
                  AnimatedPositioned(
                    key: const ValueKey('nav-floating-indicator'),
                    duration: EsperanzaNavMotion.selectionFor(context),
                    curve: EsperanzaNavMotion.selectionCurve,
                    left: activeCentreX - EsperanzaNavMotion.bubbleDiameter / 2,
                    top: bubbleTop,
                    child: IgnorePointer(
                      child: EsperanzaActiveBubble(item: items[activeIndex!], reduced: reduced),
                    ),
                  ),

                // 4. Central "+" launcher — half above the bar, half on it.
                Positioned(
                  key: const ValueKey('nav-center-action'),
                  left: width / 2 - EsperanzaNavMotion.centerDiameter / 2,
                  top: -(EsperanzaNavMotion.centerDiameter / 2),
                  child: EsperanzaCenterAction(
                    onPressed: onCenterPressed,
                    activeIcon: activeLauncherTarget?.icon,
                    activeAccent: activeLauncherTarget?.accent,
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
