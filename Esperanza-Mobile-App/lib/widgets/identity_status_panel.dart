import 'package:flutter/material.dart';

import '../models/identity_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';

/// The resident's IDENTITY status, beside (never inside) the residency panel
/// (VerificationStatusPanel): whether the ID and selfie were confirmed, are
/// being checked, need staff, failed, or were withdrawn by the LGU. Its own
/// small vocabulary (models/identity_status.dart), with its own pill.
class IdentityStatusPanel extends StatelessWidget {
  final IdentityStatus? status;

  /// Offered when the resident can fix it by sending new photos.
  final VoidCallback? onResend;

  /// Offered when no identity check was ever done (registered, "do it later").
  final VoidCallback? onStart;

  const IdentityStatusPanel({super.key, required IdentityStatus this.status, this.onResend}) : onStart = null;

  const IdentityStatusPanel.notStarted({super.key, required this.onStart}) : status = null, onResend = null;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null) return _notStarted();
    return AppCard(
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Icon(status.icon, size: 19, color: status.foreground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identity Verification',
                      style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    IdentityStatusPill(status: status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(status.explanation, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4)),
          if (status.residentCanResend && onResend != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Send a New ID and Selfie', size: AppButtonSize.sm, onPressed: onResend),
          ],
        ],
      ),
    );
  }
}

extension on IdentityStatusPanel {
  Widget _notStarted() {
    return AppCard(
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Icon(Icons.document_scanner_outlined, size: 19, color: AppColors.brand700),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identity Verification',
                      style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text('Not verified yet', style: TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w700, color: AppColors.slate600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Verify your identity with your valid ID and a quick face check. The LGU reviews your residency only after this, and Dokyu and Tulong open once both are done.',
            style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
          ),
          if (onStart != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Verify My Identity', size: AppButtonSize.sm, onPressed: onStart),
          ],
        ],
      ),
    );
  }
}

/// The identity status as a small pill: icon and label, never colour alone.
class IdentityStatusPill extends StatelessWidget {
  final IdentityStatus status;
  const IdentityStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Identity ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 13, color: status.foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                status.label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.fine.copyWith(color: status.foreground, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
