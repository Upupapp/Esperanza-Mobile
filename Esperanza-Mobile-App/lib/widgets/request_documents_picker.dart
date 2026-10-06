import 'package:flutter/material.dart';
import '../models/attachment.dart';
import '../models/service_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/requirement_document_type.dart';
import 'server_requirement_uploader.dart';

/// The request's required documents, attached while the request is being
/// filled in (Esperanza QA, 2026-10-07: they were handled only after filing,
/// as if a separate errand). The picked files are uploaded to the request's
/// own requirements right after it is created (RequestsService.attachPicked),
/// through the same attach endpoint the request detail uses afterwards, so the
/// request lifecycle on the server is unchanged.
///
/// Each line says whether it is required, applies only to some, or is done at
/// the office; a document not attached now can still be added from the request.
class RequestDocumentsPicker extends StatelessWidget {
  final List<RequirementInfo> requirements;

  /// Picked files by requirement label.
  final Map<String, Attachment> picked;
  final ValueChanged<MapEntry<String, Attachment>> onPicked;
  final Color accent;
  final String serviceName;
  final ServiceCategory category;

  const RequestDocumentsPicker({
    super.key,
    required this.requirements,
    required this.picked,
    required this.onPicked,
    required this.accent,
    required this.serviceName,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final owed = missingRequired(requirements, picked);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Required documents',
          style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'These are part of your request. Attach them here and they are sent with it. '
          'If you do not have one yet, you can add it later from your request; the office reviews '
          'your request once every required document is attached.',
          style: AppTypography.captionSmallRegular.copyWith(color: AppColors.textMuted, height: 1.4),
        ),
        if (owed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            owed.length == 1
                ? '1 required document not attached yet.'
                : '${owed.length} required documents not attached yet.',
            style: AppTypography.captionSmallRegular.copyWith(color: AppColors.orange700, fontWeight: FontWeight.w600),
          ),
        ],
        for (final req in requirements) ...[
          const SizedBox(height: AppSpacing.md),
          _KindChip(info: req),
          const SizedBox(height: AppSpacing.xs),
          if (req.requiresUpload)
            ServerRequirementUploader(
              label: req.label,
              current: picked[req.label],
              accent: accent,
              busy: false,
              serviceName: serviceName,
              category: category,
              onPicked: (a) => onPicked(MapEntry(req.label, a)),
            )
          else
            Text(
              '${req.label} — nothing to upload: the office does this with you.',
              style: AppTypography.captionSmallRegular.copyWith(color: AppColors.slate500, height: 1.4),
            ),
        ],
      ],
    );
  }

  /// Required documents the resident has not picked yet.
  static List<RequirementInfo> missingRequired(List<RequirementInfo> requirements, Map<String, Attachment> picked) =>
      requirements.where((r) => r.isRequired && r.requiresUpload && picked[r.label] == null).toList();
}

class _KindChip extends StatelessWidget {
  final RequirementInfo info;
  const _KindChip({required this.info});

  @override
  Widget build(BuildContext context) {
    final (text, bg, fg) = !info.requiresUpload
        ? ('Done at the office', AppColors.slate100, AppColors.slate600)
        : info.isRequired
        ? ('Required', AppColors.rose50, AppColors.rose600)
        : ('If it applies', AppColors.slate100, AppColors.slate600);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Text(
          text,
          style: TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }
}
