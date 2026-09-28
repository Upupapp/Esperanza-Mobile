import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Centralized confirmation dialog + toast helpers so every screen shows
/// confirmations/success/error feedback consistently (Section 2 of the
/// alignment doc — reusable states, not per-screen one-offs).
class AppDialogs {
  AppDialogs._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool danger = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        danger: danger,
      ),
    );
    return result ?? false;
  }

  /// A single-button acknowledgment sheet — same visual shell as
  /// [confirm], for a message that only needs a dismiss action (e.g. "a
  /// permission wasn't granted, but you can keep using the app").
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InfoSheet(title: title, message: message, actionLabel: actionLabel),
    );
  }

  /// Same title/message/actions shape as [confirm], but presented as a
  /// centered dialog (`showDialog`/`Dialog`) rather than a bottom sheet —
  /// reserved for the rarer, higher-stakes confirmations (e.g. changing a
  /// profile photo bound to a 6-month cooldown) that should read as
  /// distinctly different from routine bottom-sheet confirmations.
  static Future<bool> centeredConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CenteredConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        danger: danger,
      ),
    );
    return result ?? false;
  }

  /// Centered single-button counterpart to [info] — see [centeredConfirm].
  static Future<void> centeredInfo(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _CenteredInfoDialog(title: title, message: message, actionLabel: actionLabel),
    );
  }

  static void toast(BuildContext context, String message, {bool success = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_rounded,
              size: 18,
              color: success ? AppColors.emerald500 : AppColors.brand400,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;

  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrollable rather than sized-to-content: a long message (a
            // policy explanation, say) would otherwise overflow the sheet
            // on a short device instead of the actions staying reachable.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate500, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ConfirmActions(cancelLabel: cancelLabel, confirmLabel: confirmLabel, danger: danger),
          ],
        ),
      ),
    );
  }
}

class _CenteredConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;

  const _CenteredConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate500, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ConfirmActions(cancelLabel: cancelLabel, confirmLabel: confirmLabel, danger: danger),
          ],
        ),
      ),
    );
  }
}

class _CenteredInfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;

  const _CenteredInfoDialog({required this.title, required this.message, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate500, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: actionLabel,
              variant: AppButtonVariant.primary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;

  const _InfoSheet({required this.title, required this.message, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scrollable rather than sized-to-content — see _ConfirmSheet's
            // matching comment.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate500, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: actionLabel,
              variant: AppButtonVariant.primary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cancel + confirm, side by side when both labels fit a half-width button,
/// otherwise stacked full width with the confirm action on top.
///
/// Side by side only, "View Existing Request" and "Go to My Verified
/// Account" were cut to "View Existing R…": the action a resident had to
/// read to choose was the one they could not read.
class _ConfirmActions extends StatelessWidget {
  const _ConfirmActions({required this.cancelLabel, required this.confirmLabel, required this.danger});

  final String cancelLabel;
  final String confirmLabel;
  final bool danger;

  /// AppButton's md size: 18pt horizontal padding each side.
  static const double _buttonPadding = 36;

  bool _fits(BuildContext context, String label, double width) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: AppTypography.button),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width + _buttonPadding <= width;
  }

  @override
  Widget build(BuildContext context) {
    final cancel = AppButton(
      label: cancelLabel,
      variant: AppButtonVariant.secondary,
      fullWidth: true,
      onPressed: () => Navigator.of(context).pop(false),
    );
    final confirm = AppButton(
      label: confirmLabel,
      variant: danger ? AppButtonVariant.danger : AppButtonVariant.primary,
      fullWidth: true,
      onPressed: () => Navigator.of(context).pop(true),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - AppSpacing.sm) / 2;
        if (_fits(context, cancelLabel, half) && _fits(context, confirmLabel, half)) {
          return Row(
            children: [
              Expanded(child: cancel),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: confirm),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [confirm, const SizedBox(height: AppSpacing.sm), cancel],
        );
      },
    );
  }
}

