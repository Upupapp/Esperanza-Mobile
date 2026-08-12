import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/status_chip.dart';

/// Full request detail + status timeline. Includes a clearly-labeled DEMO
/// panel that simulates what a Web Admin staff member would do next
/// (Review -> Approve/Reject/Request Additional Requirements -> Release),
/// so the full citizen<->admin loop is visible end-to-end even though this
/// build has no real Web Admin connection — see Section 7 of the alignment
/// doc ("Process Reflection Between Mobile and Web Admin"). This panel
/// must never be mistaken for a real admin action; it is local-only.
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
                      Expanded(child: Text(request.typeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
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
            const Text('Status Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
            Text('Attachments (${request.attachments.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: request.attachments
                    .map((a) => ListTile(
                          dense: true,
                          leading: Icon(_iconFor(a.category), color: accent, size: 18),
                          title: Text(a.fileName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                          subtitle: Text('${a.category.shortLabel} · ${a.readableSize}', style: const TextStyle(fontSize: 11)),
                        ))
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
            const SizedBox(height: AppSpacing.xxl),
            _DemoAdminPanel(request: request, accent: accent),
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
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5, color: AppColors.slate700, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _fmtFull(DateTime d) => '${d.month}/${d.day}/${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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
                Container(width: 10, height: 10, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
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
                    Text(entry.status as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${entry.actor} · ${_fmt(entry.at as DateTime)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    if (entry.remarks != null) ...[
                      const SizedBox(height: 4),
                      Text(entry.remarks as String, style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.3)),
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

  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _DemoAdminPanel extends StatefulWidget {
  final ServiceRequest request;
  final Color accent;
  const _DemoAdminPanel({required this.request, required this.accent});

  @override
  State<_DemoAdminPanel> createState() => _DemoAdminPanelState();
}

class _DemoAdminPanelState extends State<_DemoAdminPanel> {
  String? _nextStatus;
  final _remarksController = TextEditingController();
  bool _expanded = false;

  static const _adminNextSteps = [
    'Under Verification', 'Waiting Requirements', 'Assigned', 'Processing',
    'Approved', 'Rejected', 'Ready for Release', 'Released', 'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, size: 16, color: AppColors.amber500),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Demo: Simulate Web Admin Action', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.amber700)),
                ),
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.slate400),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            const Text(
              'No real Web Admin backend exists yet — this lets you preview how a status change from admin staff would appear on this screen.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSelectField<String>(
              label: 'Next status (as admin would set it)',
              value: _nextStatus,
              options: _adminNextSteps,
              labelBuilder: (s) => s,
              onChanged: (v) => setState(() => _nextStatus = v),
              hintText: 'Choose a status',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Admin remarks (optional)', controller: _remarksController, maxLines: 2, hintText: 'e.g. Please submit a clearer photo of your ID.'),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Apply as Admin',
              variant: AppButtonVariant.secondary,
              fullWidth: true,
              onPressed: _nextStatus == null
                  ? null
                  : () async {
                      await context.read<RequestsService>().simulateAdminUpdate(
                            widget.request.id,
                            newStatus: _nextStatus!,
                            actorRole: '${widget.request.office} Staff',
                            remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
                          );
                      if (context.mounted) {
                        AppDialogs.toast(context, 'Status updated to "$_nextStatus" (simulated).');
                        setState(() {
                          _nextStatus = null;
                          _remarksController.clear();
                        });
                      }
                    },
            ),
          ],
        ],
      ),
    );
  }
}
