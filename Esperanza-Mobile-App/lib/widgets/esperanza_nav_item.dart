import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'esperanza_nav_motion.dart';
import 'nav_item_data.dart';

/// One destination cell in [EsperanzaCurvedNavBar]'s base row. Direct port
/// of Servana's `ServanaNavItem`: the label is ALWAYS shown (not only for
/// the active tab, which is how Esperanza's old floating pill behaved) and
/// occupies a fixed position, so nothing shifts when selection changes. The
/// icon area above it is a reserved, fixed-height box that goes empty while
/// this tab is active — the active icon is shown instead inside the
/// travelling bubble that floats above the bar, not here.
class EsperanzaNavItem extends StatelessWidget {
  final NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const EsperanzaNavItem({super.key, required this.item, required this.isActive, required this.onTap});

  // 2026-10 refresh: the active tab is a gold bubble with a navy icon, and
  // its label navy — the seal's colours, as on Home's primary actions.
  static const Color _activeColor = AppColors.navy900;
  static const Color _bubbleColor = AppColors.gold400;
  // Navy, not slate (2026-10 refinement): quieter than the gold bubble, but
  // plainly the app's own colour, and well past AA on the white pill.
  static const Color _inactiveColor = AppColors.navy600;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _activeColor : _inactiveColor;
    return Expanded(
      child: Semantics(
        label: item.label,
        button: true,
        selected: isActive,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          radius: 40,
          child: SizedBox(
            height: EsperanzaNavMotion.barHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Flexible: in the floating pill (8pt shorter than the old
                // bar) a 2x label needs a few points, and this reserved
                // icon slot gives them up — the 24pt icon still fits.
                Flexible(
                  child: SizedBox(
                    height: EsperanzaNavMotion.bubbleDiameter * 0.62,
                    child: isActive
                        ? const SizedBox.shrink()
                        : Center(child: Icon(item.outlineIcon, color: color, size: EsperanzaNavMotion.iconSize)),
                  ),
                ),
                Padding(
                  // 6, not 8: the floating pill is 8pt shorter than the old
                  // full-width bar, and at 2x text the label needs it.
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    // The system text scale is deliberately NOT clamped here.
                    // It used to be capped at 1.3x. Measured 2026-08-29 (FE 05)
                    // with the clamp removed, at 280/320/360/412pt:
                    //   - no overflow at any width, at any scale up to 2.0x;
                    //   - the label grows 12pt -> 23pt, which is the whole point
                    //     for a citizen who set large text;
                    //   - "Profile" already ellipsized at 1.3x *with* the clamp,
                    //     so the clamp never bought legibility — it only made
                    //     the same truncated word smaller.
                    // Ellipsis is visual only: the semantics tree still carries
                    // the full label, so a screen reader is unaffected. The icon
                    // above carries the identity regardless.
                    // nav_access_overflow_test.dart holds this at 2.0x.
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.sans,
                      fontSize: AppTextSize.fine,
                      height: 1.1,
                      color: color,
                      letterSpacing: -0.3,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The travelling active bubble that floats above the bar over whichever
/// slot is selected — direct port of Servana's `_ActiveBubble`.
class EsperanzaActiveBubble extends StatelessWidget {
  final NavItemData item;
  final bool reduced;

  const EsperanzaActiveBubble({super.key, required this.item, required this.reduced});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: EsperanzaNavMotion.bubbleDiameter,
      height: EsperanzaNavMotion.bubbleDiameter,
      // Clay (2026-10 design): a puffy gold ball lit from the top-left — a
      // gradient body, a soft highlight and a warm glow beneath it.
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold300, EsperanzaNavItem._bubbleColor, AppColors.gold600],
          stops: [0, 0.55, 1],
        ),
        border: Border.all(color: AppColors.surface, width: 3),
        boxShadow: [
          BoxShadow(color: AppColors.gold600.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 8), spreadRadius: -3),
          BoxShadow(color: AppColors.navy900.withValues(alpha: 0.18), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      // The clay shading: a highlight pooled at the upper-left over an inner
      // shade at the lower-right, so the ball reads as raised.
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.40, -0.50),
          radius: 0.95,
          colors: [
            AppColors.surface.withValues(alpha: 0.50),
            AppColors.surface.withValues(alpha: 0),
            AppColors.gold700.withValues(alpha: 0.22),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: reduced ? const Duration(milliseconds: 1) : EsperanzaNavMotion.selection,
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: Icon(
            item.filledIcon,
            key: ValueKey(item.label),
            color: AppColors.navy950,
            size: EsperanzaNavMotion.iconSize * EsperanzaNavMotion.activeIconScale,
          ),
        ),
      ),
    );
  }
}
