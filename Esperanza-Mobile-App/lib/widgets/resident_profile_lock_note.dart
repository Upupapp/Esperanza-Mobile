import 'package:flutter/material.dart';

import '../models/resident_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Why the Resident Profile cannot be changed here right now, in the
/// website's words: it can be filled in or corrected only while it is
/// Unverified (not yet sent, or sent back by the barangay). While the
/// barangay checks it, or once it is verified, it is shown, not edited
/// (app/web parity, 2026-10-23).
class ResidentProfileLockNote extends StatelessWidget {
  const ResidentProfileLockNote({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final verified = status == VerificationStatus.verified;
    final fg = verified ? AppColors.emerald700 : AppColors.brand700;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: verified ? AppColors.emerald50 : AppColors.brand50,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(verified ? Icons.verified_outlined : Icons.hourglass_top_rounded, size: AppSizes.iconSm, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                verified
                    ? "Your barangay office verified your information and your household's. "
                          'To change something, ask your barangay office.'
                    : 'Your barangay office is reviewing it. You will be told when it is done, '
                          'and you can change it again if they send it back.',
                style: AppTypography.helper.copyWith(color: fg, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The form while the barangay has the profile: greyed out and not
/// tappable, so it reads as shown, not editable (owner, 2026-10-23).
class ResidentProfileViewOnly extends StatelessWidget {
  const ResidentProfileViewOnly({super.key, required this.locked, required this.child});

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return IgnorePointer(
      child: Opacity(opacity: 0.55, child: child),
    );
  }
}
