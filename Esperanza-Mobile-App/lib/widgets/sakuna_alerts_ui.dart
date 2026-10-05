import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/citizen_session_service.dart';
import '../services/notifications_service.dart';
import '../services/sakuna_alerts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A Sakuna alert the LGU published for the resident's barangay, opened as a
/// dialog the moment the app picks it up (it refreshes every minute while
/// open, and on return to the app). Before, an alert reached only someone who
/// happened to open the Emergency tab (QA run 2026-10-05).
class SakunaAlertDialog {
  SakunaAlertDialog._();

  /// Returns true when the resident chose to open the Emergency tab.
  static Future<bool> show(BuildContext context, ServerNotification alert) async {
    final open = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        icon: const Icon(Icons.campaign_rounded, color: AppColors.rose600, size: 32),
        title: Column(
          children: [
            if (alert.pill != null)
              Text(
                alert.pill!.toUpperCase(),
                style: const TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w700, color: AppColors.rose700, letterSpacing: 0.6),
              ),
            const SizedBox(height: 4),
            Text(alert.title, textAlign: TextAlign.center, style: AppTypography.cardHeading),
          ],
        ),
        content: Text(alert.body, style: AppTypography.bodyText),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Close')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Emergency'),
          ),
        ],
      ),
    );
    return open ?? false;
  }
}

/// The alerts in force for the resident's barangay, at the top of Home, like
/// the website's dashboard. Refreshes every minute while Home is alive.
class ActiveAlertsCard extends StatefulWidget {
  final VoidCallback? onOpen;
  const ActiveAlertsCard({super.key, this.onOpen});

  @override
  State<ActiveAlertsCard> createState() => _ActiveAlertsCardState();
}

class _ActiveAlertsCardState extends State<ActiveAlertsCard> {
  List<PublicAlert> _alerts = const [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final barangay = context.read<CitizenSessionService>().account?.barangay;
      final alerts = await SakunaAlerts.load(barangay: barangay);
      if (mounted) setState(() => _alerts = alerts);
    } on ApiException {
      // Keep what is shown; the next minute tries again.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alerts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          for (final alert in _alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: AppColors.rose50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: widget.onOpen,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.rose600.withValues(alpha: 0.35), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.campaign_rounded, color: AppColors.rose600, size: 22),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (alert.level != null)
                                Text(
                                  alert.level!.toUpperCase(),
                                  style: const TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w700, color: AppColors.rose700, letterSpacing: 0.6),
                                ),
                              Text(alert.title, style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.rose700)),
                              if (alert.body.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(alert.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.slate700)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
