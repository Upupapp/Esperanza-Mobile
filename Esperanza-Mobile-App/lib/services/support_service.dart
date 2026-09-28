import 'api_client.dart';
import 'json_read.dart';

/// Report a Problem, against POST /citizen/support/tickets
/// (esperanza-backend CitizenPortalController::storeSupportTicket()).
class SupportService {
  SupportService._();

  /// The backend's own list (SupportTicket::CATEGORIES), validated with
  /// `Rule::in` -- any other string is a 422, so the form offers exactly these.
  static const categories = ['Account & Login', 'Dokyu', 'Tulong', 'Technical Issue', 'App Problem', 'Other'];

  /// Files a ticket and returns its reference (`TKT-YYYY-####`). The
  /// attachment, when given, is sent as multipart field `attachment`.
  static Future<String> fileTicket({
    required String category,
    required String subject,
    required String body,
    String? attachmentPath,
  }) async {
    final fields = {'category': category, 'subject': subject.trim(), 'body': body.trim()};
    final res = attachmentPath != null
        ? await api.postMultipart('/citizen/support/tickets', filePath: attachmentPath, fileField: 'attachment', fields: fields)
        : await api.post('/citizen/support/tickets', body: fields);
    final ref = JsonRead.nonEmpty(res.map['ref']);
    if (ref == null) {
      throw const ApiException(
        messageEn: 'Your report may not have been received. Please try again.',
        messageFil: 'Maaaring hindi natanggap ang iyong ulat. Pakisubukang muli.',
      );
    }
    return ref;
  }
}
