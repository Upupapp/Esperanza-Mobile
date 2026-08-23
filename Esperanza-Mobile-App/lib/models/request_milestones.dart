import '../theme/app_status.dart';

/// The richer, frontend-simulation-only milestone sequence a Dokyu/Tulong
/// request's timeline walks through — see docs on Phase 5 (milestone
/// simulation). This is deliberately a *separate* vocabulary from
/// [AppStatus]: [AppStatus]'s own doc comment forbids inventing new status
/// labels there (it's the universal, Web-Admin-shared status system), but
/// the payment sub-steps here (Waiting for Payment, Payment Method
/// Selected, Payment Processing, Paid) have no equivalent among its 14
/// canonical values. [RequestMilestones.canonicalStatusFor] maps every
/// milestone label to its nearest [AppStatus] for the request's actual
/// `status`/StatusChip field, so that field only ever holds one of the 14
/// canonical labels; the milestone label itself is what the timeline
/// widget displays and what `StatusHistoryEntry.status` records for these
/// steps.
class RequestMilestones {
  RequestMilestones._();

  static const submitted = 'Submitted';
  static const pendingReview = 'Pending Review';
  static const underVerification = 'Under Verification';
  static const processing = 'Processing';
  static const approved = 'Approved';
  static const waitingForPayment = 'Waiting for Payment';
  static const paymentMethodSelected = 'Payment Method Selected';
  static const paymentProcessing = 'Payment Processing';
  static const receiptGenerated = 'Receipt Generated';
  static const paid = 'Paid';
  static const readyForRelease = 'Ready for Release';
  static const completed = 'Completed';
  static const rejected = 'Rejected';

  static const List<String> _base = [submitted, pendingReview, underVerification, processing, approved];
  static const List<String> _paymentLeg = [
    waitingForPayment,
    paymentMethodSelected,
    paymentProcessing,
    receiptGenerated,
    paid,
  ];
  static const List<String> _tail = [readyForRelease, completed];

  /// The full ordered path a request walks, given whether its service
  /// requires payment (from the catalog item's own `fee` field — see
  /// [CatalogItem.fee] callers; never invented here). Services with no fee
  /// skip straight from Approved to Ready for Release.
  static List<String> sequenceFor({required bool requiresPayment}) =>
      requiresPayment ? [..._base, ..._paymentLeg, ..._tail] : [..._base, ..._tail];

  /// Nearest canonical [AppStatus] for a milestone label — exact match for
  /// the 7 labels that already are canonical names; the 4 payment
  /// sub-steps map to the closest existing meaning rather than inventing
  /// new ones ("there's an outstanding requirement" for the first three,
  /// "now moving toward release" once paid).
  static AppStatus canonicalStatusFor(String milestone) {
    switch (milestone) {
      case waitingForPayment:
      case paymentMethodSelected:
      case paymentProcessing:
        return AppStatus.waitingRequirements;
      case receiptGenerated:
      case paid:
        return AppStatus.processing;
      case rejected:
        return AppStatus.rejected;
      default:
        return AppStatusX.fromLabel(milestone);
    }
  }
}
