import 'package:flutter/material.dart';
import '../../models/receipt.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_spacing.dart';
import '../../utils/receipt_export.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/receipts/esperanza_receipt.dart';

/// Displays a request's own generated [Receipt] — always the same receipt
/// for the same request, re-opened from "View Receipt" on its detail
/// screen for as long as this demo session lasts. Renders the single
/// [EsperanzaReceipt] design (payment method only changes its "Mode of
/// Payment" row, never the overall layout) and wraps it in a
/// [RepaintBoundary] so "Download Receipt" exports exactly what's shown,
/// not a separately-built export layout.
class ReceiptScreen extends StatefulWidget {
  final Receipt receipt;
  const ReceiptScreen({super.key, required this.receipt});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _boundaryKey = GlobalKey();
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final bytes = await captureRepaintBoundary(_boundaryKey);
      final filename = receiptFilename(widget.receipt);
      await exportReceiptBytes(bytes: bytes, filename: filename);
      AppHaptics.success();
      if (mounted) {
        AppDialogs.toast(context, 'Receipt downloaded successfully. You can also view it anytime in Transactions.');
      }
    } catch (_) {
      if (mounted) AppDialogs.toast(context, "Couldn't download the receipt. Please try again.", success: false);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Receipt'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: RepaintBoundary(
            key: _boundaryKey,
            child: EsperanzaReceipt(receipt: receipt),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
          child: AppButton(
            label: 'Download Receipt',
            icon: Icons.download_rounded,
            fullWidth: true,
            loading: _downloading,
            onPressed: _downloading ? null : _download,
          ),
        ),
      ),
    );
  }
}
