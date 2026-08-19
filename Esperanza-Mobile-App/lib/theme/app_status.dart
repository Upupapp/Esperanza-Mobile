import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The Esperanza platform's universal status system — the exact 14 status
/// names and color mappings from the Web Admin's
/// `resources/views/components/ui/badge.blade.php`. These names are shared
/// verbatim across Web Admin and Mobile; never invent new status labels
/// (see CLAUDE.md's "Universal status system" and
/// ESPERANZA_MOBILE_WEB_ALIGNMENT.md Section 4).
enum AppStatus {
  draft,
  submitted,
  pendingReview,
  underVerification,
  assigned,
  processing,
  waitingRequirements,
  approved,
  rejected,
  readyForRelease,
  released,
  completed,
  cancelled,
  archived,
}

class StatusStyle {
  final Color background;
  final Color foreground;
  final Color dot;
  const StatusStyle(this.background, this.foreground, this.dot);
}

extension AppStatusX on AppStatus {
  /// The exact label shown to users — must match the Web Admin string
  /// exactly since these appear side-by-side across both apps.
  String get label => switch (this) {
    AppStatus.draft => 'Draft',
    AppStatus.submitted => 'Submitted',
    AppStatus.pendingReview => 'Pending Review',
    AppStatus.underVerification => 'Under Verification',
    AppStatus.assigned => 'Assigned',
    AppStatus.processing => 'Processing',
    AppStatus.waitingRequirements => 'Waiting Requirements',
    AppStatus.approved => 'Approved',
    AppStatus.rejected => 'Rejected',
    AppStatus.readyForRelease => 'Ready for Release',
    AppStatus.released => 'Released',
    AppStatus.completed => 'Completed',
    AppStatus.cancelled => 'Cancelled',
    AppStatus.archived => 'Archived',
  };

  StatusStyle get style => switch (this) {
    AppStatus.draft => const StatusStyle(AppColors.slate100, AppColors.slate600, AppColors.slate400),
    AppStatus.submitted => const StatusStyle(AppColors.blue50, AppColors.blue700, AppColors.blue500),
    AppStatus.pendingReview => const StatusStyle(AppColors.amber50, AppColors.amber700, AppColors.amber500),
    AppStatus.underVerification => const StatusStyle(AppColors.indigo50, AppColors.indigo700, AppColors.indigo500),
    AppStatus.assigned => const StatusStyle(AppColors.purple50, AppColors.purple700, AppColors.purple500),
    AppStatus.processing => const StatusStyle(AppColors.brand50, AppColors.brand700, AppColors.brand500),
    AppStatus.waitingRequirements => const StatusStyle(AppColors.orange50, AppColors.orange700, AppColors.orange500),
    AppStatus.approved => const StatusStyle(AppColors.emerald50, AppColors.emerald700, AppColors.emerald500),
    AppStatus.rejected => const StatusStyle(AppColors.rose50, AppColors.rose700, AppColors.rose500),
    AppStatus.readyForRelease => const StatusStyle(AppColors.teal50, AppColors.teal700, AppColors.teal500),
    AppStatus.released => const StatusStyle(AppColors.cyan50, AppColors.cyan700, AppColors.cyan500),
    AppStatus.completed => const StatusStyle(AppColors.green50, AppColors.green700, AppColors.green500),
    AppStatus.cancelled => const StatusStyle(AppColors.slate100, AppColors.slate500, AppColors.slate400),
    AppStatus.archived => const StatusStyle(AppColors.slate100, AppColors.slate400, AppColors.slate300),
  };

  /// Whether this status represents a finished/terminal state — mirrors the
  /// `doneStatuses` arrays used in document-requests.blade.php /
  /// assistance-requests.blade.php to split "Active" vs "Done" tabs.
  bool get isDone =>
      this == AppStatus.completed ||
      this == AppStatus.released ||
      this == AppStatus.rejected ||
      this == AppStatus.cancelled ||
      this == AppStatus.archived;

  static AppStatus fromLabel(String label) {
    return AppStatus.values.firstWhere((s) => s.label == label, orElse: () => AppStatus.draft);
  }
}
