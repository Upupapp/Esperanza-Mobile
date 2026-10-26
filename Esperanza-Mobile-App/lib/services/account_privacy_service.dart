import 'api_client.dart';
import 'json_read.dart';

/// A request a citizen makes about the personal data the Municipality holds
/// on them, under the Data Privacy Act (RA 10173), as
/// `GET/POST /citizen/data-requests` returns it
/// (esperanza-backend CitizenPortalController::dataRequestRow()).
class DataRequest {
  const DataRequest({
    required this.ref,
    required this.kind,
    required this.detail,
    required this.status,
    this.resolution,
    this.submittedAt,
    this.resolvedAt,
    this.reason,
    this.requestedName,
  });

  final String ref;
  final String kind;
  final String detail;

  /// One of the canonical status labels (`Submitted` when filed).
  final String status;
  final String? resolution;
  final DateTime? submittedAt;
  final DateTime? resolvedAt;

  /// A change of name: why ([NameChangeReason.key]) and the name asked for.
  final String? reason;
  final String? requestedName;

  /// A change of name still waiting for the barangay: then no second.
  bool get openNameChange => kind == AccountPrivacyService.nameChangeKind && const {'Submitted', 'Under Review'}.contains(status);

  static DataRequest? fromJson(Map<String, dynamic> row) {
    final ref = JsonRead.nonEmpty(row['ref']);
    final kind = JsonRead.nonEmpty(row['kind']);
    if (ref == null || kind == null) return null;
    return DataRequest(
      ref: ref,
      kind: kind,
      detail: JsonRead.string(row['detail']) ?? '',
      status: JsonRead.nonEmpty(row['status']) ?? 'Submitted',
      resolution: JsonRead.nonEmpty(row['resolution']),
      submittedAt: JsonRead.date(row['submitted_at']),
      resolvedAt: JsonRead.date(row['resolved_at']),
      reason: JsonRead.nonEmpty(row['reason']),
      requestedName: _name(JsonRead.map(row['requested'])),
    );
  }
}

String? _name(Map<String, dynamic>? n) {
  if (n == null) return null;
  final parts = ['first_name', 'middle_name', 'last_name', 'suffix'].map((k) => JsonRead.nonEmpty(n[k])).nonNulls;
  return parts.isEmpty ? null : parts.join(' ');
}

/// Why a verified resident's name changes, and the proof the barangay checks
/// (the website's NAME_REASONS; esperanza-backend
/// DataSubjectRequest::NAME_CHANGE_REASONS).
class NameChangeReason {
  const NameChangeReason(this.key, this.label, this.proof);

  final String key;
  final String label;
  final String proof;
}

/// One kind of data request, in the words a resident would use.
class DataRequestKind {
  const DataRequestKind(this.key, this.title, this.description);

  /// Sent to the server as `kind`.
  final String key;
  final String title;
  final String description;
}

class AccountPrivacyService {
  AccountPrivacyService._();

  /// The backend's own list (CitizenPortalController::DATA_REQUEST_KINDS),
  /// validated with `Rule::in` -- any other key is a 422.
  static const kinds = [
    DataRequestKind('access', 'See my data', 'Ask what personal information the Municipality holds about you.'),
    DataRequestKind('correction', 'Correct my data', 'Ask for something the Municipality holds about you to be fixed.'),
    DataRequestKind(
      'erasure',
      'Delete my data',
      'Ask for your information to be deleted or blocked, where the law allows.',
    ),
    DataRequestKind(
      'portability',
      'Get a copy',
      'Ask for a copy of your information that you can keep or take elsewhere.',
    ),
  ];

  static String kindTitle(String key) => key == nameChangeKind
      ? 'Change my name'
      : kinds.firstWhere((k) => k.key == key, orElse: () => DataRequestKind(key, key, '')).title;

  /// A verified resident's change of name, filed from Edit Profile.
  static const nameChangeKind = 'name_change';

  static const nameChangeReasons = [
    NameChangeReason('marriage', 'Marriage (taking my spouse’s surname)', 'PSA marriage certificate'),
    NameChangeReason(
      'annulment',
      'Annulment or nullity of marriage (back to my former surname)',
      'PSA marriage certificate with the annotation, or the court decision',
    ),
    NameChangeReason('court_order', 'Court order (a legal change of name)', 'Certified copy of the court order or decision'),
    NameChangeReason(
      'clerical',
      'My name is misspelled (typo)',
      'PSA birth certificate, or a valid ID showing the right spelling',
    ),
  ];

  /// POST /citizen/data-requests, kind name_change (multipart): the reason,
  /// the new name and the proof. A second while one waits is a 409
  /// NAME_CHANGE_PENDING.
  static Future<DataRequest> fileNameChange({
    required String reason,
    required String firstName,
    String middleName = '',
    required String lastName,
    String note = '',
    required List<int> proofBytes,
    required String proofName,
  }) async {
    final res = await api.postMultipart(
      '/citizen/data-requests',
      fields: {
        'kind': nameChangeKind,
        'reason': reason,
        'first_name': firstName.trim(),
        if (middleName.trim().isNotEmpty) 'middle_name': middleName.trim(),
        'last_name': lastName.trim(),
        if (note.trim().isNotEmpty) 'detail': note.trim(),
      },
      bytesFiles: {'proof': (bytes: proofBytes, filename: proofName)},
    );
    final row = DataRequest.fromJson(res.map);
    if (row == null) {
      throw const ApiException(
        messageEn: 'Your request may not have been received. Please check My data requests before trying again.',
        messageFil:
            'Maaaring hindi natanggap ang iyong kahilingan. Tingnan muna ang My data requests bago subukang muli.',
      );
    }
    return row;
  }

  /// The backend's cap on `detail` (`max:2000`).
  static const detailMaxLength = 2000;

  static Future<List<DataRequest>> dataRequests() async =>
      JsonRead.rows(await api.getAllPages('/citizen/data-requests'), DataRequest.fromJson);

  static Future<DataRequest> fileDataRequest({required String kind, required String detail}) async {
    final res = await api.post('/citizen/data-requests', body: {'kind': kind, 'detail': detail.trim()});
    final row = DataRequest.fromJson(res.map);
    if (row == null) {
      throw const ApiException(
        messageEn: 'Your request may not have been received. Please check My data requests before trying again.',
        messageFil:
            'Maaaring hindi natanggap ang iyong kahilingan. Tingnan muna ang My data requests bago subukang muli.',
      );
    }
    return row;
  }

  /// PUT /citizen/password. The server signs out every other session and
  /// keeps this one.
  static Future<void> changePassword({required String current, required String password}) async {
    await api.put(
      '/citizen/password',
      body: {'current_password': current, 'password': password, 'password_confirmation': password},
    );
  }

  /// POST /auth/citizen/password/forgot. Always accepted: the server never
  /// says whether [identifier] matched an account, and sends a code only to
  /// a verified account's proven contact (AuthController::forgotPassword).
  static Future<void> requestPasswordReset(String identifier) async {
    await api.post('/auth/citizen/password/forgot', body: {'identifier': identifier.trim()});
  }

  /// POST /auth/citizen/password/reset. Every session of the account ends,
  /// so the resident signs in again with the new password.
  static Future<void> resetPassword({required String identifier, required String code, required String password}) async {
    await api.post(
      '/auth/citizen/password/reset',
      body: {
        'identifier': identifier.trim(),
        'code': code.trim(),
        'password': password,
        'password_confirmation': password,
      },
    );
  }
}
