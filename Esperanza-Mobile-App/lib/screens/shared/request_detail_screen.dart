import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/catalog_item.dart';
import '../../models/request_milestones.dart';
import '../../models/service_request.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/master_file_service.dart';
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
import '../../widgets/async_state_view.dart';
import '../../widgets/request_milestone_timeline.dart';
import '../../widgets/requirement_uploader.dart';
import '../../widgets/status_chip.dart';
import '../../utils/requirement_document_type.dart';
import 'new_request_screen.dart';
import 'service_request_wizard_screen.dart';

/// Full request detail + real status history, against
/// GET /citizen/requests/{ref} (production-readiness programme,
/// 2026-09-25). Previously showed [RequestsService]'s own local
/// milestone simulation, with a "Demo Controls" card that let the citizen
/// drive their own request's status themselves -- a real deployment's
/// status changes only ever come from the Web Admin, so that card and
/// every other "(Demo)" control (Reject, Flag Additional Documents, Cancel
/// Request, Continue Verification) are gone along with the simulation
/// they drove. What's real and stays wired: replacing a specific flagged
/// requirement (POST .../requirements/{key}/replace) and resubmitting once
/// every flag is resolved (POST .../resubmit).
class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  /// Set only when opened from an "Application Needs Correction"
  /// notification's Replace Document action (see notification_feed.dart) —
  /// scrolls straight to that one [FlaggedRequirement]'s own uploader card
  /// once the screen renders, so the citizen never has to search for it
  /// among other requirements. Ignored if that entry is already resolved or
  /// no longer exists (e.g. an old, already-actioned notification) — the
  /// screen just shows the request's current state instead.
  final String? focusFlaggedRequirementId;

  const RequestDetailScreen({super.key, required this.requestId, this.focusFlaggedRequirementId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _busy = false;
  final _flaggedCardKeys = <String, GlobalKey>{};

  GlobalKey _keyFor(String flaggedId) => _flaggedCardKeys.putIfAbsent(flaggedId, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    final target = widget.focusFlaggedRequirementId;
    if (target == null) return;
    // One-shot, after the first frame this screen renders — by then the
    // targeted card's GlobalKey (assigned while building the corrections
    // section below) is attached, if that entry still exists and is still
    // unresolved. Nothing to scroll to (a stale/already-actioned
    // notification) simply leaves the screen showing the top as usual.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _flaggedCardKeys[target]?.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
      }
    });
  }

  Future<void> _replaceFlagged(RequestsService service, String flaggedId, Attachment newAttachment) async {
    final path = newAttachment.localPath;
    if (path == null) {
      AppDialogs.toast(context, 'Could not read the selected file. Please pick it again.', success: false);
      return;
    }
    setState(() => _busy = true);
    AppHaptics.success();
    try {
      await service.replaceRequirement(widget.requestId, requirementKey: flaggedId, filePath: path);
      if (mounted) AppDialogs.toast(context, 'Document replaced.');
    } on ApiException catch (e) {
      if (mounted) AppDialogs.toast(context, e.message(), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resubmit(RequestsService service) async {
    setState(() => _busy = true);
    AppHaptics.success();
    try {
      await service.resubmit(widget.requestId);
      if (mounted) AppDialogs.toast(context, 'Application resubmitted.');
    } on ApiException catch (e) {
      if (mounted) AppDialogs.toast(context, e.message(), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
  /// creates a brand-new ServiceRequest with its own ref (see
  /// RequestsService.submit).
  Future<void> _applyAgain(BuildContext context, RequestsService service, ServiceRequest request, Color accent) async {
    final catalog = request.category == ServiceCategory.dokyu ? service.dokyuCatalog : service.tulongCatalog;
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
        final result = tulongEligibilityFor(service, applicantId: account.id, typeName: item.name);
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

    return Scaffold(
      appBar: AppBar(title: Text(widget.requestId)),
      body: SafeArea(
        child: AsyncStateView<ServiceRequest>(
          loader: () => service.loadDetail(widget.requestId),
          builder: (context, request, reload) => _buildBody(context, service, request),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RequestsService service, ServiceRequest request) {
    final status = AppStatusX.fromLabel(request.status);
    final accent = switch (request.category) {
      ServiceCategory.dokyu => AppColors.brand600,
      ServiceCategory.tulong => AppColors.purple700,
      ServiceCategory.sakunaIncident => AppColors.rose600,
      // Neutral: an accent borrowed from another service would imply one.
      ServiceCategory.unknown => AppColors.slate600,
    };
    final usesMilestones = request.category != ServiceCategory.sakunaIncident;

    return ListView(
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Flexible, not a bare fixed-size child — a longer status
                  // label ("Under Verification") plus a longer typeName
                  // together can exceed a narrow phone's width (see the
                  // matching fix in request_list_screen.dart's own
                  // _RequestTile row).
                  Flexible(child: StatusChip(status: status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(request.office, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.textMuted)),
              const Divider(height: AppSpacing.xxl),
              _infoRow('Submitted', _fmtFull(request.submittedAt)),
              if (!usesMilestones && request.adminRemarks != null) _infoRow('Admin remarks', request.adminRemarks!),
            ],
          ),
        ),
        // Noticeable, but only ever for a genuinely Rejected request that
        // actually has a reason on file.
        if (request.status == 'Rejected' && request.adminRemarks != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _RejectedApplicationCard(
            reason: request.adminRemarks!,
            guidance: 'Submit a new ${request.typeName} application.',
            onApplyAgain: () => _applyAgain(context, service, request, accent),
          ),
        ],
        // Distinct from Rejected above — the request is still active, not
        // terminal, and resumable. One or more specific flagged
        // requirements each get their own re-upload control; no flagged
        // requirement at all means the server's own "needs manual
        // verification" flavor — nothing for the citizen to upload, just
        // the explanation from decision_remarks.
        if (request.status == RequestMilestones.underReview) ...[
          const SizedBox(height: AppSpacing.xl),
          if (request.flaggedRequirements.isNotEmpty)
            _CorrectionsSection(
              request: request,
              accent: accent,
              busy: _busy,
              keyFor: _keyFor,
              onReplace: (flaggedId, a) => _replaceFlagged(service, flaggedId, a),
              onResubmit: request.canResubmit ? () => _resubmit(service) : null,
            )
          else
            _ManualVerificationCard(
              reason: request.adminRemarks ?? 'The request requires additional verification.',
            ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          usesMilestones ? 'Request Timeline' : 'Status Timeline',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: request.statusHistory.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('No history recorded yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                )
              : usesMilestones
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
      ],
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
              style: AppTypography.bodySmallMedium.copyWith(color: AppColors.slate700),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtFull(DateTime d) =>
      '${d.month}/${d.day}/${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// The rejected-request explanation panel — reason, a suggested next step,
/// and Apply Again. `reason` is the server's real `decision_remarks`.
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
          Text(reason, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.slate700, height: 1.45)),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'What you can do:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate700),
          ),
          const SizedBox(height: 3),
          Text(guidance, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.slate600, height: 1.4)),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: 'Apply Again', fullWidth: true, onPressed: onApplyAgain),
        ],
      ),
    );
  }
}

/// Distinct from [_RejectedApplicationCard] — the request is still active,
/// not terminal. Wraps one [_FlaggedRequirementCard] per still-unresolved
/// [FlaggedRequirement], a header showing how many still need correction,
/// and the explicit "Resubmit Application" action — disabled until the
/// server's own `can_resubmit` says every one of them is replaced.
/// Replacing a document never resubmits by itself; only this button does.
class _CorrectionsSection extends StatelessWidget {
  final ServiceRequest request;
  final Color accent;
  final bool busy;
  final GlobalKey Function(String flaggedId) keyFor;
  final void Function(String flaggedId, Attachment newAttachment) onReplace;
  final VoidCallback? onResubmit;

  const _CorrectionsSection({
    required this.request,
    required this.accent,
    required this.busy,
    required this.keyFor,
    required this.onReplace,
    required this.onResubmit,
  });

  @override
  Widget build(BuildContext context) {
    final unresolved = request.flaggedRequirements.where((f) => !f.isResolved).toList();
    final allResolved = unresolved.isEmpty;
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
                  'Application Needs Correction',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.orange700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            unresolved.length > 1
                ? '${unresolved.length} documents require correction.'
                : allResolved
                    ? 'All flagged documents have been replaced — you may now resubmit.'
                    : '1 document requires correction.',
            style: AppTypography.captionSmallRegular.copyWith(color: AppColors.slate500, height: 1.4),
          ),
          for (final flagged in unresolved)
            Padding(
              key: keyFor(flagged.id),
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _FlaggedRequirementCard(
                flagged: flagged,
                currentAttachment: _attachmentFor(request, flagged.requirementLabel),
                accent: accent,
                busy: busy,
                serviceName: request.typeName,
                category: request.category,
                onReplace: (a) => onReplace(flagged.id, a),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Resubmit Application',
            icon: Icons.send_rounded,
            fullWidth: true,
            loading: busy,
            onPressed: allResolved && !busy ? onResubmit : null,
          ),
        ],
      ),
    );
  }
}

Attachment? _attachmentFor(ServiceRequest request, String requirementLabel) {
  for (final a in request.attachments) {
    if (a.documentTypeLabel == requirementLabel) return a;
  }
  return null;
}

/// One flagged requirement's own reason + [RequirementUploader] — the
/// resident replaces exactly this document (never the whole application,
/// and never any other requirement on the same request). Wired to
/// [MasterFileService] the same way the original submission-time requirement
/// uploaders are, so "Use Existing Document" works here too.
class _FlaggedRequirementCard extends StatelessWidget {
  final FlaggedRequirement flagged;
  final Attachment? currentAttachment;
  final Color accent;
  final bool busy;
  final String serviceName;
  final ServiceCategory category;
  final ValueChanged<Attachment> onReplace;

  const _FlaggedRequirementCard({
    required this.flagged,
    required this.currentAttachment,
    required this.accent,
    required this.busy,
    required this.serviceName,
    required this.category,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final requirement = RequirementInfo(
      label: flagged.requirementLabel,
      documentType: documentTypeFor(flagged.requirementLabel),
      isRequired: true,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange500.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flagged.requirementLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Reason: ${flagged.reason}',
            style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Opacity(
            opacity: busy ? 0.6 : 1,
            child: IgnorePointer(
              ignoring: busy,
              child: Consumer<MasterFileService>(
                builder: (context, masterFile, _) {
                  final accountId = context.read<CitizenSessionService>().account?.id;
                  final existing = accountId != null ? masterFile.findByType(accountId, requirement.documentType) : null;
                  return RequirementUploader(
                    requirement: requirement,
                    attachment: currentAttachment,
                    accent: accent,
                    existingMasterDoc: existing,
                    onAttachNew: (a) {
                      onReplace(a);
                      if (accountId != null) {
                        masterFile.saveOrUpdate(
                          accountId: accountId,
                          documentType: requirement.documentType,
                          label: requirement.label,
                          attachment: a,
                          origin: category == ServiceCategory.dokyu ? 'Dokyu' : 'Tulong',
                          serviceName: serviceName,
                        );
                      }
                    },
                    onUseExisting: () {
                      if (existing != null) {
                        onReplace(attachmentForReuse(existing.attachment, requirementLabel: requirement.label));
                      }
                    },
                    onRemove: () {},
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Needs manual verification" — the server's own Under Review with no
/// specific requirement flagged (decision_remarks explains why, but
/// needs_correction is empty). Nothing for the citizen to upload or
/// correct, so unlike the corrections section this never embeds a
/// [RequirementUploader] — just the plain-language explanation. Never
/// styled or worded like a rejection.
class _ManualVerificationCard extends StatelessWidget {
  final String reason;
  const _ManualVerificationCard({required this.reason});

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
              const Icon(Icons.fact_check_outlined, size: 18, color: AppColors.orange700),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Under Review',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.orange700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(reason, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.slate700, height: 1.45)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The request requires additional verification. This is still an active request, not a rejection — no '
            'action is needed from you at this time.',
            style: AppTypography.captionSmallRegular.copyWith(color: AppColors.slate500, height: 1.4),
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
