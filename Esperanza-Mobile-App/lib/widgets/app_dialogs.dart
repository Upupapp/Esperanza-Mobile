import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
    bool danger = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        danger: danger,
      ),
    );
    return result ?? false;
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
            const SizedBox(width: 10),
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
  final bool danger;

  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 13.5, color: AppColors.slate500, height: 1.4)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: danger ? AppButtonVariant.danger : AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
