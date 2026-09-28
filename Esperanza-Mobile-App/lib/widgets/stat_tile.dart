import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum StatTileColor { brand, green, purple, orange, red, gold }

/// Mirrors `resources/views/components/ui/stat-card.blade.php`'s color map
/// and layout (icon chip top-left, value, label).
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final StatTileColor color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = StatTileColor.brand,
    this.onTap,
  });

  ({Color bg, Color fg}) get _colors => switch (color) {
    StatTileColor.brand => (bg: AppColors.brand50, fg: AppColors.brand600),
    StatTileColor.green => (bg: AppColors.emerald50, fg: AppColors.emerald700),
    StatTileColor.purple => (bg: AppColors.purple50, fg: AppColors.purple700),
    StatTileColor.orange => (bg: AppColors.orange50, fg: AppColors.orange700),
    StatTileColor.red => (bg: AppColors.rose50, fg: AppColors.rose700),
    StatTileColor.gold => (bg: AppColors.gold50, fg: AppColors.gold700),
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Icon(icon, size: 17, color: c.fg),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                value,
                style: const TextStyle(fontSize: AppTextSize.section, fontWeight: FontWeight.w700, color: AppColors.navy900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: AppTextSize.fine,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
