import 'package:flutter/material.dart';
import '../models/request_milestones.dart';
import '../models/service_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/tulong_status.dart';
import '../utils/date_text.dart';
import 'esperanza_art.dart';

/// The richer Dokyu/Tulong milestone timeline (Phase 5, rewritten for the
/// Mobile-only final request-flow correction pass — frontend simulation
/// only, see docs). Unlike the plain "history so far" list this replaces,
/// it shows the *entire* primary path for this request — completed steps,
/// the current one clearly highlighted, and future ones grayed out with a
/// placeholder instead of a date — using [RequestMilestones.sequence]'s
/// fixed 5 stages (Submitted, Under Verification, Approved, Mark to
/// Release, Released; payment no longer appears here at all — see that
/// class's own doc comment) so a citizen always sees what's still ahead.
/// Branches into a distinct Rejected or Under Review view instead of the
/// normal tail when applicable, since both can happen from any point in
/// the sequence — Under Review is the only one of the two that's
/// resumable: once resolved the request re-enters the sequence at Under
/// Verification and this branch stops applying on the next rebuild.
///
/// A Tulong case shows its own seven-step main line instead
/// ([TulongStatus.mainSequence]): Needs Requirements is its correction branch
/// (resubmitting returns it to Initial Screening), Returned for Reassessment
/// a note on the current step, and a cancelled case closes like a rejected one.
class RequestMilestoneTimeline extends StatelessWidget {
  final ServiceRequest request;
  final Color accent;

  const RequestMilestoneTimeline({super.key, required this.request, required this.accent});

  @override
  Widget build(BuildContext context) {
    // No recorded history is not a rejection — `.last` on an empty list threw
    // here, which would have moved the decode crash into the timeline.
    final isTulong = request.category == ServiceCategory.tulong;
    // Cancelled on Dokyu too: the office's reason was shown only for Tulong
    // (parity check, 2026-10-26).
    final isCancelledCase = request.status == TulongStatus.cancelled;
    final isRejected = request.statusHistory.lastOrNull?.status == RequestMilestones.rejected || isCancelledCase;
    bool needsAction(String status) =>
        status == RequestMilestones.underReview || (isTulong && status == TulongStatus.needsRequirements);
    final isUnderReview = needsAction(request.status);

    if (isUnderReview) {
      final entries = request.statusHistory;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < entries.length; i++)
            _MilestoneRow(
              label: entries[i].status,
              state: needsAction(entries[i].status) ? _MilestoneState.needsAction : _MilestoneState.done,
              timestamp: entries[i].at,
              remarks: needsAction(entries[i].status) ? null : entries[i].remarks,
              isLast: i == entries.length - 1,
              accent: accent,
            ),
        ],
      );
    }

    if (isRejected) {
      // Every entry actually recorded (everything reached before the
      // branch, then the Rejected entry itself) — rejection can happen
      // from any point in the sequence, so this walks the real recorded
      // order rather than the fixed one.
      final entries = request.statusHistory;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < entries.length; i++)
            _MilestoneRow(
              label: entries[i].status,
              state: _closes(entries[i].status, isCancelledCase) ? _MilestoneState.rejected : _MilestoneState.done,
              timestamp: entries[i].at,
              // The Rejected entry's own remarks duplicate what
              // _RejectionReasonCard already shows prominently below.
              remarks: _closes(entries[i].status, isCancelledCase) ? null : entries[i].remarks,
              isLast: i == entries.length - 1,
              accent: accent,
            ),
          if (request.adminRemarks != null) ...[
            const SizedBox(height: AppSpacing.md),
            _RejectionReasonCard(
              reason: request.adminRemarks!,
              title: request.status == TulongStatus.cancelled ? 'Reason for Cancellation' : 'Reason for Rejection',
            ),
          ],
        ],
      );
    }

    final sequence = isTulong ? TulongStatus.mainSequence : RequestMilestones.sequence;
    final reachedAt = <String, DateTime>{
      // Filing is not a transition on the server (a request is created
      // Submitted), so the first step's time is the request's own.
      if (sequence.isNotEmpty && sequence.first == 'Submitted') 'Submitted': request.submittedAt,
      for (final e in request.statusHistory)
        if (sequence.contains(e.status)) e.status: e.at,
    };
    final remarksFor = <String, String>{
      for (final e in request.statusHistory)
        if (sequence.contains(e.status) && e.remarks != null) e.status: e.remarks!,
    };
    // The furthest point actually reached — normally the same as the last
    // history entry, but derived from the sequence itself so a
    // out-of-order/legacy history (e.g. old seeded demo data written
    // before this timeline existed) still renders sensibly instead of
    // crashing or mis-highlighting.
    var currentIndex = -1;
    for (var i = 0; i < sequence.length; i++) {
      if (reachedAt.containsKey(sequence[i])) currentIndex = i;
    }
    // A Tulong case can step back (Returned for Reassessment resumes at
    // Assessment), so where it stands is its current status, not the
    // furthest step it ever reached.
    if (isTulong) {
      final at = sequence.indexOf(TulongStatus.stepFor(request.status));
      if (at >= 0) currentIndex = at;
    }
    final returned = isTulong && request.status == TulongStatus.returnedForReassessment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < sequence.length; i++)
          _MilestoneRow(
            label: sequence[i],
            state: i < currentIndex
                ? _MilestoneState.done
                : i == currentIndex
                ? _MilestoneState.current
                : _MilestoneState.future,
            timestamp: i <= currentIndex ? reachedAt[sequence[i]] : null,
            remarks: returned && i == currentIndex
                ? 'Returned for reassessment: the office is re-checking your case. Nothing is needed from you.'
                : remarksFor[sequence[i]],
            isLast: i == sequence.length - 1,
            accent: accent,
          ),
      ],
    );
  }
}

/// The entry that closed the case: Rejected, or a Tulong case's Cancelled.
bool _closes(String status, bool cancelledCase) =>
    status == RequestMilestones.rejected || (cancelledCase && status == TulongStatus.cancelled);

enum _MilestoneState { done, current, future, rejected, needsAction }

class _MilestoneRow extends StatelessWidget {
  final String label;
  final _MilestoneState state;
  final DateTime? timestamp;
  final String? remarks;
  final bool isLast;
  final Color accent;

  const _MilestoneRow({
    required this.label,
    required this.state,
    required this.timestamp,
    this.remarks,
    required this.isLast,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (state) {
      _MilestoneState.done => accent,
      _MilestoneState.current => accent,
      _MilestoneState.future => AppColors.slate300,
      _MilestoneState.rejected => AppColors.rose600,
      _MilestoneState.needsAction => AppColors.orange500,
    };
    final labelStyle = switch (state) {
      _MilestoneState.future => const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.textMuted),
      _MilestoneState.rejected => const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.rose700),
      _MilestoneState.needsAction => const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.orange700),
      _ => TextStyle(
          fontSize: AppTextSize.helper,
          fontWeight: state == _MilestoneState.current ? FontWeight.w700 : FontWeight.w600,
          color: AppColors.textPrimary,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // 2026-10 design: a step done is a filled circle with a check,
                // the current step a gold ball with a glow, a step ahead a
                // white ring; a refusal or a request for action carries its
                // own mark, so colour is never the only signal.
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: switch (state) {
                      _MilestoneState.future => AppColors.surface,
                      _MilestoneState.current => AppColors.gold400,
                      _ => dotColor,
                    },
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: state == _MilestoneState.future ? AppColors.slate300 : AppColors.surface,
                      width: state == _MilestoneState.future ? 1.6 : 2,
                    ),
                    boxShadow: state == _MilestoneState.future
                        ? null
                        : [
                            BoxShadow(
                              color: (state == _MilestoneState.current ? AppColors.gold400 : dotColor).withValues(alpha: 0.40),
                              blurRadius: state == _MilestoneState.current ? 10 : 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: switch (state) {
                    _MilestoneState.done => const Icon(Icons.check_rounded, size: 13, color: AppColors.surface),
                    _MilestoneState.current => Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: AppColors.navy900, shape: BoxShape.circle),
                    ),
                    _MilestoneState.rejected => const Icon(Icons.close_rounded, size: 13, color: AppColors.surface),
                    _MilestoneState.needsAction => const Icon(Icons.priority_high_rounded, size: 13, color: AppColors.surface),
                    _MilestoneState.future => null,
                  },
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      color: state == _MilestoneState.future ? AppColors.slate200 : dotColor.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: labelStyle),
                    // Under the label, not beside it: a full date and time
                    // ("Sep 24, 2026, 8:30 AM") does not fit beside a long
                    // step name on a 320pt phone.
                    if (timestamp != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        dateAndTime(timestamp!),
                        style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted),
                      ),
                    ],
                    if (remarks != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        remarks!,
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

class _RejectionReasonCard extends StatelessWidget {
  final String reason;
  final String title;
  const _RejectionReasonCard({required this.reason, required this.title});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.md),
      tint: AppColors.rose50,
      tintEnd: AppColors.rose50,
      rim: AppColors.rose500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.rose600, size: 18),
              const SizedBox(width: AppSpacing.sm),
              // Flexible: "Reason for Cancellation" ran 33 px past a 390-wide
              // phone at a large text size.
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.rose700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(reason, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose700, height: 1.45)),
        ],
      ),
    );
  }
}
