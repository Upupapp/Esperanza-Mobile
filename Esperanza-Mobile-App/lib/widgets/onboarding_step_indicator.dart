import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Progress indicator for the registration/verification wizard (Section
/// 9) — a labeled "Step X of Y" line plus a row of segment bars, rather
/// than per-step circular dots with under-labels: at 6 steps, individual
/// labels would either overflow or need truncation on narrow phones. The
/// segment-bar approach scales to any step count without that risk while
/// still making completed/current/upcoming instantly readable.
class OnboardingStepIndicator extends StatelessWidget {
  final int currentStep; // 0-based
  final List<String> stepLabels;

  const OnboardingStepIndicator({super.key, required this.currentStep, required this.stepLabels});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step ${currentStep + 1} of ${stepLabels.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand600),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stepLabels[currentStep],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int i = 0; i < stepLabels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= currentStep ? AppColors.brand500 : AppColors.slate200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
