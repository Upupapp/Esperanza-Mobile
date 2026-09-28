import 'api_client.dart';
import 'json_read.dart';

/// The citizen's Digital ID as the LGU issues it: GET /citizen/digital-id
/// (esperanza-backend DigitalId::card()). [qr] is a signed payload staff
/// verify with GET /verify-id/{payload}, so the card cannot be forged by
/// editing what is printed on it.
class DigitalIdCard {
  const DigitalIdCard({
    required this.accountNo,
    required this.name,
    required this.barangay,
    required this.status,
    required this.valid,
    required this.qr,
    this.purok,
    this.address,
    this.birthdate,
    this.sex,
    this.civilStatus,
    this.issuedAt,
  });

  final String accountNo;
  final String name;
  final String barangay;
  final String? purok;
  final String? address;
  final DateTime? birthdate;
  final String? sex;
  final String? civilStatus;
  final String status;

  /// True only for a verified account; an unverified card still renders but
  /// says plainly that it is not yet valid.
  final bool valid;
  final DateTime? issuedAt;
  final String qr;

  static DigitalIdCard? fromApi(Map<String, dynamic> json) {
    final accountNo = JsonRead.nonEmpty(json['account_no']);
    final qr = JsonRead.nonEmpty(json['qr']);
    if (accountNo == null || qr == null) return null;
    return DigitalIdCard(
      accountNo: accountNo,
      name: JsonRead.nonEmpty(json['name']) ?? '',
      barangay: JsonRead.nonEmpty(json['barangay']) ?? '',
      purok: JsonRead.nonEmpty(json['purok']),
      address: JsonRead.nonEmpty(json['address']),
      birthdate: JsonRead.date(json['birthdate']),
      sex: JsonRead.nonEmpty(json['sex']),
      civilStatus: JsonRead.nonEmpty(json['civil_status']),
      status: JsonRead.nonEmpty(json['status']) ?? '',
      valid: JsonRead.boolean(json['valid']) ?? false,
      issuedAt: JsonRead.date(json['issued_at']),
      qr: qr,
    );
  }
}

class DigitalIdService {
  DigitalIdService._();

  static Future<DigitalIdCard> fetch() async {
    final res = await api.get('/citizen/digital-id');
    final card = DigitalIdCard.fromApi(res.map);
    if (card == null) {
      throw const ApiException(
        messageEn: 'Your Digital ID could not be loaded. Please try again.',
        messageFil: 'Hindi ma-load ang iyong Digital ID. Pakisubukang muli.',
      );
    }
    return card;
  }
}
