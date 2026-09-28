import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// A comfortably-sized, tappable row used for hub/menu-style navigation
/// lists (Profile menu today; any future settings-style list tomorrow).
/// Sized for a real mobile touch target (~64dp) rather than a
/// content-only Row, per ESPERANZA_MOBILE_WEB_ALIGNMENT.md's "reuse before
/// duplicating" rule.
class MenuListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const MenuListTile({super.key, required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.rose600 : AppColors.slate700;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: danger ? AppColors.rose50 : AppColors.slate100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 20, color: danger ? AppColors.rose500 : AppColors.slate500),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600, color: color),
              ),
            ),
            if (!danger) const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
          ],
        ),
      ),
    );
  }
}
