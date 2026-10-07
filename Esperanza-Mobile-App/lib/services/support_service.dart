import 'api_client.dart';
import 'json_read.dart';

/// One of the resident's support tickets, as GET /citizen/support/tickets
/// lists it (CitizenPortalController::ticketRow()), with the office's reply
/// once it has answered.
class SupportTicket {
  final String ref;
  final String category;
  final String subject;
  final String body;
  final String status;
  final String? response;
  final DateTime? respondedAt;
  final DateTime? createdAt;
  final String? attachmentName;

  const SupportTicket({
    required this.ref,
    required this.category,
    required this.subject,
    required this.body,
    required this.status,
    this.response,
    this.respondedAt,
    this.createdAt,
    this.attachmentName,
  });

  static SupportTicket? fromJson(Map<String, dynamic> row) {
    final ref = JsonRead.nonEmpty(row['ref']);
    if (ref == null) return null;
    return SupportTicket(
      ref: ref,
      category: JsonRead.nonEmpty(row['category']) ?? 'Other',
      subject: JsonRead.nonEmpty(row['subject']) ?? '(no subject)',
      body: JsonRead.string(row['body']) ?? '',
      status: JsonRead.nonEmpty(row['status']) ?? 'Submitted',
      response: JsonRead.nonEmpty(row['response']),
      respondedAt: JsonRead.date(row['responded_at']),
      createdAt: JsonRead.date(row['created_at']),
      attachmentName: JsonRead.nonEmpty(JsonRead.map(row['attachment'])?['name']),
    );
  }
}

/// Report a Problem, against POST /citizen/support/tickets
/// (esperanza-backend CitizenPortalController::storeSupportTicket()), and the
/// resident's tickets so far, as the web portal's Help > Support lists them.
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

  /// GET /citizen/support/tickets, newest first.
  static Future<List<SupportTicket>> myTickets() async {
    final rows = await api.getAllPages('/citizen/support/tickets', query: {'per_page': 50}, maxPages: 4);
    return JsonRead.rows(rows, SupportTicket.fromJson);
  }
}
