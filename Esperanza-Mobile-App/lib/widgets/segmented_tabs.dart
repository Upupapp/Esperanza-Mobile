import 'package:flutter/material.dart';
import '../theme/app_elevation.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'esperanza_art.dart';

/// A reusable pill/segmented tab control — same visual language reused for
/// the request Active/Done tabs and the Balita/Events tabs. Segments are
/// equal-width (via Expanded) so switching never shifts layout, and each
/// segment is padded to a comfortable tap target rather than relying on
/// tiny text-only hit areas.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color accent;

  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.accent = AppColors.navy800,
  });

  @override
  Widget build(BuildContext context) {
    // A neumorphic well (2026-10 design) holding a raised white pill for the
    // selected segment.
    return NeuWell(
      radius: AppRadius.full,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Segment(
                label: labels[i],
                selected: i == selectedIndex,
                accent: accent,
                onTap: () => onChanged(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _Segment({required this.label, required this.selected, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.clear,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.clear,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: selected
                ? [
                    BoxShadow(color: AppElevation.tabPillShadow, blurRadius: 10, offset: const Offset(0, 3)),
                    BoxShadow(color: AppColors.navy800.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 4)),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextSize.helper,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? accent : AppColors.slate600,
            ),
          ),
        ),
      ),
    );
  }
}
