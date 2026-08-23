import '../models/service_request.dart';
import '../services/requests_service.dart';

/// Per assistance type, per resident — Dokyu has no such limit (a document
/// may legitimately be needed again for a different purpose), but the same
/// Tulong assistance may only be applied for this many times, matching the
/// demo's intentional "no farming the same assistance" rule.
const int tulongApplicationLimitPerAssistance = 2;

/// How many of [applicantId]'s own submitted requests are for this exact
/// Tulong assistance ([typeName]) — every submitted record counts once it
/// has a real reference number, regardless of whether it later becomes
/// Pending, Approved, Rejected, or Completed; a Cancelled request is the
/// one status this project's existing business logic already treats as
/// "doesn't count" (see RequestsService.cancel), so it's excluded here too.
/// There is no separate "draft" ServiceRequest — submit() only ever
/// creates one once the citizen has actually submitted, so an abandoned or
/// never-submitted form was never counted in the first place.
int tulongApplicationCountFor(RequestsService requests, {required String applicantId, required String typeName}) {
  return requests.all
      .where(
        (r) =>
            r.applicantId == applicantId &&
            r.category == ServiceCategory.tulong &&
            r.typeName == typeName &&
            r.status != 'Cancelled',
      )
      .length;
}

/// Whether [applicantId] has already reached [tulongApplicationLimitPerAssistance]
/// submitted applications for this exact assistance — a third attempt at
/// the SAME assistance must be blocked, but this never affects a different
/// Tulong assistance type, which has its own independent count.
bool hasReachedTulongApplicationLimit(RequestsService requests, {required String applicantId, required String typeName}) =>
    tulongApplicationCountFor(requests, applicantId: applicantId, typeName: typeName) >=
    tulongApplicationLimitPerAssistance;
