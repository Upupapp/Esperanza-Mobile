import 'package:flutter/material.dart';
import '../models/request_milestones.dart';
import '../models/service_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_text.dart';

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
class RequestMilestoneTimeline extends StatelessWidget {
  final ServiceRequest request;
  final Color accent;

  const RequestMilestoneTimeline({super.key, required this.request, required this.accent});

  @override
  Widget build(BuildContext context) {
    // No recorded history is not a rejection — `.last` on an empty list threw
    // here, which would have moved the decode crash into the timeline.
    final isRejected = request.statusHistory.lastOrNull?.status == RequestMilestones.rejected;
    final isUnderReview = request.status == RequestMilestones.underReview;

    if (isUnderReview) {
      final entries = request.statusHistory;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < entries.length; i++)
            _MilestoneRow(
              label: entries[i].status,
              state: entries[i].status == RequestMilestones.underReview ? _MilestoneState.needsAction : _MilestoneState.done,
              timestamp: entries[i].at,
              remarks: entries[i].status == RequestMilestones.underReview ? null : entries[i].remarks,
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
              state: entries[i].status == RequestMilestones.rejected ? _MilestoneState.rejected : _MilestoneState.done,
              timestamp: entries[i].at,
              // The Rejected entry's own remarks duplicate what
              // _RejectionReasonCard already shows prominently below.
              remarks: entries[i].status == RequestMilestones.rejected ? null : entries[i].remarks,
              isLast: i == entries.length - 1,
              accent: accent,
            ),
          if (request.adminRemarks != null) ...[
            const SizedBox(height: AppSpacing.md),
            _RejectionReasonCard(reason: request.adminRemarks!),
          ],
        ],
      );
    }

    final sequence = RequestMilestones.sequence;
    final reachedAt = <String, DateTime>{
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
            timestamp: reachedAt[sequence[i]],
            remarks: remarksFor[sequence[i]],
            isLast: i == sequence.length - 1,
            accent: accent,
          ),
      ],
    );
  }
}

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
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: state == _MilestoneState.current ? 14 : 10,
                  height: state == _MilestoneState.current ? 14 : 10,
                  decoration: BoxDecoration(
                    color: state == _MilestoneState.future ? Colors.white : dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: state == _MilestoneState.future ? 1.5 : 0),
                    boxShadow: state == _MilestoneState.current
                        ? [BoxShadow(color: dotColor.withValues(alpha: 0.35), blurRadius: 6, spreadRadius: 2)]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      color: state == _MilestoneState.future ? AppColors.slate100 : dotColor.withValues(alpha: 0.35),
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
  const _RejectionReasonCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.rose50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.rose500.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.rose600, size: 18),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Reason for Rejection',
                style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.rose700),
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
