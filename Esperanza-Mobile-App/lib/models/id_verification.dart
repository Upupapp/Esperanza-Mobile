import '../services/json_read.dart';

/// The resident's latest valid-ID submission, as GET /citizen/verification/id
/// describes it (esperanza-backend DescribesIdentity::describeIdDocument()).
///
/// [status] is the ID record's own vocabulary (Pending Review, Accepted,
/// Rejected, Superseded), not a request status, so it is never passed to
/// AppStatusX.fromLabel: Accepted and Superseded are not badge labels.
class IdSubmission {
  final String idType;
  final String status;
  final String? remarks;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  const IdSubmission({required this.idType, required this.status, this.remarks, this.submittedAt, this.reviewedAt});

  bool get isPending => status == 'Pending Review';
  bool get isRejected => status == 'Rejected';
  bool get isAccepted => status == 'Accepted';

  static IdSubmission? fromApi(Object? raw) {
    final json = JsonRead.map(raw);
    if (json == null) return null;
    final status = JsonRead.nonEmpty(json['status']);
    if (status == null) return null;
    return IdSubmission(
      idType: JsonRead.nonEmpty(json['id_type']) ?? 'Valid ID',
      status: status,
      remarks: JsonRead.nonEmpty(json['remarks']),
      submittedAt: JsonRead.date(json['submitted_at']),
      reviewedAt: JsonRead.date(json['reviewed_at']),
    );
  }
}

/// GET /citizen/verification/id: the IDs the LGU accepts, whether this
/// account may send one (only while it is Pending Review or Rejected:
/// IdentityRecords::canSubmitId()), and the latest submission.
class IdVerificationView {
  final List<String> idTypes;
  final bool canSubmit;
  final IdSubmission? submission;

  const IdVerificationView({this.idTypes = const [], this.canSubmit = false, this.submission});

  /// Sending is offered exactly where the web portal offers it: the server
  /// allows it, and the last ID is not still waiting for an officer.
  bool get canSendNew => canSubmit && !(submission?.isPending ?? false);

  static IdVerificationView fromApi(Object? raw) {
    final json = JsonRead.map(raw) ?? const <String, dynamic>{};
    return IdVerificationView(
      idTypes: JsonRead.strings(json['id_types']),
      canSubmit: JsonRead.boolean(json['can_submit']) ?? false,
      submission: IdSubmission.fromApi(json['submission']),
    );
  }
}
