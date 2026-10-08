import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Reusable "New Request" floating action button, used by both Dokyu and
/// Tulong.
///
/// 2026-10 design: the screen's main action, so it is the gold primary pill
/// with navy text and a warm glow, the same on both modules (gold is the
/// action colour throughout). [accent] (the module colour) is kept for the
/// call sites; the module still shows in the screen's tabs and cards.
class NewRequestFab extends StatelessWidget {
  final Color accent;
  final VoidCallback onPressed;
  final String label;
  final Object heroTag;

  const NewRequestFab({
    super.key,
    required this.accent,
    required this.onPressed,
    required this.heroTag,
    this.label = 'New Request',
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(color: AppColors.gold500.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -4),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.gold400,
        foregroundColor: AppColors.navy950,
        splashColor: AppColors.surface.withValues(alpha: 0.30),
        icon: const Icon(Icons.add_rounded, color: AppColors.navy950),
        label: Text(
          label,
          style: const TextStyle(color: AppColors.navy950, fontWeight: FontWeight.w700, fontSize: AppTextSize.body),
        ),
      ),
    );
  }
}
