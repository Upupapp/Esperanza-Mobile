import '../models/resident_certificate.dart';
import 'api_client.dart';
import 'json_read.dart';

/// The resident's certificates (owner, 2026-11-05, sheet item 9), the same
/// route the website's Tulong page reads (welfare-citizen.js):
///
///   GET /citizen/certificates   every certificate naming them, newest first
class CertificatesService {
  CertificatesService._();

  static Future<List<ResidentCertificate>> mine() async {
    final rows = await api.getAllPages('/citizen/certificates');
    return JsonRead.rows(rows, ResidentCertificate.fromApi);
  }
}
