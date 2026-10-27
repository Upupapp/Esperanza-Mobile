import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// The household's code in the barangay's resident registry (e.g.
/// HH-2026-0004), as on the website's Resident Profile card (2026-10-27).
/// The server assigns it; the resident reads it here and can copy it, and
/// staff use it on the evacuation and relief forms. Until the barangay
/// verifies the profile it is said to be awaiting their confirmation.
class HouseholdCodeCard extends StatelessWidget {
  const HouseholdCodeCard({super.key, required this.code, required this.verified});

  final String code;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.home_outlined, size: 22, color: AppColors.brand600),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Household code'), style: AppTypography.labelText),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(code, style: AppTypography.cardTitle.copyWith(letterSpacing: 0.5)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tr("Your household's code in the barangay's resident registry. Staff use it on evacuation and relief forms."),
                  style: AppTypography.helper,
                ),
                if (!verified) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    tr('Your barangay office confirms it when it verifies your profile.'),
                    style: AppTypography.helper.copyWith(color: AppColors.amber700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
