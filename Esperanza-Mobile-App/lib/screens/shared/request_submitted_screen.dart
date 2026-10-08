import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import 'request_detail_screen.dart';
import '../../theme/app_typography.dart';
import '../../widgets/esperanza_art.dart';

/// "Show confirmation" step from Section 5 — a dedicated success screen
/// (not just a toast) so the submission feels real and gives the citizen
/// their reference number to note down, mirroring how a real government
/// service confirms a filed request.
///
/// "Track This Request" navigates using THIS screen's own [context] rather
/// than accepting a `VoidCallback` built by whichever screen pushed this
/// one — that closure would capture the pushing screen's own context,
/// which `pushReplacement` disposes the moment this screen takes its
/// place. Tapping the button then throws "Looking up a deactivated
/// widget's ancestor is unsafe" and silently does nothing, which is
/// exactly the bug this shape avoids: [requestId] is plain data, safe to
/// carry across the replacement, and the navigation itself always runs
/// against this screen's own still-live context.
class RequestSubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final String typeName;
  final Color accent;
  final String requestId;

  const RequestSubmittedScreen({
    super.key,
    required this.referenceNumber,
    required this.typeName,
    required this.accent,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scrolls when it must (a short phone, a large text size), centred
      // otherwise.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.xxl * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SuccessIllustration(),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Request Submitted',
                style: TextStyle(fontSize: AppTextSize.section, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                typeName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate500),
              ),
              const SizedBox(height: AppSpacing.xl),
              GlassSurface(
                radius: AppRadius.xl,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                child: Column(
                  children: [
                    const Text(
                      'REFERENCE NUMBER',
                      style: TextStyle(
                        fontSize: AppTextSize.fine,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      referenceNumber,
                      style: TextStyle(fontSize: AppTextSize.section, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Your request status is now "Submitted". You\'ll be notified as it moves through review, approval, and release.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.huge),
              AppButton(
                label: 'Track This Request',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: requestId)),
                ),
                fullWidth: true,
                size: AppButtonSize.lg,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Back to Home',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                fullWidth: true,
              ),
            ],
          ),
          ),
          ),
        ),
      ),
    );
  }
}
