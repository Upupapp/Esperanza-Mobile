import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/status_chip.dart';

/// Full request detail + status timeline — status/history is always
/// whatever [RequestsService] currently holds for this request, so a
/// future Web Admin/backend integration updating that data is reflected
/// here automatically; nothing on this screen is demo-only.
class RequestDetailScreen extends StatelessWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RequestsService>();
    final request = service.all.firstWhere((r) => r.id == requestId);
    final status = AppStatusX.fromLabel(request.status);
    final accent = switch (request.category) {
      ServiceCategory.dokyu => AppColors.brand600,
      ServiceCategory.tulong => AppColors.purple700,
      ServiceCategory.sakunaIncident => AppColors.rose600,
    };

    return Scaffold(
      appBar: AppBar(title: Text(request.referenceNumber)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.typeName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(request.office, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  const Divider(height: AppSpacing.xxl),
                  _infoRow('Purpose', request.purpose),
                  _infoRow('Expected processing time', request.expectedDays),
                  _infoRow('Submitted', _fmtFull(request.submittedAt)),
                  if (request.adminRemarks != null) _infoRow('Admin remarks', request.adminRemarks!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Status Timeline',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: [
                  for (int i = 0; i < request.statusHistory.length; i++)
                    _TimelineRow(
                      entry: request.statusHistory[request.statusHistory.length - 1 - i],
                      isLast: i == request.statusHistory.length - 1,
                      accent: accent,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Attachments (${request.attachments.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: request.attachments
                    .map(
                      (a) => ListTile(
                        dense: true,
                        leading: Icon(_iconFor(a.category), color: accent, size: 18),
                        title: Text(a.fileName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          '${a.category.shortLabel} · ${a.readableSize}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (!status.isDone) ...[
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Cancel Request',
                variant: AppButtonVariant.danger,
                onPressed: () async {
                  final ok = await AppDialogs.confirm(
                    context,
                    title: 'Cancel this request?',
                    message: 'This cannot be undone. You will need to submit a new request if you change your mind.',
                    confirmLabel: 'Cancel Request',
                    danger: true,
                  );
                  if (ok && context.mounted) {
                    await context.read<RequestsService>().cancel(requestId);
                    if (context.mounted) AppDialogs.toast(context, 'Request cancelled.', success: false);
                  }
                },
                fullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, color: AppColors.slate700, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtFull(DateTime d) =>
      '${d.month}/${d.day}/${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  IconData _iconFor(AttachmentCategory c) => switch (c) {
    AttachmentCategory.image => Icons.image_outlined,
    AttachmentCategory.pdf => Icons.picture_as_pdf_outlined,
    AttachmentCategory.docx => Icons.description_outlined,
    AttachmentCategory.video => Icons.videocam_outlined,
    AttachmentCategory.other => Icons.insert_drive_file_outlined,
  };
}

class _TimelineRow extends StatelessWidget {
  final dynamic entry;
  final bool isLast;
  final Color accent;
  const _TimelineRow({required this.entry, required this.isLast, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: AppColors.slate100)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.status as String, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.actor} · ${_fmt(entry.at as DateTime)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    if (entry.remarks != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.remarks as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
