import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'service_launcher_menu.dart';

import '../l10n/tr.dart';
/// "You are verified!" - opened once, on whatever tab is showing, when the
/// LGU's account-verified notice arrives (the website's verified-popup).
/// Before, it was only a dot on the bell while Dokyu and Tulong still said
/// to wait for approval.
class VerifiedWelcomeDialog {
  VerifiedWelcomeDialog._();

  /// Which service the resident chose to open, or null for neither.
  static Future<ServiceLauncherTarget?> show(BuildContext context) => showDialog<ServiceLauncherTarget>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          icon: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: const Icon(Icons.verified_rounded, color: AppColors.emerald700, size: 26),
          ),
          title: Text(tr('You are verified!'), textAlign: TextAlign.center, style: AppTypography.cardHeading),
          content: Text(
            tr('The LGU has verified your account. You can now request documents in Dokyu or apply for assistance in Tulong.'),
            textAlign: TextAlign.center,
            style: AppTypography.bodyText,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowAlignment: OverflowBarAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(ServiceLauncherTarget.tulong),
              child: Text(tr('Apply for Tulong')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(ServiceLauncherTarget.dokyu),
              icon: const Icon(Icons.note_add_outlined, size: 18),
              label: Text(tr('Request a Document')),
            ),
          ],
        ),
      );
}
