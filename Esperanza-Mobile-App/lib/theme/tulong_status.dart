import 'app_colors.dart';
import 'app_status.dart';

/// Tulong's own case-status vocabulary: a closed set of eleven, beside
/// [AppStatus] and never part of it.
///
/// A Tulong case is screened, assessed, approved, processed and released, so
/// it does not run the request lifecycle Dokyu runs. The web declares the set
/// in `config/esperanza_tulong_lifecycle.php`, and the backend has run it since
/// its finding B-044 closed (2026-10-04). [AppStatus] stays the web badge
/// component's seventeen labels; `tulong_status_test.dart` pins this file to
/// the web config the way `status_parity_test.dart` pins [AppStatus].
///
/// Four names (Submitted, Completed, Rejected, Cancelled) are shared with
/// [AppStatus] by coincidence of English and resolve there. The seven
/// Tulong-only names are styled here, in the web Tulong pages' colours.
class TulongStatus {
  TulongStatus._();

  static const submitted = 'Submitted';
  static const initialScreening = 'Initial Screening';
  static const assessment = 'Assessment';
  static const forApproval = 'For Approval';
  static const assistanceProcessing = 'Assistance Processing';
  static const readyForRelease = 'Ready for Release';
  static const completed = 'Completed';
  static const needsRequirements = 'Needs Requirements';
  static const returnedForReassessment = 'Returned for Reassessment';
  static const rejected = 'Rejected';
  static const cancelled = 'Cancelled';

  /// The main line, in order: the resident's tracking timeline.
  static const mainSequence = [
    submitted,
    initialScreening,
    assessment,
    forApproval,
    assistanceProcessing,
    readyForRelease,
    completed,
  ];

  /// Holds on the main line, not steps in it. Needs Requirements waits on the
  /// resident; Returned for Reassessment is the office's own re-check.
  static const sideStates = [needsRequirements, returnedForReassessment];

  static const terminal = [completed, rejected, cancelled];

  static const all = [
    submitted,
    initialScreening,
    assessment,
    forApproval,
    assistanceProcessing,
    readyForRelease,
    completed,
    needsRequirements,
    returnedForReassessment,
    rejected,
    cancelled,
  ];

  /// The seven names [AppStatus] does not have.
  static const tulongOnly = [
    initialScreening,
    assessment,
    forApproval,
    assistanceProcessing,
    readyForRelease,
    needsRequirements,
    returnedForReassessment,
  ];

  /// Approved, and on its way to the resident or already with them.
  static const approved = [assistanceProcessing, readyForRelease, completed];

  static bool isTulongOnly(String label) => tulongOnly.contains(label);

  /// The main-line step a side state sits on.
  static String stepFor(String status) => switch (status) {
    needsRequirements => initialScreening,
    returnedForReassessment => forApproval,
    _ => status,
  };

  /// The web Tulong pages' `statusStyles`, for the Tulong-only names.
  static StatusStyle? styleFor(String label) => switch (label) {
    initialScreening => const StatusStyle(AppColors.blue50, AppColors.blue700, AppColors.blue500),
    needsRequirements => const StatusStyle(AppColors.amber50, AppColors.amber700, AppColors.amber500),
    assessment => const StatusStyle(AppColors.indigo50, AppColors.indigo700, AppColors.indigo500),
    forApproval => const StatusStyle(AppColors.amber50, AppColors.amber700, AppColors.amber500),
    returnedForReassessment => const StatusStyle(AppColors.orange50, AppColors.orange700, AppColors.orange500),
    assistanceProcessing => const StatusStyle(AppColors.purple50, AppColors.purple700, AppColors.purple500),
    readyForRelease => const StatusStyle(AppColors.teal50, AppColors.teal700, AppColors.teal500),
    _ => null,
  };
}

/// A request's status as the app shows it. Most labels are [AppStatus]'s; a
/// Tulong case may hold one of [TulongStatus]'s own, which
/// [AppStatusX.fromLabel] does not know (and asserts on in debug).
class RequestStatusView {
  final String label;
  const RequestStatusView(this.label);

  StatusStyle get style => TulongStatus.styleFor(label) ?? AppStatusX.fromLabel(label).style;

  /// Every Tulong-only status is still open; the shared ones answer as
  /// [AppStatus] does.
  bool get isDone => !TulongStatus.isTulongOnly(label) && AppStatusX.fromLabel(label).isDone;
}
