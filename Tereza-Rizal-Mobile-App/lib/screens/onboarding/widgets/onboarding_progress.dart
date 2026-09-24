import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import 'onboarding_parallax_layer.dart';

/// Page progress that responds continuously to the swipe rather than snapping
/// at the page boundary.
///
/// Ported from the Servana client's `WelcomePageIndicator`: each segment's
/// width and opacity track how close the live scroll position is to that page,
/// so at the half-way point of a drag both segments are the same size. A dot
/// that jumps on `onPageChanged` tells the citizen where they *arrived*; this
/// one tells them where they *are*.
///
/// Distinguished by width **and** colour, never colour alone. The segments
/// themselves are excluded from semantics — three unlabelled containers read
/// aloud is worse than silence — and the group announces its position once.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.controller,
    required this.page,
    required this.count,
    required this.reduceMotion,
  });

  final PageController controller;

  /// The settled page, used for the announcement. The visual uses the live
  /// position instead.
  final int page;
  final int count;
  final bool reduceMotion;

  static const double _height = 6;
  static const double _minWidth = 8;
  static const double _maxWidth = 28;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${page + 1} of $count',
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final progress = reduceMotion
                ? page.toDouble()
                : OnboardingParallaxLayer.progressOf(controller);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (var i = 0; i < count; i++) _segment(i, progress)],
            );
          },
        ),
      ),
    );
  }

  Widget _segment(int i, double progress) {
    // 1.0 on this page, 0.0 a full page away.
    final active = (1.0 - (progress - i).abs()).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs - 1),
      width: _minWidth + (_maxWidth - _minWidth) * active,
      height: _height,
      decoration: BoxDecoration(
        color: Color.lerp(
          AppColors.surface.withValues(alpha: 0.38),
          AppColors.surface,
          active,
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}
