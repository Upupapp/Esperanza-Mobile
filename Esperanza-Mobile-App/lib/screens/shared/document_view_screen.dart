import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/document_preview.dart';
import '../../models/service_request.dart';
import '../../services/barangay_service.dart';
import '../../services/citizen_session_service.dart';
import '../../services/document_templates_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/document_pdf.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/zoomable_document.dart';

import '../../l10n/tr.dart';
/// The statuses at which the website offers "View Document".
const documentReadyStatuses = {'Approved', 'Mark to Release', 'Released'};

/// The document a Dokyu request is for, or null when the website draws none
/// for it.
DocumentMeta? documentMetaFor(ServiceRequest r) =>
    r.category == ServiceCategory.dokyu && r.serviceKey != null ? documentMetas[r.serviceKey] : null;

/// The barangay's punong barangay, secretary and seal, from GET /barangays.
Future<({String? captain, String? secretary, String? sealUrl})> barangayOfficials(String barangay) async {
  try {
    final all = await BarangayService.load();
    for (final b in all) {
      if (b.name.toLowerCase() == barangay.toLowerCase()) {
        return (captain: b.captain, secretary: b.secretary, sealUrl: b.sealUrl);
      }
    }
  } catch (_) {
    // The document still draws, with the office's blank line.
  }
  return (captain: null, secretary: null, sealUrl: null);
}

/// "Your document is ready": once approved, the website's Document Ready card
/// on Track Request, with View Document.
class DocumentReadyCard extends StatelessWidget {
  const DocumentReadyCard({super.key, required this.request, required this.accent});

  final ServiceRequest request;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final meta = documentMetaFor(request);
    final released = request.status == 'Released';
    if (meta == null) {
      return AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.slate600, size: AppSizes.iconBase),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                "Your request has been approved. Online preview isn't available for this request — visit the office to claim your physical copy.",
                style: AppTypography.bodySmall.copyWith(color: AppColors.textBody),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.task_outlined, color: accent, size: AppSizes.iconBase),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  released ? 'Your document has been released' : 'Your document is ready',
                  style: AppTypography.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            tr('Preview, download, or print your official copy.'),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: tr('View Document'),
            icon: Icons.visibility_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DocumentViewScreen(request: request, meta: meta)),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Your Document": the paper, filled from what was filed, with the control
/// number and QR once issued, and Download PDF (the website's modal).
class DocumentViewScreen extends StatefulWidget {
  const DocumentViewScreen({super.key, required this.request, required this.meta});

  final ServiceRequest request;
  final DocumentMeta meta;

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  late final Future<(DocumentSheet, String?)> _sheet = _build();

  /// The page as drawn, for Download PDF.
  final _page = GlobalKey();

  Future<(DocumentSheet, String?)> _build() async {
    final account = context.read<CitizenSessionService>().account;
    final barangay = account?.barangay ?? '';
    final results = await Future.wait([DocumentTemplatesService.load(), barangayOfficials(barangay)]);
    final templates = results[0] as Map<String, DocumentTemplate>;
    final officials = results[1] as ({String? captain, String? secretary, String? sealUrl});
    final issued = currentIssued(widget.request.issuedDocuments);
    final data = documentData(
      widget.meta,
      widget.request.formFields,
      fullName: account?.fullName ?? '',
      birthdate: account?.birthdate,
      sex: account?.sex,
      civilStatus: account?.civilStatus,
      occupation: account?.occupation,
      address: account?.address,
      purok: account?.purok,
    );
    final sheet = buildDocument(
      widget.meta.asIssued,
      data,
      barangay: barangay,
      punongBarangay: officials.captain,
      barangaySecretary: officials.secretary,
      template: templates[widget.meta.key],
      issued: issued,
    );
    return (sheet, officials.sealUrl);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Your Document'))),
      body: SafeArea(
        child: FutureBuilder<(DocumentSheet, String?)>(
          future: _sheet,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final (sheet, sealUrl) = snap.data!;
            // The page fills the screen, to pinch in and out of; the
            // reference line and Download PDF stay below it.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: Text(
                    '${r.referenceNumber} · ${r.status}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ),
                Expanded(
                  child: ClipRect(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: ZoomableDocument(sheet: sheet, barangaySealUrl: sealUrl, captureKey: _page),
                    ),
                  ),
                ),
                const DocumentZoomHint(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tr('Reference copy. The signed copy is released at the office.'),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: tr('Download PDF'),
                        icon: Icons.download_rounded,
                        fullWidth: true,
                        onPressed: () => DocumentPdf.share(
                          context,
                          _page,
                          title: sheet.title,
                          fileName:
                              'Esperanza-${sheet.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}-${r.referenceNumber}.pdf',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
