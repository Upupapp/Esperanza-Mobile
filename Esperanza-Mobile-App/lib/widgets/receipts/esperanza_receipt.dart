import 'package:flutter/material.dart';
import '../../models/receipt.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/esperanza_seal.dart';

/// The single Esperanza municipal payment receipt — used for every payment
/// method (Onsite, GCash, Maya). There is deliberately only one visual
/// design: a citizen who paid via GCash or Maya still receives an
/// Esperanza municipal receipt, not a wallet-app-styled one. The only
/// difference between payment methods is the "Mode of Payment" row's label
/// and badge color (see [_paymentModeLabel]/[_PaymentModeBadge]) — every
/// other value comes from this request's own [Receipt].
/// FRONTEND SIMULATION ONLY — no real payment/print integration.
class EsperanzaReceipt extends StatelessWidget {
  final Receipt receipt;
  const EsperanzaReceipt({super.key, required this.receipt});

  static const _gcashBlue = Color(0xFF0072CE);
  static const _mayaGreen = Color(0xFF00A85A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.slate50,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: AppColors.navy900.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                // Header — municipal identity.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.navy900, AppColors.brand700],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(esperanzaSealAsset, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Municipality of Esperanza, Masbate',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Official Payment Receipt',
                        style: TextStyle(
                          color: AppColors.gold300,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(
                            color: AppColors.emerald700,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _row('Resident Name', receipt.residentName),
                      _row('Service', receipt.serviceName),
                      _row('Request Reference No.', receipt.requestReferenceNumber),
                      _row('Amount Paid', receipt.amount, emphasize: true),
                      _modeOfPaymentRow(),
                      _row('Date & Time', _fmt(receipt.dateTime)),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.sm),
                      _row('Transaction Reference No.', receipt.referenceNumber),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'This is a frontend simulation. No real payment transaction was made.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasize ? 16 : 12.5,
                fontWeight: FontWeight.w700,
                color: emphasize ? AppColors.brand700 : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The one row that differs by payment method — a label plus a small
  /// color-coded badge (see [_PaymentModeBadge]), never a separate receipt
  /// theme. GCash/Maya branding is intentionally reduced to this single
  /// badge + label, not a full logo, so the receipt still reads as an
  /// Esperanza municipal document first.
  Widget _modeOfPaymentRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text('Mode of Payment', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          const SizedBox(width: AppSpacing.md),
          // Expanded + Flexible, matching every other row's label/value
          // split: a fixed-size trailing Row can't shrink, so the longer
          // "Onsite — Municipal Office" label overflowed at phone widths
          // until the value side could wrap like the rest of the receipt.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _PaymentModeBadge(type: receipt.type),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _paymentModeLabel(receipt.type),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _paymentModeLabel(ReceiptType type) => switch (type) {
    ReceiptType.gcash => 'GCash',
    ReceiptType.maya => 'Maya',
    ReceiptType.onsite => 'Onsite — Municipal Office',
  };

  String _fmt(DateTime d) =>
      '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// A small color-coded badge standing in for the payment method's logo.
/// This project has no bundled GCash/Maya brand assets, and reproducing
/// those trademarked logos isn't appropriate for a demo — brand color plus
/// a payment glyph gives the same at-a-glance recognition ("blue GCash",
/// "green Maya") without it. Onsite reuses an Esperanza-appropriate
/// storefront glyph rather than repeating the seal already shown above.
class _PaymentModeBadge extends StatelessWidget {
  final ReceiptType type;
  const _PaymentModeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      ReceiptType.gcash => (EsperanzaReceipt._gcashBlue, Icons.account_balance_wallet_rounded),
      ReceiptType.maya => (EsperanzaReceipt._mayaGreen, Icons.account_balance_wallet_rounded),
      ReceiptType.onsite => (AppColors.brand700, Icons.storefront_rounded),
    };
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 11, color: Colors.white),
    );
  }
}
