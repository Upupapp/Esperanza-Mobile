import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/request_milestones.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/request_milestone_timeline.dart';
import '../../widgets/status_chip.dart';
import 'payment_method_sheet.dart';
import 'receipt_screen.dart';

/// Full request detail + status timeline — status/history is always
/// whatever [RequestsService] currently holds for this request, so a
/// future Web Admin/backend integration updating that data is reflected
/// here automatically; nothing citizen-facing on this screen is demo-only.
///
/// Dokyu/Tulong requests get the richer [RequestMilestoneTimeline] (Phase
/// 5 — frontend simulation, see docs) plus a clearly-separated "Demo
/// Controls" card for manually advancing the simulation during
/// presentations; Sakuna incident reports keep the older, simpler
/// newest-first history list since the milestone/payment system was never
/// meant to apply there.
class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _demoBusy = false;

  Future<void> _advance(RequestsService service, ServiceRequest request, Color accent) async {
    final next = service.nextMilestone(widget.requestId);
    if (next == null) return;

    String? paymentMethod;
    if (next == RequestMilestones.paymentMethodSelected) {
      if (!mounted) return;
      paymentMethod = await PaymentMethodSheet.show(context, accent: accent, feeAmount: request.fee);
      if (paymentMethod == null) return; // dismissed without choosing
    }

    setState(() => _demoBusy = true);
    AppHaptics.medium();
    await service.advanceMilestone(widget.requestId, paymentMethod: paymentMethod);
    if (mounted) setState(() => _demoBusy = false);
  }

  Future<void> _reject(RequestsService service) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Reject this request? (Demo)',
      message: 'This simulates an admin rejecting the request, for demonstration purposes only. It cannot be undone.',
      confirmLabel: 'Reject (Demo)',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _demoBusy = true);
    AppHaptics.warning();
    await service.rejectDemo(
      widget.requestId,
      reason:
          'The information you submitted did not match the information shown on your valid ID. '
          'Please review your details and submit the correct information.',
    );
    if (mounted) setState(() => _demoBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RequestsService>();
    final request = service.all.firstWhere((r) => r.id == widget.requestId);
    final status = AppStatusX.fromLabel(request.status);
    final accent = switch (request.category) {
      ServiceCategory.dokyu => AppColors.brand600,
      ServiceCategory.tulong => AppColors.purple700,
      ServiceCategory.sakunaIncident => AppColors.rose600,
    };
    final usesMilestones = request.category != ServiceCategory.sakunaIncident;

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
                  if (request.requiresPayment) _infoRow('Fee', request.fee),
                  if (request.paymentMethod != null) _infoRow('Payment method', request.paymentMethod!),
                  if (!usesMilestones && request.adminRemarks != null) _infoRow('Admin remarks', request.adminRemarks!),
                  // Permanently visible for the rest of this demo session
                  // once generated — not tied to the current milestone, so
                  // it stays reachable even after the request moves past
                  // Receipt Generated to Paid/Ready for Release/Completed.
                  if (request.receipt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'View Receipt',
                      icon: Icons.receipt_long_rounded,
                      variant: AppButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ReceiptScreen(receipt: request.receipt!)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              usesMilestones ? 'Request Timeline' : 'Status Timeline',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: usesMilestones
                  ? RequestMilestoneTimeline(request: request, accent: accent)
                  : Column(
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
            if (usesMilestones && service.canAdvance(widget.requestId)) ...[
              const SizedBox(height: AppSpacing.xl),
              _DemoControlsCard(
                nextMilestone: service.nextMilestone(widget.requestId),
                busy: _demoBusy,
                accent: accent,
                onAdvance: () => _advance(service, request, accent),
                onReject: () => _reject(service),
              ),
            ],
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
                    await context.read<RequestsService>().cancel(widget.requestId);
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

/// Clearly demonstration-only controls for manually driving the frontend
/// milestone simulation — deliberately styled to read as "not a normal
/// resident action" (dashed amber border, a "DEMO" tag) so a citizen using
/// the real app would never mistake this for something they control. See
/// Phase 5 docs: a real deployment's status changes come from the Web
/// Admin/backend, never a button in the citizen's own app.
class _DemoControlsCard extends StatelessWidget {
  final String? nextMilestone;
  final bool busy;
  final Color accent;
  final VoidCallback onAdvance;
  final VoidCallback onReject;

  const _DemoControlsCard({
    required this.nextMilestone,
    required this.busy,
    required this.accent,
    required this.onAdvance,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final next = nextMilestone;
    final needsPaymentMethod = next == RequestMilestones.paymentMethodSelected;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber500.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 16, color: AppColors.amber700),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'DEMONSTRATION CONTROLS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.amber700, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            next == null
                ? 'For client demonstrations only — not a real resident control.'
                : 'For client demonstrations only — not a real resident control. Next: $next',
            style: const TextStyle(fontSize: 11.5, color: AppColors.slate600, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: needsPaymentMethod ? 'Choose Payment Method (Demo)' : 'Next Demo Step',
            icon: needsPaymentMethod ? Icons.payments_outlined : Icons.skip_next_rounded,
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            loading: busy,
            onPressed: busy ? null : onAdvance,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: busy ? null : onReject,
            style: TextButton.styleFrom(foregroundColor: AppColors.rose600),
            child: const Text('Reject Request (Demo)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
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
