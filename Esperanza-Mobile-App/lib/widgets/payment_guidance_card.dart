import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

import '../l10n/tr.dart';
/// Before filing, how the fee is paid, as the website's Payment step says it
/// (document-requests.blade.php): in person at the office, assessed when
/// submitted, the "not yet ruled" note where the LGU has not decided the fee,
/// and never to an e-wallet. A free service says so instead, when
/// [sayWhenFree] (Dokyu does; Tulong, like the website, says nothing).
/// A free service is free even while the LGU has not ruled on it: Medical
/// Assistance (AICS) told residents how to pay a fee it does not have
/// (2026-11-12). The "not yet ruled" note is for a service with a fee.
class PaymentGuidanceCard extends StatelessWidget {
  const PaymentGuidanceCard({super.key, required this.item, this.sayWhenFree = true});

  final CatalogItem item;
  final bool sayWhenFree;

  bool get _free => item.fee.trim().isEmpty || item.fee.toLowerCase() == 'free';

  @override
  Widget build(BuildContext context) {
    if (_free) {
      if (!sayWhenFree) return const SizedBox.shrink();
      return AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.emerald700, size: AppSizes.iconBase),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('No Payment Required'), style: AppTypography.cardHeading),
                  Text('${item.name} is issued free of charge.', style: AppTypography.helper),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final bullets = [
      'You pay the fee in person at the office listed, which gives you an official receipt.',
      'The exact amount is assessed when you submit, and shows on your request.',
      if (item.policyBlocked) "The LGU has not yet ruled on this service's fee; the office will confirm it.",
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: AppColors.brand600, size: AppSizes.iconBase),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(tr('How to pay'), style: AppTypography.cardHeading)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(Icons.circle, size: 5, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(b, style: AppTypography.helper.copyWith(color: AppColors.textBody))),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, size: AppSizes.iconSm, color: AppColors.amber700),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    tr('Never send payment to an e-wallet or account the Municipality has not confirmed.'),
                    style: AppTypography.helper.copyWith(color: AppColors.amber700, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xl),
          _row(tr('Collecting office'), item.office),
          _row(tr('Total due'), item.fee),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: AppTypography.helper)),
        Expanded(child: Text(value, style: AppTypography.bodySmallMedium.copyWith(color: AppColors.textPrimary))),
      ],
    ),
  );
}
