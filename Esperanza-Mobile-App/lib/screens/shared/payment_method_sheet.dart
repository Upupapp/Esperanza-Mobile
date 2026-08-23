import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_spacing.dart';

/// Waiting for Payment's method picker — Onsite or a simulated online
/// option (GCash / Maya, the two mobile wallets already referenced
/// elsewhere in this project's reference material). FRONTEND SIMULATION
/// ONLY: selecting GCash/Maya never performs a real transaction — see the
/// "Demo / Simulation" badge on each online option and
/// docs on Phase 5's payment simulation. Returns the chosen method label
/// ('Onsite' / 'GCash' / 'Maya') via [show], or null if dismissed without
/// choosing.
class PaymentMethodSheet extends StatelessWidget {
  final Color accent;
  final String feeAmount;

  const PaymentMethodSheet({super.key, required this.accent, required this.feeAmount});

  static Future<String?> show(BuildContext context, {required Color accent, required String feeAmount}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PaymentMethodSheet(accent: accent, feeAmount: feeAmount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Choose Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Required fee for this request: $feeAmount',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xl),
            _MethodTile(
              icon: Icons.storefront_outlined,
              iconColor: accent,
              title: 'Pay at Municipal Office',
              subtitle: 'Onsite — settle the fee in person when you visit or claim your document.',
              onTap: () {
                AppHaptics.selection();
                Navigator.of(context).pop('Onsite');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _MethodTile(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.brand600,
              title: 'GCash',
              subtitle: 'Simulated online payment — no real transaction is made.',
              demo: true,
              onTap: () {
                AppHaptics.selection();
                Navigator.of(context).pop('GCash');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _MethodTile(
              icon: Icons.credit_card_outlined,
              iconColor: AppColors.emerald700,
              title: 'Maya',
              subtitle: 'Simulated online payment — no real transaction is made.',
              demo: true,
              onTap: () {
                AppHaptics.selection();
                Navigator.of(context).pop('Maya');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool demo;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.demo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: iconColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                        if (demo) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(999)),
                            child: const Text(
                              'DEMO',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.amber700, letterSpacing: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.3)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
            ],
          ),
        ),
      ),
    );
  }
}
