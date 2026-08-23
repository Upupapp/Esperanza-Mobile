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

  static const Color _activeColor = AppColors.brand500;
  static const Color _inactiveColor = AppColors.slate400;

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
                SizedBox(
                  height: EsperanzaNavMotion.bubbleDiameter * 0.62,
                  child: isActive
                      ? const SizedBox.shrink()
                      : Center(child: Icon(item.outlineIcon, color: color, size: EsperanzaNavMotion.iconSize)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.linear(MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3)),
                    style: TextStyle(
                      fontFamily: AppTypography.sans,
                      fontSize: 10.5,
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
      decoration: BoxDecoration(
        color: EsperanzaNavItem._activeColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 3),
        boxShadow: [
          BoxShadow(color: EsperanzaNavItem._activeColor.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: reduced ? const Duration(milliseconds: 1) : EsperanzaNavMotion.selection,
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: Icon(
            item.filledIcon,
            key: ValueKey(item.label),
            color: Colors.white,
            size: EsperanzaNavMotion.iconSize * EsperanzaNavMotion.activeIconScale,
          ),
        ),
      ),
    );
  }
}
