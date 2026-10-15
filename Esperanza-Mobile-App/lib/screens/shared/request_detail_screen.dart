import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../../theme/app_typography.dart';
import '../../theme/tulong_status.dart';
import '../../utils/tulong_eligibility.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/image_viewer_scaffold.dart';
import '../../widgets/request_milestone_timeline.dart';
import '../../widgets/request_release_cards.dart';
import '../appointments/appointments_screen.dart';
import '../../widgets/requirement_uploader.dart';
import '../../widgets/server_requirement_uploader.dart';
import '../../widgets/status_chip.dart';
import '../../utils/requirement_document_type.dart';
import 'new_request_screen.dart';
import 'service_request_wizard_screen.dart';
import '../../utils/date_text.dart';
import '../../utils/peso_text.dart';
import '../../widgets/esperanza_art.dart';

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

  /// The server's answer to the latest replace, attach or resubmit. The
  /// screen showed the detail as first loaded, so after a resident replaced a
  /// flagged document its Resubmit stayed disabled (that copy's can_resubmit
  /// was still false) until the screen was closed and opened again.
  ServiceRequest? _latest;
  final _flaggedCardKeys = <String, GlobalKey>{};

  GlobalKey _keyFor(String flaggedId) => _flaggedCardKeys.putIfAbsent(flaggedId, () => GlobalKey());

  /// The open request re-reads itself every 30 seconds: the office approved
  /// and released one while it sat open here, and it still read Under Review
  /// until the app was restarted (Esperanza bugs QA, 2026-10-06). Only this
  /// screen's own request, only while it is open, never during an upload.
  Timer? _poll;

  Future<void> _refreshQuietly() async {
    if (!mounted || _busy) return;
    try {
      final fresh = await context.read<RequestsService>().loadDetail(widget.requestId);
      if (mounted && !_busy) setState(() => _latest = fresh);
    } catch (_) {
      // Offline or a hiccup: the next tick tries again; nothing to show.
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refreshQuietly());
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
      final updated = await service.replaceRequirement(widget.requestId, requirementKey: flaggedId, filePath: path);
      if (mounted) {
        setState(() => _latest = updated);
        AppDialogs.toast(context, 'Document replaced.');
      }
    } on ApiException catch (e) {
      if (mounted) AppDialogs.toast(context, e.message(), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The document for a requirement the office has not decided yet
  /// ([PendingRequirement]); attaching again replaces the file on record.
  Future<void> _attach(RequestsService service, String requirementKey, Attachment newAttachment) async {
    final path = newAttachment.localPath;
    final papelesId = newAttachment.papelesId;
    if (path == null && papelesId == null) {
      AppDialogs.toast(context, 'Could not read the selected file. Please pick it again.', success: false);
      return;
    }
    setState(() => _busy = true);
    AppHaptics.success();
    try {
      final updated = await service.attachRequirement(
        widget.requestId,
        requirementKey: requirementKey,
        filePath: path,
        papelesId: papelesId,
      );
      if (mounted) {
        setState(() => _latest = updated);
        AppDialogs.toast(context, 'Document attached.');
      }
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
      final updated = await service.resubmit(widget.requestId);
      if (mounted) {
        setState(() => _latest = updated);
        AppDialogs.toast(context, 'Application resubmitted.');
      }
    } on ApiException catch (e) {
      if (mounted) AppDialogs.toast(context, e.message(), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The resident takes back a Tulong request the office has not
  /// recommended yet (end-to-end test 2026-10-07: there was no way to).
  Future<void> _withdraw(RequestsService service, ServiceRequest request) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Withdraw this request?',
      message: 'The office stops working on ${request.referenceNumber} and it cannot be reopened. To ask again, file a new request.',
      confirmLabel: 'Withdraw',
      cancelLabel: 'Keep it',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await service.withdraw(widget.requestId);
      if (mounted) {
        setState(() => _latest = updated);
        AppDialogs.toast(context, '${request.referenceNumber} withdrawn.');
      }
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
        final result = tulongEligibilityFor(service, typeName: item.name);
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
          builder: (context, request, reload) => _buildBody(context, service, _latest ?? request),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RequestsService service, ServiceRequest request) {
    final accent = switch (request.category) {
      ServiceCategory.dokyu => AppColors.brand600,
      ServiceCategory.tulong => AppColors.purple700,
      ServiceCategory.sakunaIncident => AppColors.rose600,
      // Neutral: an accent borrowed from another service would imply one.
      ServiceCategory.unknown => AppColors.slate600,
    };
    final usesMilestones = request.category != ServiceCategory.sakunaIncident;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
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
                      style: const TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Capped at half the row, not a Flexible: a Flexible next to
                  // the Expanded title split the row 50/50, so the title could
                  // never use the space a short badge left over and wrapped
                  // ("Barangay / Clearance") beside empty space. The cap still
                  // stops a long label ("Under Verification") plus a long
                  // service name from overflowing a narrow phone.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
                    child: StatusChip.request(request.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(request.office, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.textMuted)),
              // The incident's severity and the citizen's own description
              // (B-052) -- the one free-text block this category has, where
              // Dokyu/Tulong instead show admin remarks and form fields.
              if (request.category == ServiceCategory.sakunaIncident && request.purpose.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(request.purpose, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.textPrimary)),
              ],
              if (request.incidentPhotos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _IncidentPhotos(urls: request.incidentPhotos),
              ],
              const Divider(height: AppSpacing.xxl),
              _infoRow('Submitted', dateAndTime(request.submittedAt)),
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
        if (_attachableOutsideCorrection(request).isNotEmpty || _rowsOutsideCorrection(request).isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _AttachSection(
            request: request,
            pending: _attachableOutsideCorrection(request),
            accent: accent,
            busy: _busy,
            onAttach: (key, a) => _attach(service, key, a),
            onReplace: (key, a) => _replaceFlagged(service, key, a),
          ),
        ],
        // Tulong's correction state is Needs Requirements; resubmitting
        // returns the case to Initial Screening.
        if (request.status == RequestMilestones.underReview || request.status == TulongStatus.needsRequirements) ...[
          const SizedBox(height: AppSpacing.xl),
          if (request.flaggedRequirements.isNotEmpty)
            _CorrectionsSection(
              request: request,
              accent: accent,
              busy: _busy,
              keyFor: _keyFor,
              onReplace: (flaggedId, a) => _replaceFlagged(service, flaggedId, a),
              onAttach: (key, a) => _attach(service, key, a),
              onResubmit: request.canResubmit ? () => _resubmit(service) : null,
            )
          else
            _ManualVerificationCard(
              needsRequirements: request.status == TulongStatus.needsRequirements,
              reason: request.adminRemarks ?? 'The request requires additional verification.',
            ),
        ],
        // A Tulong case once approved: what was approved, then what was
        // received. The office's assessment stays on the staff side.
        if (request.assistance != null && TulongStatus.approved.contains(request.status)) ...[
          const SizedBox(height: AppSpacing.xl),
          _AssistanceCard(status: request.status, assistance: request.assistance!, claimHint: request.pickup == null),
        ],
        if (request.payment != null && request.payment!.amount > 0) ...[
          const SizedBox(height: AppSpacing.xl),
          _FeeCard(payment: request.payment!),
        ],
        // Ready: where and how to claim it (2026-10-15).
        if (request.pickup != null) ...[
          const SizedBox(height: AppSpacing.xl),
          PickupCard(pickup: request.pickup!, reference: request.referenceNumber, accent: accent),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BookAppointmentScreen(requestRef: request.referenceNumber)),
              ),
              icon: const Icon(Icons.event_available_outlined, size: 18),
              label: const Text('Book a time to claim it'),
            ),
          ),
        ],
        // Issued: control number, verification QR and the signed copy (2026-10-15).
        if (request.issuedDocuments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          IssuedDocumentsCard(documents: request.issuedDocuments, accent: accent),
        ],
        // Once released: the photo or scan the office took at release.
        if (request.releaseProof != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _ReleaseProofCard(proof: request.releaseProof!, accent: accent),
        ],
        if (request.canWithdraw) ...[
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Withdraw Request',
            icon: Icons.undo_rounded,
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            loading: _busy,
            onPressed: _busy ? null : () => _withdraw(service, request),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          usesMilestones ? 'Request Timeline' : 'Status Timeline',
          style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: request.statusHistory.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('No history recorded yet.', style: TextStyle(color: AppColors.textMuted, fontSize: AppTextSize.label)),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
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
    return GlassSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      tint: AppColors.rose50,
      tintEnd: AppColors.rose50,
      rim: AppColors.rose500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, size: 18, color: AppColors.rose700),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Application Rejected',
                style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.rose700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(reason, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.slate700, height: 1.45)),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'What you can do:',
            style: TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w700, color: AppColors.slate700),
          ),
          const SizedBox(height: AppSpacing.xs),
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
  final void Function(String requirementKey, Attachment newAttachment) onAttach;
  final VoidCallback? onResubmit;

  const _CorrectionsSection({
    required this.request,
    required this.accent,
    required this.busy,
    required this.keyFor,
    required this.onReplace,
    required this.onAttach,
    required this.onResubmit,
  });

  @override
  Widget build(BuildContext context) {
    final unresolved = request.flaggedRequirements.where((f) => !f.isResolved).toList();
    // Required documents never uploaded sit here too, beside Resubmit: in a
    // separate card above, they were easy to miss, and the resident
    // resubmitted without the ID (QA run 2026-10-05).
    final missing = request.missingRequired;
    final allResolved = unresolved.isEmpty && missing.isEmpty;
    return GlassSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      tint: AppColors.orange50,
      tintEnd: AppColors.orange50,
      rim: AppColors.orange500,
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
                  style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.orange700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            allResolved
                ? 'All flagged documents have been replaced — you may now resubmit.'
                : unresolved.length + missing.length > 1
                    ? '${unresolved.length + missing.length} documents need your attention.'
                    : unresolved.isNotEmpty
                        ? '1 document requires correction.'
                        : '1 required document still needs to be attached.',
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
          for (final m in missing)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: ServerRequirementUploader(
                label: m.label,
                current: null,
                accent: accent,
                busy: busy,
                serviceName: request.typeName,
                category: request.category,
                allowPapeles: true,
                onPicked: (a) => onAttach(m.key, a),
              ),
            ),
          for (final done in request.flaggedRequirements.where((f) => f.isResolved))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.emerald700),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${done.requirementLabel}: replaced. The office checks it after you resubmit.',
                      style: AppTypography.captionSmallRegular.copyWith(color: AppColors.slate700, height: 1.4),
                    ),
                  ),
                ],
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
          if (!allResolved || onResubmit == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              unresolved.isNotEmpty
                  ? (unresolved.length > 1
                        ? 'Replace the flagged documents above first, then resubmit.'
                        : 'Replace the flagged document above first, then resubmit.')
                  : missing.isNotEmpty
                      ? 'Attach the required document${missing.length > 1 ? 's' : ''} above first, then resubmit.'
                      : 'This request cannot be resubmitted right now. Pull down to refresh.',
              style: AppTypography.captionSmallRegular.copyWith(color: AppColors.slate500, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// The requirement rows the documents card shows: during a correction, the
/// ones the correction card already handles (flagged, replaced, or missing and
/// required) are left to it.
List<RequirementRow> _rowsOutsideCorrection(ServiceRequest request) {
  final inCorrection = request.status == RequestMilestones.underReview || request.status == TulongStatus.needsRequirements;
  if (!inCorrection || request.flaggedRequirements.isEmpty) return request.requirementRows;
  final inCard = {...request.flaggedRequirements.map((f) => f.id), ...request.missingRequired.map((m) => m.key)};
  return request.requirementRows.where((r) => !inCard.contains(r.key)).toList();
}

/// Required, optional, or done at the office: the server's rule
/// (RequestRequirement::needsFile), read from the line's own wording.
class _RequirementKindChip extends StatelessWidget {
  final String label;
  const _RequirementKindChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final info = resolveRequirements([label]).single;
    final (text, bg, fg) = !info.requiresUpload
        ? ('Done at the office', AppColors.slate100, AppColors.slate600)
        : info.isRequired
        ? ('Required', AppColors.rose50, AppColors.rose600)
        : ('If it applies', AppColors.slate100, AppColors.slate600);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Text(text, style: TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

/// A requirement with no upload control: its name and where it stands.
class _RequirementStateRow extends StatelessWidget {
  final String label;
  final String line;
  final Color color;
  final bool accepted;
  const _RequirementStateRow({required this.label, required this.line, required this.color, this.accepted = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(accepted ? Icons.check_circle_rounded : Icons.description_outlined, size: 18, color: accepted ? AppColors.emerald700 : AppColors.slate500),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(line, style: AppTypography.captionSmallRegular.copyWith(color: color, fontWeight: accepted ? FontWeight.w600 : FontWeight.w400, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The documents the top card offers: during a correction, the missing
/// required ones are offered in the correction card instead, beside Resubmit.
List<PendingRequirement> _attachableOutsideCorrection(ServiceRequest request) {
  final inCorrection = request.status == RequestMilestones.underReview || request.status == TulongStatus.needsRequirements;
  if (!inCorrection || request.flaggedRequirements.isEmpty) return request.attachableRequirements;
  final inCard = request.missingRequired.map((m) => m.key).toSet();
  return request.attachableRequirements.where((p) => !inCard.contains(p.key)).toList();
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
    return GlassSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.md),
      rim: AppColors.orange500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flagged.requirementLabel,
            style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reason: ${flagged.reason}',
            style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.slate600, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          ServerRequirementUploader(
            label: flagged.requirementLabel,
            showTitle: false,
            current: currentAttachment,
            accent: accent,
            busy: busy,
            serviceName: serviceName,
            category: category,
            onPicked: onReplace,
          ),
        ],
      ),
    );
  }
}

/// Requirements the office has not decided yet ([PendingRequirement]): the
/// resident attaches each document here, or changes it, while the request is
/// being verified. Nothing is resubmitted; the office reviews what is on file.
class _AttachSection extends StatelessWidget {
  final ServiceRequest request;
  final List<PendingRequirement> pending;
  final Color accent;
  final bool busy;
  final void Function(String requirementKey, Attachment newAttachment) onAttach;

  /// A rejected document's replacement (see [RequirementRow.replaceable]).
  final void Function(String requirementKey, Attachment newAttachment) onReplace;

  const _AttachSection({
    required this.request,
    required this.pending,
    required this.accent,
    required this.busy,
    required this.onAttach,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final pendingKeys = {for (final p in pending) p.key};
    final rows = _rowsOutsideCorrection(request);
    // What the resident still owes: a required document with no file yet.
    final owed = pending.where((p) {
      final info = resolveRequirements([p.label]).single;
      return info.isRequired && info.requiresUpload && _attachmentFor(request, p.label) == null;
    }).length;
    final accepted = rows.where((r) => r.isAccepted).length;
    final rejected = rows.where((r) => r.isRejected).length;
    final summary = [
      if (rejected > 0)
        rejected == 1
            ? '1 document was not accepted: replace it below so the office can review it again.'
            : '$rejected documents were not accepted: replace them below so the office can review them again.',
      if (owed > 0) owed == 1 ? '1 required document still needs to be attached.' : '$owed required documents still need to be attached.',
      if (owed == 0 && pending.isNotEmpty) 'Every required document is attached. You can change one until the office reviews it.',
      if (rows.isNotEmpty) '$accepted of ${rows.length} accepted by the office.',
    ].join(' ');
    return GlassSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file_rounded, size: 18, color: accent),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Documents for this request',
                  style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary,
            style: AppTypography.captionSmallRegular.copyWith(
              color: rejected > 0 ? AppColors.rose600 : (owed > 0 ? AppColors.orange700 : AppColors.slate500),
              height: 1.4,
            ),
          ),
          for (final p in pending)
            if (!rows.any((r) => r.key == p.key) || !rows.firstWhere((r) => r.key == p.key).isAccepted)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RequirementKindChip(label: p.label),
                    if (resolveRequirements([p.label]).single.requiresUpload)
                      ServerRequirementUploader(
                        label: p.label,
                        current: _attachmentFor(request, p.label),
                        accent: accent,
                        busy: busy,
                        serviceName: request.typeName,
                        category: request.category,
                        allowPapeles: true,
                        onPicked: (a) => onAttach(p.key, a),
                      )
                    else
                      _RequirementStateRow(label: p.label, line: 'Nothing to upload: the office does this with you.', color: AppColors.slate500),
                  ],
                ),
              ),
          // Everything not open for upload: accepted ones stay, in green; a
          // rejected one says why and takes a replacement (Esperanza QA,
          // 2026-10-07: the resident saw neither the reason nor a way to fix it).
          for (final r in rows.where((r) => !pendingKeys.contains(r.key)))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: r.isRejected
                  ? _RejectedRequirement(
                      row: r,
                      request: request,
                      accent: accent,
                      busy: busy,
                      onReplace: (a) => onReplace(r.key, a),
                    )
                  : _RequirementStateRow(
                label: r.label,
                line: switch (r.status) {
                  'Approved' => 'Accepted by the office${r.fileName == null ? '' : ' · ${r.fileName}'}',
                  'Rejected' => 'Not accepted by the office',
                  'Flagged for Replacement' => 'The office asked for a replacement',
                  'Resubmitted' => 'Replaced; the office checks it again',
                  _ => r.fileName == null ? 'With the office' : 'With the office · ${r.fileName}',
                },
                color: switch (r.status) {
                  'Approved' => AppColors.emerald700,
                  'Rejected' => AppColors.rose600,
                  'Flagged for Replacement' => AppColors.orange700,
                  _ => AppColors.slate500,
                },
                accepted: r.isAccepted,
              ),
            ),
        ],
      ),
    );
  }
}

/// A document the office rejected: the reason, and - while the office can
/// still review one - an upload for its replacement, which goes back to the
/// office as Resubmitted. Once the request has moved on, it only says so.
class _RejectedRequirement extends StatelessWidget {
  final RequirementRow row;
  final ServiceRequest request;
  final Color accent;
  final bool busy;
  final ValueChanged<Attachment> onReplace;

  const _RejectedRequirement({
    required this.row,
    required this.request,
    required this.accent,
    required this.busy,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final why = [?row.reason, if (row.remarks != null && row.remarks != row.reason) row.remarks!].join(' — ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementStateRow(
          label: row.label,
          line: row.replaceable ? 'Not accepted by the office. Upload a replacement.' : 'Not accepted by the office',
          color: AppColors.rose600,
        ),
        if (why.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 26, top: AppSpacing.xs),
            child: Text(
              'Reason: $why',
              style: AppTypography.captionSmallRegular.copyWith(color: AppColors.rose700, height: 1.4),
            ),
          ),
        if (row.replaceable)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: ServerRequirementUploader(
              label: row.label,
              showTitle: false,
              current: null,
              accent: accent,
              busy: busy,
              serviceName: request.typeName,
              category: request.category,
              onPicked: onReplace,
            ),
          ),
      ],
    );
  }
}

/// "Needs manual verification" — the server's own Under Review with no
/// specific requirement flagged (decision_remarks explains why, but
/// needs_correction is empty). Nothing for the citizen to upload or
/// correct, so unlike the corrections section this never embeds a
/// [RequirementUploader] — just the plain-language explanation. Never
/// styled or worded like a rejection.
/// The request's fee and where it stands: pay at the office (which issues the
/// official receipt), paid with the receipt number, or not accepted.
class _FeeCard extends StatelessWidget {
  final RequestPayment payment;
  const _FeeCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, line) = payment.isPaid
        ? (AppColors.emerald50, AppColors.emerald700, Icons.receipt_long_rounded, 'Paid. Official receipt ${payment.receiptNo ?? '—'}.')
        : payment.isRejected
        ? (AppColors.rose50, AppColors.rose600, Icons.error_outline_rounded, 'The payment was not accepted. Please contact the office.')
        : (AppColors.orange50, AppColors.orange700, Icons.payments_outlined, 'Pay at the office and bring your reference number. The office issues the official receipt.');
    return GlassSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      tint: bg,
      tintEnd: bg,
      rim: fg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Fee', style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: fg)),
              ),
              Text(
                pesoText(payment.amount.toStringAsFixed(2)) ?? '',
                style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(line, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.slate700, height: 1.4)),
        ],
      ),
    );
  }
}

class _AssistanceCard extends StatelessWidget {
  final String status;
  final TulongAssistance assistance;
  const _AssistanceCard({required this.status, required this.assistance, this.claimHint = true});

  /// The one-line claim hint, when the server sent no pickup details.
  final bool claimHint;

  @override
  Widget build(BuildContext context) {
    final received = status == TulongStatus.completed;
    final title = switch (status) {
      TulongStatus.readyForRelease => 'Ready to claim',
      TulongStatus.completed => 'Assistance received',
      _ => 'Approved — being prepared',
    };
    final amount = pesoText(received ? (assistance.releasedAmount ?? assistance.approvedAmount) : assistance.approvedAmount);
    return GlassSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      tint: AppColors.emerald50,
      tintEnd: AppColors.emerald50,
      rim: AppColors.emerald500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(received ? Icons.task_alt_rounded : Icons.verified_outlined, size: 18, color: AppColors.emerald700),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.emerald700),
                ),
              ),
            ],
          ),
          if (amount != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(received ? 'Amount received' : 'Approved amount', style: AppTypography.captionSmallRegular.copyWith(color: AppColors.slate600)),
            Text(amount, style: const TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
          if (received && assistance.releaseReference != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Reference: ${assistance.releaseReference}', style: AppTypography.bodySmallRegular.copyWith(color: AppColors.slate700)),
          ],
          if (received && assistance.releasedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(dateAndTime(assistance.releasedAt!), style: AppTypography.captionSmallRegular.copyWith(color: AppColors.slate600)),
          ],
          if (claimHint && status == TulongStatus.readyForRelease) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bring a valid ID to ${assistance.office ?? 'the office'} to claim it.',
              style: AppTypography.bodySmallRegular.copyWith(color: AppColors.slate700, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManualVerificationCard extends StatelessWidget {
  /// Tulong's correction state: a Tulong case never reads as Under Review,
  /// which is Dokyu's.
  final bool needsRequirements;
  final String reason;
  const _ManualVerificationCard({required this.needsRequirements, required this.reason});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      tint: AppColors.orange50,
      tintEnd: AppColors.orange50,
      rim: AppColors.orange500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, size: 18, color: AppColors.orange700),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  needsRequirements ? 'Needs Requirements' : 'Under Review',
                  style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.orange700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(reason, style: AppTypography.bodySmallRegular.copyWith(color: AppColors.slate700, height: 1.45)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            needsRequirements
                ? 'The office needs more for this case. Read the remarks above, or contact the MSWDO. This is still an '
                      'active request, not a rejection.'
                : 'The request requires additional verification. This is still an active request, not a rejection — no '
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
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.status as String, style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${entry.actor} · ${dateAndTime(entry.at as DateTime)}',
                      style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted),
                    ),
                    if (entry.remarks != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.remarks as String,
                        style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.slate600, height: 1.3),
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

}

/// The proof of release the office captured (Esperanza QA, 2026-10-07: a
/// released Pet Registration showed the status but not the proof). An image
/// opens in the app's viewer; any other file opens outside the app. The link
/// is the server's signed, short-lived one, issued only on the resident's own
/// request detail.
/// The photos the resident sent with an incident report. One the server is
/// still checking has no link yet and says so.
class _IncidentPhotos extends StatelessWidget {
  final List<String?> urls;
  const _IncidentPhotos({required this.urls});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < urls.length; i++)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 88,
              height: 88,
              child: urls[i] == null
                  ? Container(
                      color: AppColors.slate100,
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      alignment: Alignment.center,
                      child: Text(
                        'Being checked',
                        textAlign: TextAlign.center,
                        style: AppTypography.captionSmallRegular.copyWith(color: AppColors.textMuted),
                      ),
                    )
                  : Semantics(
                      button: true,
                      label: 'Open photo ${i + 1} of ${urls.length}',
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ImageViewerScaffold(
                              title: 'Photo ${i + 1} of ${urls.length}',
                              image: NetworkImage(urls[i]!),
                              semanticLabel: 'Photo ${i + 1} you sent with the report',
                            ),
                          ),
                        ),
                        child: Image.network(
                          urls[i]!,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.slate100,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported_outlined, color: AppColors.slate500),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _ReleaseProofCard extends StatelessWidget {
  final Attachment proof;
  final Color accent;
  const _ReleaseProofCard({required this.proof, required this.accent});

  Future<void> _open(BuildContext context) async {
    final url = proof.remoteUrl;
    if (url == null) return;
    if (proof.category == AttachmentCategory.image) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScaffold(
            title: 'Proof of release',
            image: NetworkImage(url),
            semanticLabel: 'Proof of release photo',
          ),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) AppDialogs.toast(context, 'Could not open the file. Pull down to refresh, then try again.', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.verified_outlined, size: 20, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proof of release',
                  style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(proof.fileName, style: AppTypography.captionSmallRegular.copyWith(color: AppColors.slate500)),
              ],
            ),
          ),
          TextButton(onPressed: () => _open(context), child: const Text('View')),
        ],
      ),
    );
  }
}
