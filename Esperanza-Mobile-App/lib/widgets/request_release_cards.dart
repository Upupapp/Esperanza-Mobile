import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/request_release.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_text.dart';
import '../utils/peso_text.dart';
import 'app_card.dart';
import 'app_dialogs.dart';
import 'image_viewer_scaffold.dart';

/// Where and how to claim a request that is ready (owner, 2026-10-15): the
/// office, its contact and hours, what to bring, and a fee still to pay.
class PickupCard extends StatelessWidget {
  const PickupCard({super.key, required this.pickup, required this.reference, required this.accent});

  final RequestPickup pickup;
  final String reference;
  final Color accent;

  String _bring(String key) => switch (key) {
    'valid_id' => 'A valid ID',
    'reference_number' => 'Your reference number, $reference',
    'fee' =>
      pickup.feeDue == null
          ? 'The fee, paid at the office before release'
          : 'The fee of ${pesoText(pickup.feeDue)}, paid at the office before release',
    _ => key,
  };

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^0-9+]'), ''));
    if (!await launchUrl(uri) && context.mounted) {
      AppDialogs.toast(context, 'Could not open the phone app.', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, size: AppSizes.iconBase, color: accent),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: Text('Ready to claim', style: AppTypography.cardHeading)),
            ],
          ),
          if (pickup.readySince != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Ready since ${shortDate(pickup.readySince!)}', style: AppTypography.helper),
          ],
          const SizedBox(height: AppSpacing.headingGap),
          _Line(label: 'Where', value: pickup.office ?? 'The office handling your request'),
          if (pickup.officeHours != null) _Line(label: 'Hours', value: pickup.officeHours!),
          if (pickup.officeContact != null)
            _Line(label: 'Contact', value: pickup.officeContact!, onTap: () => _call(context, pickup.officeContact!)),
          if (pickup.bring.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text('Bring', style: AppTypography.labelText),
            const SizedBox(height: AppSpacing.xs),
            for (final key in pickup.bring)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle_outline_rounded, size: AppSizes.iconSm, color: accent),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(_bring(key), style: AppTypography.bodyText)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      value,
      style: AppTypography.bodyText.copyWith(
        fontWeight: FontWeight.w600,
        color: onTap == null ? AppColors.textPrimary : AppColors.brand700,
        decoration: onTap == null ? null : TextDecoration.underline,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: AppTypography.helper)),
          Expanded(
            child: onTap == null
                ? text
                : Semantics(
                    button: true,
                    label: 'Call $value',
                    // The number is the label; read once, not twice.
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: onTap,
                      // A full-height touch target, not the 22 pt of one line of text.
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
                        child: Align(alignment: Alignment.centerLeft, child: text),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The documents issued for a request (owner, 2026-10-15): each one's
/// control number and dates, whether it is still valid, the QR anyone can
/// scan to check it, and the scan of the signed paper - the resident's
/// digital copy. The paper stays the official document.
class IssuedDocumentsCard extends StatelessWidget {
  const IssuedDocumentsCard({super.key, required this.documents, required this.accent});

  final List<IssuedDocumentInfo> documents;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: AppSizes.iconBase, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  documents.length == 1 ? 'Your document' : 'Your documents',
                  style: AppTypography.cardHeading,
                ),
              ),
            ],
          ),
          for (final (i, d) in documents.indexed) ...[
            if (i > 0) const Divider(height: AppSpacing.xxl),
            const SizedBox(height: AppSpacing.headingGap),
            _IssuedDocument(document: d, accent: accent),
          ],
        ],
      ),
    );
  }
}

class _IssuedDocument extends StatelessWidget {
  const _IssuedDocument({required this.document, required this.accent});

  final IssuedDocumentInfo document;
  final Color accent;

  Future<void> _open(BuildContext context, String url, {bool image = false}) async {
    if (image) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScaffold(
            title: 'Signed copy',
            image: NetworkImage(url),
            semanticLabel: 'Signed copy of ${document.controlNumber}',
          ),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        AppDialogs.toast(context, 'Could not open it. Pull down to refresh, then try again.', success: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = document;
    final (label, fg, bg) = d.revoked
        ? ('Revoked', AppColors.rose700, AppColors.rose50)
        : d.expired
        ? ('Expired', AppColors.amber700, AppColors.amber50)
        : ('Valid', AppColors.emerald700, AppColors.emerald50);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.controlNumber,
                    style: AppTypography.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (d.isReprint)
                    Text('Reprint${d.reprintNumber > 0 ? ' ${d.reprintNumber}' : ''}', style: AppTypography.helper),
                  if (d.issuedOn != null) Text('Issued ${shortDate(d.issuedOn!)}', style: AppTypography.helper),
                  if (d.validUntil != null)
                    Text('Valid until ${shortDate(d.validUntil!)}', style: AppTypography.helper),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
              child: Text(label, style: AppTypography.labelText.copyWith(color: fg)),
            ),
          ],
        ),
        if (d.revoked) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The office withdrew this document${d.revokedReason == null ? '.' : ': ${d.revokedReason}'}',
            style: AppTypography.bodyText.copyWith(color: AppColors.rose700),
          ),
        ],
        if (!d.revoked && d.verifyUrl != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                label: 'Verification QR code for ${d.controlNumber}',
                image: true,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: QrImageView(data: d.verifyUrl!, size: 96, padding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Anyone can scan this code to check that the document is genuine and still valid.',
                  style: AppTypography.helper,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            if (d.scanUrl != null)
              FilledButton.tonalIcon(
                onPressed: () => _open(context, d.scanUrl!, image: !d.isPdf),
                icon: const Icon(Icons.description_outlined, size: AppSizes.iconSm),
                label: const Text('View signed copy'),
              ),
            if (!d.revoked && d.verifyUrl != null)
              TextButton.icon(
                onPressed: () => _open(context, d.verifyUrl!),
                icon: const Icon(Icons.open_in_new_rounded, size: AppSizes.iconSm),
                label: const Text('Check online'),
              ),
          ],
        ),
        if (!d.revoked && !d.hasScan)
          const Text(
            'The office has not attached a signed copy yet. The paper copy you claim is the official document.',
            style: AppTypography.helper,
          ),
      ],
    );
  }
}
