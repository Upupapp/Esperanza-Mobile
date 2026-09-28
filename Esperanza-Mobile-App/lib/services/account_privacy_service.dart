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
  });

  final String ref;
  final String kind;
  final String detail;

  /// One of the canonical status labels (`Submitted` when filed).
  final String status;
  final String? resolution;
  final DateTime? submittedAt;
  final DateTime? resolvedAt;

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
    );
  }
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

  static String kindTitle(String key) =>
      kinds.firstWhere((k) => k.key == key, orElse: () => DataRequestKind(key, key, '')).title;

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
}
