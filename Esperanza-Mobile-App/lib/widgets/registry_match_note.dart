import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The resident was recognised as a record their barangay already had
/// (`registry_match` pending, 2026-10-09), in the website's words and, in
/// Filipino, the website's Filipino (it was English only; flow guide
/// 2026-11-13, Residents bug 7).
class RegistryMatchNote extends StatelessWidget {
  /// At sign-up: the record will be linked once the barangay verifies.
  static String get atSignUp =>
      tr("We found you in your barangay's registry. It will be linked to your account when the barangay office verifies you.");

  /// On the Resident Profile, until the barangay confirms it.
  static String get onProfile =>
      tr('Your barangay already has a record of you. The barangay office confirms it when they verify your account; until then you see only the details you gave.');

  final String text;
  const RegistryMatchNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.how_to_reg_outlined, size: 16, color: AppColors.brand800),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text, style: AppTypography.fine.copyWith(color: AppColors.brand800, height: 1.4))),
          ],
        ),
      );
}
