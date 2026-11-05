import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import '../../models/resident_certificate.dart';
import '../../services/message_language.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/document_pdf.dart';
import '../../widgets/app_button.dart';
import '../../widgets/certificate_paper.dart';

/// The website's own Filipino for the certificate window
/// (components/welfare/certificate.blade.php), Filipino / English.
String _t(String fil, String en) => MessageLanguage.filipino.value ? fil : en;

/// "Sertipiko": the certificate itself, as the website's certificate window
/// draws it (owner, 2026-11-05) - A4 landscape with the seal, the title, the
/// holders, the date and venue, the signatories, the control number and the
/// verify QR - for a session's certificate and an event's alike. Opened from
/// My certificates and from the event's page. Download PDF makes the same
/// page into an A4 landscape PDF for the phone's share sheet (print, save or
/// send), as "Your Document" does.
class CertificateViewScreen extends StatefulWidget {
  const CertificateViewScreen({super.key, required this.certificate});

  final ResidentCertificate certificate;

  @override
  State<CertificateViewScreen> createState() => _CertificateViewScreenState();
}

class _CertificateViewScreenState extends State<CertificateViewScreen> {
  final _page = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final c = widget.certificate;
    final sheet = CertificateSheet.of(c);
    return Scaffold(
      key: const Key('certificate_view'),
      appBar: AppBar(title: Text(_t('Sertipiko', 'Certificate'))),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (c.revoked)
              Container(
                margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.rose50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.rose500),
                ),
                child: Text(
                  revokedNote(c),
                  style: AppTypography.helper.copyWith(color: AppColors.rose700),
                ),
              ),
            Expanded(
              child: ClipRect(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      // The landscape page scaled to the screen's width.
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(key: _page, child: CertificatePaper(sheet: sheet)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pinch_outlined, size: AppSizes.iconSm, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(child: Text('Pinch to zoom in or out', style: AppTypography.helper)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: _t('I-download ang PDF', 'Download PDF'),
                icon: Icons.download_rounded,
                fullWidth: true,
                onPressed: () => DocumentPdf.share(
                  context,
                  _page,
                  title: sheet.title,
                  fileName: '${sheet.title.replaceAll(RegExp(r'[^\w-]+'), '-')}-${sheet.control}.pdf',
                  pageFormat: PdfPageFormat.a4.landscape,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The website's line for a revoked certificate, with the office's reason.
String revokedNote(ResidentCertificate c) =>
    _t('Binawi ang sertipikong ito', 'This certificate was revoked') +
    (c.revokedReason == null ? '.' : ': ${c.revokedReason}');
