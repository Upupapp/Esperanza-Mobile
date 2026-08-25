import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/catalog_item.dart';
import '../../models/request_milestones.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../utils/tulong_eligibility.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/request_milestone_timeline.dart';
import '../../widgets/requirement_uploader.dart';
import '../../widgets/status_chip.dart';
import '../../utils/requirement_document_type.dart';
import 'new_request_screen.dart';
import 'payment_method_sheet.dart';
import 'receipt_screen.dart';
import 'service_request_wizard_screen.dart';

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

  /// Prefers the requested service's own [CatalogItem.demoRejectionReason]
  /// (a realistic, service-specific reason — see A15 of the Mobile <-> Web
  /// Admin final alignment pass) and falls back to a generic-but-still-
  /// realistic ID-mismatch reason for any service that doesn't have one,
  /// so every Dokyu/Tulong request type keeps a working reject simulation.
  String _rejectionReasonFor(ServiceRequest request) {
    final catalog = request.category == ServiceCategory.dokyu ? MockCatalog.documentTypes : MockCatalog.assistanceTypes;
    for (final item in catalog) {
      if (item.name == request.typeName && item.demoRejectionReason != null) {
        return item.demoRejectionReason!;
      }
    }
    return 'The information you submitted did not match the information shown on your valid ID. '
        'Please review your details and submit the correct information.';
  }

  Future<void> _reject(RequestsService service, ServiceRequest request) async {
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
    await service.rejectDemo(widget.requestId, reason: _rejectionReasonFor(request));
    if (mounted) setState(() => _demoBusy = false);
  }

  /// The first genuinely-uploadable requirement for this request's own
  /// catalog item (skipping staff/office-process lines — see
  /// RequirementInfo.requiresUpload) — the one a live demo of "Needs More
  /// Documents" flags, so the walkthrough is deterministic and repeatable
  /// across every Dokyu/Tulong service without a separate per-service
  /// config. Null only if the item somehow has no uploadable requirement at
  /// all (none currently do).
  RequirementInfo? _flaggableRequirementFor(ServiceRequest request) {
    final catalog = request.category == ServiceCategory.dokyu ? MockCatalog.documentTypes : MockCatalog.assistanceTypes;
    for (final item in catalog) {
      if (item.name != request.typeName) continue;
      final requirements = resolveRequirements(item.requirements);
      for (final r in requirements) {
        if (r.requiresUpload) return r;
      }
    }
    return null;
  }

  Future<void> _flagAdditionalDocuments(RequestsService service, ServiceRequest request) async {
    final requirement = _flaggableRequirementFor(request);
    if (requirement == null) return;
    final ok = await AppDialogs.confirm(
      context,
      title: 'Request additional documents? (Demo)',
      message: 'This simulates an admin flagging "${requirement.label}" as needing a new upload. The request stays '
          'active — it is not rejected.',
      confirmLabel: 'Flag Document (Demo)',
    );
    if (!ok || !mounted) return;
    setState(() => _demoBusy = true);
    AppHaptics.warning();
    await service.flagAdditionalDocuments(
      widget.requestId,
      requirementLabel: requirement.label,
      reason: 'The submitted "${requirement.label}" could not be verified. Please upload a clearer or updated copy.',
    );
    if (mounted) setState(() => _demoBusy = false);
  }

  Future<void> _resolveAdditionalDocuments(RequestsService service, Attachment newAttachment) async {
    setState(() => _demoBusy = true);
    AppHaptics.success();
    await service.resolveAdditionalDocuments(widget.requestId, newAttachment: newAttachment);
    if (mounted) setState(() => _demoBusy = false);
  }

  /// "Apply Again" on a Rejected request's own Application Rejected panel —
  /// reopens a brand-new application for the same catalog item, reusing the
  /// exact same routing ServiceCatalogScreen's own item list already uses
  /// (formSpec present -> the wizard, otherwise the older single-step
  /// screen) rather than a second implementation. For Tulong, this still
  /// goes through the same eligibility check as opening the item fresh
  /// would (see utils/tulong_eligibility.dart) — a resident could have a
  /// second, still-active application for this same assistance even while
  /// looking at an earlier rejected one, and that must still block here
  /// exactly as it would from the catalog. Dokyu has no such restriction.
  /// The rejected request itself is never touched — submitting always
  /// creates a brand-new ServiceRequest with its own id/reference number
  /// (see RequestsService.submit).
  Future<void> _applyAgain(BuildContext context, ServiceRequest request, Color accent) async {
    final catalog = request.category == ServiceCategory.dokyu ? MockCatalog.documentTypes : MockCatalog.assistanceTypes;
    CatalogItem? item;
    for (final i in catalog) {
      if (i.name == request.typeName) {
        item = i;
        break;
      }
    }
    if (item == null) return; // no matching catalog item to reopen against

    if (request.category == ServiceCategory.tulong) {
      final account = context.read<CitizenSessionService>().account;
      if (account != null) {
        final result = tulongEligibilityFor(
          context.read<RequestsService>(),
          applicantId: account.id,
          typeName: item.name,
        );
        if (!result.isEligible) {
          final viewRequest = await showTulongBlockedDialog(context, result);
          if (viewRequest && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: result.blockingRequest!.id)),
            );
          }
          return;
        }
      }
    }

    if (!context.mounted) return;
    final resolvedItem = item;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => resolvedItem.formSpec != null
            ? ServiceRequestWizardScreen(category: request.category, item: resolvedItem, accent: accent)
            : NewRequestScreen(category: request.category, item: resolvedItem, accent: accent),
      ),
    );
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
            // Noticeable, but only ever for a genuinely Rejected request
            // that actually has a reason on file — a seeded/older Rejected
            // demo request with no adminRemarks set simply doesn't show
            // this panel, exactly like before this feature existed.
            if (request.status == 'Rejected' && request.adminRemarks != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _RejectedApplicationCard(
                reason: request.adminRemarks!,
                guidance: request.rejectionGuidance ?? 'Submit a new ${request.typeName} application.',
                onApplyAgain: () => _applyAgain(context, request, accent),
              ),
            ],
            // Distinct from Rejected above — the request is still active,
            // not terminal. Only ever shown for the specific "admin flagged
            // one requirement" simulation (flaggedRequirementLabel set), not
            // every 'Waiting Requirements' status (the payment sub-steps
            // also canonicalize to that same label but never set this
            // field) — see ServiceRequest.flaggedRequirementLabel.
            if (request.status == 'Waiting Requirements' && request.flaggedRequirementLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _AdditionalDocumentsCard(
                reason: request.adminRemarks ?? 'Please provide an updated copy of the flagged requirement.',
                requirement: RequirementInfo(
                  label: request.flaggedRequirementLabel!,
                  documentType: documentTypeFor(request.flaggedRequirementLabel!),
                  isRequired: true,
                ),
                currentAttachment: _attachmentFor(request, request.flaggedRequirementLabel!),
                accent: accent,
                busy: _demoBusy,
                onResubmit: (a) => _resolveAdditionalDocuments(service, a),
              ),
            ],
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
                onReject: () => _reject(service, request),
                onFlagDocs: _flaggableRequirementFor(request) != null
                    ? () => _flagAdditionalDocuments(service, request)
                    : null,
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

  Attachment? _attachmentFor(ServiceRequest request, String requirementLabel) {
    for (final a in request.attachments) {
      if (a.documentTypeLabel == requirementLabel) return a;
    }
    return null;
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

/// The rejected-request explanation panel — reason, a suggested next step,
/// and Apply Again. FRONTEND SIMULATION ONLY: the reason/guidance text is
/// plain seeded/admin-entered data (see RequestsService's demo seed and
/// RequestDetailScreen._reject), never generated or inferred here.
class _RejectedApplicationCard extends StatelessWidget {
  final String reason;
  final String guidance;
  final VoidCallback onApplyAgain;

  const _RejectedApplicationCard({required this.reason, required this.guidance, required this.onApplyAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.rose50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rose500.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, size: 18, color: AppColors.rose700),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Application Rejected',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.rose700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(reason, style: const TextStyle(fontSize: 12.5, color: AppColors.slate700, height: 1.45)),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'What you can do:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate700),
          ),
          const SizedBox(height: 3),
          Text(guidance, style: const TextStyle(fontSize: 12.5, color: AppColors.slate600, height: 1.4)),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Apply Again', fullWidth: true, onPressed: onApplyAgain),
        ],
      ),
    );
  }
}

/// Distinct from [_RejectedApplicationCard] — the request is still active,
/// not terminal. Shows the admin's reason plus a [RequirementUploader] for
/// the one flagged requirement, so the resident replaces exactly that
/// document (never the whole application) and nothing else on the request
/// is touched. Orange/warning-styled, never red, so it never reads as a
/// rejection.
class _AdditionalDocumentsCard extends StatelessWidget {
  final String reason;
  final RequirementInfo requirement;
  final Attachment? currentAttachment;
  final Color accent;
  final bool busy;
  final ValueChanged<Attachment> onResubmit;

  const _AdditionalDocumentsCard({
    required this.reason,
    required this.requirement,
    required this.currentAttachment,
    required this.accent,
    required this.busy,
    required this.onResubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.orange50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange500.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.orange700),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Additional Document Needed',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.orange700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(reason, style: const TextStyle(fontSize: 12.5, color: AppColors.slate700, height: 1.45)),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'This is still an active request, not a rejection — upload a replacement below and it will go back for '
            'review automatically.',
            style: TextStyle(fontSize: 11.5, color: AppColors.slate500, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Opacity(
            opacity: busy ? 0.6 : 1,
            child: IgnorePointer(
              ignoring: busy,
              child: RequirementUploader(
                requirement: requirement,
                attachment: currentAttachment,
                accent: accent,
                existingMasterDoc: null,
                onAttachNew: onResubmit,
                onUseExisting: () {},
                onRemove: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
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

  /// Null when this request's catalog item has no genuinely-uploadable
  /// requirement to flag (none currently lack one) — omits the button
  /// entirely rather than showing it disabled.
  final VoidCallback? onFlagDocs;

  const _DemoControlsCard({
    required this.nextMilestone,
    required this.busy,
    required this.accent,
    required this.onAdvance,
    required this.onReject,
    required this.onFlagDocs,
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
          if (onFlagDocs != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: busy ? null : onFlagDocs,
              style: TextButton.styleFrom(foregroundColor: AppColors.orange700),
              child: const Text(
                'Request Additional Documents (Demo)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
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
