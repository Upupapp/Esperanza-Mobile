import 'package:flutter/material.dart';
import '../models/citizen_account.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_status.dart';
import '../theme/app_typography.dart';
import '../utils/demo_resident_photo.dart';

/// A tappable "quick demo login" row on the login screen. Previously this
/// was an inline `OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(
/// vertical: 12), ...)` — specifying only `vertical` there implicitly
/// zeroes `horizontal` (EdgeInsets.symmetric defaults omitted axes to 0),
/// which silently overrides the app-wide OutlinedButtonTheme's horizontal
/// padding entirely (widget-level ButtonStyle properties replace the
/// theme's rather than merging within themselves), leaving the avatar
/// flush against the card's left edge. Built as its own widget with an
/// explicit, comfortable padding so that mistake can't recur.
///
/// The "Verified User" / "Unverified User" badge is derived from
/// `account.status` (the same AppStatus vocabulary used everywhere else)
/// rather than a separate label passed in at the call site, so the two
/// demo accounts can never show a badge that disagrees with what signing
/// in as them will actually behave like.
class DemoAccountCard extends StatelessWidget {
  final CitizenAccount account;
  final VoidCallback? onTap;

  /// Overrides the primary label (normally [account.fullName]) — used by
  /// the Phase 6 duplicate-account demo button so it reads as clearly
  /// distinct from the real Perlita Quiambao card rather than showing an
  /// identical name twice.
  final String? label;

  const DemoAccountCard({super.key, required this.account, required this.onTap, this.label});

  bool get _isVerified => AppStatusX.fromLabel(account.status) == AppStatus.approved;

  @override
  Widget build(BuildContext context) {
    final badgeColor = _isVerified ? AppColors.emerald700 : AppColors.amber700;
    final badgeBg = _isVerified ? AppColors.emerald50 : AppColors.amber50;
    final photo = demoProfileImageFor(account);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brand50,
                backgroundImage: photo,
                child: photo == null
                    ? Text(
                        account.initials,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand600),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label ?? account.fullName, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      'Brgy. ${account.barangay}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  _isVerified ? 'Verified User' : 'Unverified User',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.slate300),
            ],
          ),
        ),
      ),
    );
  }
}
