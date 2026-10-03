import '../services/json_read.dart';

/// The profile photo as the LGU holds it (`photo` in GET /citizen/profile).
///
/// The owner ruled the photo an identification record (backlog B9): a new
/// one waits for an officer, the Digital ID keeps the approved one until then,
/// and a verified resident may change it once in [changeMonths] months,
/// counted from the last approval. The server enforces that; this only shows it.
class ProfilePhotoView {
  const ProfilePhotoView({
    this.approvedUrl,
    this.latestStatus,
    this.latestRemarks,
    this.canChange = true,
    this.nextChangeAt,
    this.changeMonths = 6,
  });

  /// The approved photo: what the Digital ID shows. Null until one is approved.
  final String? approvedUrl;

  /// The latest submission's status: Pending Review, Approved or Rejected.
  final String? latestStatus;

  /// The officer's reason, when the latest submission was rejected.
  final String? latestRemarks;

  final bool canChange;
  final DateTime? nextChangeAt;
  final int changeMonths;

  bool get isPending => latestStatus == 'Pending Review';
  bool get isRejected => latestStatus == 'Rejected';

  static ProfilePhotoView? fromApi(Object? raw) {
    final json = JsonRead.map(raw);
    if (json == null) return null;
    final latest = JsonRead.map(json['latest']);
    return ProfilePhotoView(
      approvedUrl: JsonRead.nonEmpty(json['url']),
      latestStatus: latest == null ? null : JsonRead.nonEmpty(latest['status']),
      latestRemarks: latest == null ? null : JsonRead.nonEmpty(latest['remarks']),
      canChange: JsonRead.boolean(json['can_change']) ?? true,
      nextChangeAt: JsonRead.date(json['next_change_at']),
      changeMonths: JsonRead.integer(json['change_months']) ?? 6,
    );
  }
}
