import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Progress indicator for the registration and request wizards — a labeled
/// "Step X of Y" line over a row of numbered step circles. Per-circle
/// labels are deliberately absent: at 6+ steps they would overflow or need
/// truncation on narrow phones; the current step's name is on the line.
class OnboardingStepIndicator extends StatelessWidget {
  final int currentStep; // 0-based
  final List<String> stepLabels;

  /// The module's colour for the bar and the "Step n of m" label (Tulong's
  /// purple); null keeps the standard blues.
  final Color? accent;

  /// Drawn for a navy ground (the wizards' [NavyBand] header): light text,
  /// gold for the current step and the path walked, translucent white ahead.
  final bool onDark;

  const OnboardingStepIndicator({
    super.key,
    required this.currentStep,
    required this.stepLabels,
    this.accent,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Flexible, not a bare Text: at a large system text scale this
            // counter cannot shrink and pushed the row past its width
            // (measured 2026-08-29 — 35px of overflow at 280pt/200%). It keeps
            // priority over the step label beside it, which ellipsizes first.
            Flexible(
              child: Text(
                'Step ${currentStep + 1} of ${stepLabels.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTextSize.label,
                  fontWeight: FontWeight.w700,
                  color: onDark ? AppColors.gold300 : (accent ?? AppColors.brand600),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                stepLabels[currentStep],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTextSize.label,
                  color: onDark ? AppColors.surface.withValues(alpha: 0.85) : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Numbered circles joined by a line (2026-10 refresh): done steps navy
        // with a check, the current one gold, later ones outlined. No label
        // under each circle; the current step's name is on the line above,
        // which is what keeps a 6- or 8-step form from overflowing.
        Row(
          children: [
            for (int i = 0; i < stepLabels.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= currentStep
                          ? (onDark ? AppColors.gold400 : (accent ?? AppColors.navy700))
                          : (onDark ? AppColors.surface.withValues(alpha: 0.25) : AppColors.slate200),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              _StepDot(
                index: i,
                state: i < currentStep ? _DotState.done : (i == currentStep ? _DotState.current : _DotState.upcoming),
                accent: accent,
                onDark: onDark,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

enum _DotState { done, current, upcoming }

class _StepDot extends StatelessWidget {
  final int index;
  final _DotState state;
  final Color? accent;
  final bool onDark;
  const _StepDot({required this.index, required this.state, this.accent, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final done = state == _DotState.done;
    final current = state == _DotState.current;
    final Color fill;
    final Color fg;
    final Color edge;
    if (onDark) {
      // On navy: the current step gold, the steps behind a clear blue with a
      // check, the steps ahead a faint glass ring.
      fill = current ? AppColors.gold400 : (done ? AppColors.brand500 : AppColors.surface.withValues(alpha: 0.10));
      fg = current ? AppColors.navy950 : AppColors.surface;
      edge = current || done ? fill : AppColors.surface.withValues(alpha: 0.45);
    } else {
      fill = current ? (accent ?? AppColors.gold400) : (done ? (accent ?? AppColors.navy700) : AppColors.surface);
      fg = current ? (accent != null ? AppColors.surface : AppColors.navy950) : (done ? AppColors.surface : AppColors.slate500);
      edge = state == _DotState.upcoming ? AppColors.slate300 : fill;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: current ? 30 : 26,
      height: current ? 30 : 26,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: edge, width: 1.5),
        boxShadow: current ? [BoxShadow(color: fill.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3))] : null,
      ),
      alignment: Alignment.center,
      child: done
          ? Icon(Icons.check_rounded, size: 15, color: fg)
          : Text(
              '${index + 1}',
              style: TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w700, color: fg, height: 1),
            ),
    );
  }
}
