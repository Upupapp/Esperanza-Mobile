import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/request_release.dart';
import '../screens/shared/pdf_viewer_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_text.dart';
import '../utils/peso_text.dart';
import 'app_card.dart';
import 'app_dialogs.dart';
import 'image_viewer_scaffold.dart';

import '../l10n/tr.dart';
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
              Expanded(child: Text(tr('Ready to claim'), style: AppTypography.cardHeading)),
            ],
          ),
          if (pickup.readySince != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Ready since ${shortDate(pickup.readySince!)}', style: AppTypography.helper),
          ],
          const SizedBox(height: AppSpacing.headingGap),
          _Line(label: tr('Where'), value: pickup.office ?? 'The office handling your request'),
          if (pickup.officeHours != null) _Line(label: tr('Hours'), value: pickup.officeHours!),
          if (pickup.officeContact != null)
            _Line(label: 'Contact', value: pickup.officeContact!, onTap: () => _call(context, pickup.officeContact!)),
          if (pickup.bring.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(tr('Bring'), style: AppTypography.labelText),
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
  const IssuedDocumentsCard({super.key, required this.documents, required this.accent, this.reload});

  final List<IssuedDocumentInfo> documents;
  final Color accent;

  /// Reads the request again and gives its documents: a signed copy's link
  /// lasts five minutes from when the request was read, so it is read again
  /// before the copy opens (QA 2026-11-18). Without it the link as read is used.
  final Future<List<IssuedDocumentInfo>> Function()? reload;

  /// Fetches a signed copy. Tests swap it out; null is the network.
  @visibleForTesting
  static Future<http.Response> Function(Uri uri)? debugFetch;

  /// Whether a signed copy is a PDF. Its link (a signed `/files/<id>` route)
  /// names no type, and the server sends every file as
  /// application/octet-stream: the link never ended in .pdf, so every PDF
  /// went to the image viewer and showed "Preview not available" (QA
  /// 2026-11-18). The file itself says: a PDF starts with "%PDF-", within
  /// its first kilobyte.
  static bool isPdf(Uint8List bytes) {
    final head = bytes.length > 1024 ? bytes.sublist(0, 1024) : bytes;
    return latin1.decode(head).contains('%PDF-');
  }

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
            _IssuedDocument(document: d, accent: accent, reload: reload),
          ],
        ],
      ),
    );
  }
}

class _IssuedDocument extends StatefulWidget {
  const _IssuedDocument({required this.document, required this.accent, this.reload});

  final IssuedDocumentInfo document;
  final Color accent;
  final Future<List<IssuedDocumentInfo>> Function()? reload;

  @override
  State<_IssuedDocument> createState() => _IssuedDocumentState();
}

class _IssuedDocumentState extends State<_IssuedDocument> {
  bool _opening = false;

  static const _notOpened = 'The signed copy could not be opened. Check your connection and try again.';

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) AppDialogs.toast(context, 'Could not open it. Check your connection and try again.', success: false);
    }
  }

  /// The signed copy, from a link read just now, in the viewer its file
  /// calls for: the PDF viewer or the image viewer.
  Future<void> _openSignedCopy() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      var url = widget.document.scanUrl;
      final reload = widget.reload;
      if (reload != null) {
        try {
          for (final d in await reload()) {
            if (d.controlNumber == widget.document.controlNumber) url = d.scanUrl;
          }
        } catch (_) {
          // Not read again (offline): the link as read may still be good.
        }
      }
      if (!mounted) return;
      if (url == null) {
        AppDialogs.toast(context, 'The signed copy is no longer available.', success: false);
        return;
      }
      // The web build hands the link to the browser, which shows either.
      if (!PdfViewerScreen.supported) return await _launch(url);
      final uri = Uri.tryParse(url);
      Uint8List? bytes;
      if (uri != null) {
        try {
          final res = await (IssuedDocumentsCard.debugFetch ?? http.get)(uri).timeout(const Duration(seconds: 30));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) bytes = res.bodyBytes;
        } catch (_) {
          // Unreachable, or too slow: said below.
        }
      }
      if (!mounted) return;
      if (bytes == null) {
        AppDialogs.toast(context, _notOpened, success: false);
        return;
      }
      final file = bytes;
      const title = 'Signed copy';
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => IssuedDocumentsCard.isPdf(file)
                ? PdfViewerScreen(
                    title: title,
                    fileName: '${widget.document.controlNumber}.pdf',
                    load: () async => file,
                  )
                : ImageViewerScaffold(
                    title: title,
                    image: MemoryImage(file),
                    semanticLabel: 'Signed copy of ${widget.document.controlNumber}',
                  ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.document;
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
                onPressed: _opening ? null : _openSignedCopy,
                icon: _opening
                    ? const SizedBox.square(
                        dimension: AppSizes.iconSm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description_outlined, size: AppSizes.iconSm),
                label: Text(tr('View signed copy')),
              ),
            if (!d.revoked && d.verifyUrl != null)
              TextButton.icon(
                onPressed: () => _launch(d.verifyUrl!),
                icon: const Icon(Icons.open_in_new_rounded, size: AppSizes.iconSm),
                label: const Text('Check online'),
              ),
          ],
        ),
        if (!d.revoked && !d.hasScan)
          Text(
            tr('The office has not attached a signed copy yet. The paper copy you claim is the official document.'),
            style: AppTypography.helper,
          ),
      ],
    );
  }
}
