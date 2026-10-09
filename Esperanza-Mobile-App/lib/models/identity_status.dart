import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Whether Esperanza currently recognises the resident's identity
/// (esperanza-backend `CitizenAccount::IDENTITY_STATUSES`, owner ruling
/// 2026-10-09): an automated check of the ID and selfie (Didit), an officer's
/// manual verification, or an officer's revocation.
///
/// Kept apart from the account's `status`, which is the LGU's RESIDENCY
/// decision. It is a closed set of its own, like the ID record's
/// Accepted/Superseded, so it is never passed to AppStatusX.fromLabel: the
/// universal badge vocabulary has no Pending, In Progress, Failed, Requires
/// Review or Revoked, and must not grow them.
enum IdentityStatus { pending, inProgress, verified, failed, requiresReview, revoked }

extension IdentityStatusX on IdentityStatus {
  String get label => switch (this) {
    IdentityStatus.pending => 'Pending',
    IdentityStatus.inProgress => 'In Progress',
    IdentityStatus.verified => 'Verified',
    IdentityStatus.failed => 'Failed',
    IdentityStatus.requiresReview => 'Requires Review',
    IdentityStatus.revoked => 'Revoked',
  };

  /// The server's label to the enum; null for no status yet, or a value this
  /// build does not know (shown as nothing rather than guessed at).
  static IdentityStatus? fromLabel(String? label) {
    for (final s in IdentityStatus.values) {
      if (s.label == label) return s;
    }
    return null;
  }

  /// True while a check is still running on the ID just sent.
  bool get awaitingCheck => this == IdentityStatus.pending || this == IdentityStatus.inProgress;

  Color get background => switch (this) {
    IdentityStatus.pending => AppColors.slate100,
    IdentityStatus.inProgress => AppColors.blue50,
    IdentityStatus.verified => AppColors.emerald50,
    IdentityStatus.failed => AppColors.rose50,
    IdentityStatus.requiresReview => AppColors.amber50,
    IdentityStatus.revoked => AppColors.rose50,
  };

  Color get foreground => switch (this) {
    IdentityStatus.pending => AppColors.slate600,
    IdentityStatus.inProgress => AppColors.blue700,
    IdentityStatus.verified => AppColors.emerald700,
    IdentityStatus.failed => AppColors.rose700,
    IdentityStatus.requiresReview => AppColors.amber700,
    IdentityStatus.revoked => AppColors.rose700,
  };

  IconData get icon => switch (this) {
    IdentityStatus.pending => Icons.schedule_rounded,
    IdentityStatus.inProgress => Icons.manage_search_rounded,
    IdentityStatus.verified => Icons.verified_user_rounded,
    IdentityStatus.failed => Icons.error_outline_rounded,
    IdentityStatus.requiresReview => Icons.person_search_rounded,
    IdentityStatus.revoked => Icons.remove_moderator_rounded,
  };

  /// What it means for the resident, and what to do next.
  String get explanation => switch (this) {
    IdentityStatus.pending =>
      'Your ID and selfie are waiting to be checked. This usually takes a few minutes. No action needed from you.',
    IdentityStatus.inProgress => 'Your ID and selfie are being checked right now.',
    IdentityStatus.verified =>
      'Your identity is confirmed: your selfie matches your valid ID. Your residency is reviewed separately by the LGU.',
    IdentityStatus.failed =>
      'We could not confirm your identity from the photos you sent. Please take new photos of your ID and a new selfie, then send them again.',
    IdentityStatus.requiresReview =>
      'LGU staff will review your ID and selfie themselves. No action needed from you right now.',
    IdentityStatus.revoked =>
      'The LGU has withdrawn the verification of your identity. Send a new valid ID and selfie, or visit your barangay office. Until then, requests are paused.',
  };

  /// Only these two can be fixed by the resident sending new photos.
  bool get residentCanResend => this == IdentityStatus.failed || this == IdentityStatus.revoked;
}

/// Plain words for a Failed check's reason codes (IdentityDecision on the
/// server). Unknown codes say nothing rather than something wrong.
String? identityReasonText(String code) => switch (code) {
  'FACE_MISMATCH' => 'Your selfie did not match the photo on your ID.',
  'LIVENESS_FAILED' => 'Your selfie must be taken live with the camera, not a photo of a photo or a screen.',
  'SELFIE_UNUSABLE' => 'We could not see your face clearly in the selfie.',
  'DOCUMENT_NOT_GENUINE' => 'Photograph the ID card itself, not a screen, a photocopy or a printout.',
  'DOCUMENT_EXPIRED' => 'The ID has expired. Please use a valid, unexpired ID.',
  _ => null,
};
