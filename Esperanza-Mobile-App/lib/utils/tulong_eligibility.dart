import 'package:flutter/material.dart';
import '../models/service_request.dart';
import '../services/requests_service.dart';
import '../theme/tulong_status.dart';
import '../widgets/app_dialogs.dart';

/// Per assistance type, per resident — Dokyu has no such restriction (a
/// document may legitimately be needed again for a different purpose, see
/// docs on Dokyu's own repeat-request rule), but the SAME Tulong assistance
/// may not be applied for again while a previous application for it is
/// still active or already succeeded. Reapplying to the same assistance is
/// only allowed once every prior application for it was Rejected (or
/// Cancelled — this project's existing business logic already treats a
/// citizen-cancelled request the same as "doesn't block anything further",
/// see RequestsService.cancel/the old tulong_application_limit.dart this
/// file replaces). This is a status check, not a count cap: a resident can
/// be rejected and reapply any number of times, but never holds two
/// concurrent (or one successful) applications for the same assistance.
enum TulongEligibility {
  eligible,

  /// A previous application for this assistance is still being decided
  /// (Submitted, Initial Screening, Needs Requirements, Assessment, For
  /// Approval or Returned for Reassessment — Tulong's own case statuses,
  /// see [TulongStatus]).
  blockedActive,

  /// This assistance was already approved for the resident — Assistance
  /// Processing, Ready for Release or Completed ([TulongStatus.approved]).
  blockedReceived,
}

class TulongEligibilityResult {
  final TulongEligibility status;

  /// The specific prior request that's blocking a new one — null only when
  /// [status] is [TulongEligibility.eligible].
  final ServiceRequest? blockingRequest;

  const TulongEligibilityResult(this.status, this.blockingRequest);

  bool get isEligible => status == TulongEligibility.eligible;
}

const _successfulTulongStatuses = {...TulongStatus.approved};
const _reapplicableTulongStatuses = {'Rejected', 'Cancelled'};

/// Whether the signed-in citizen may currently apply for the Tulong
/// assistance [typeName] — checks every one of their own past requests for
/// this exact assistance (newest first) and blocks on the first one that
/// isn't Rejected/Cancelled. A different assistance type is never affected;
/// it has its own independent history.
///
/// No longer filters by applicant id: GET /citizen/requests is scoped to the
/// signed-in citizen by the bearer token, so [requests].all already contains
/// only their own requests (production-readiness programme, 2026-09-25).
/// Filtering by id client-side was load-bearing under the old local
/// simulation, which held every demo account's requests in one shared pool
/// and needed it to isolate "mine" -- RequestsService never populates
/// applicantId from the real API at all now, so keeping that check would
/// have silently matched nothing and made this gate a permanent no-op.
TulongEligibilityResult tulongEligibilityFor(RequestsService requests, {required String typeName}) {
  final matches = requests.all.where((r) => r.category == ServiceCategory.tulong && r.typeName == typeName).toList()
    ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  for (final r in matches) {
    if (_reapplicableTulongStatuses.contains(r.status)) continue;
    final status = _successfulTulongStatuses.contains(r.status)
        ? TulongEligibility.blockedReceived
        : TulongEligibility.blockedActive;
    return TulongEligibilityResult(status, r);
  }
  return const TulongEligibilityResult(TulongEligibility.eligible, null);
}

/// Shows the appropriate blocked-application dialog for [result] (must not
/// be eligible) and returns true if the citizen chose to view the blocking
/// request — the caller is responsible for the actual navigation, since
/// this file has no screen dependency of its own.
///
/// An approved case the resident has not claimed yet (Assistance Processing,
/// Ready for Release) is "approved", not "received": telling them they
/// already received it would be untrue until it is Completed.
Future<bool> showTulongBlockedDialog(BuildContext context, TulongEligibilityResult result) {
  final isApproved = result.status == TulongEligibility.blockedReceived;
  final isReceived = isApproved && result.blockingRequest?.status == TulongStatus.completed;
  return AppDialogs.confirm(
    context,
    title: isReceived
        ? 'Assistance Already Received'
        : isApproved
        ? 'Assistance Already Approved'
        : 'Active Application Exists',
    message: isReceived
        ? 'You have already received this assistance and cannot submit another application for the same '
              'assistance at this time.'
        : isApproved
        ? 'This assistance has already been approved for you and is being prepared or is ready to claim. '
              'You cannot submit another application for it at this time.'
        : 'You already have an active application for this assistance.',
    confirmLabel: isApproved ? 'View Previous Request' : 'View Existing Request',
    cancelLabel: 'Close',
  );
}
