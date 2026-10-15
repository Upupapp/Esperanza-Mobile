import 'api_client.dart';
import 'json_read.dart';

/// One message in a ticket's conversation: the resident's, or the office's
/// (staff appear as their office, never by name).
class TicketMessage {
  const TicketMessage({required this.fromStaff, required this.name, required this.body, this.at});

  final bool fromStaff;
  final String name;
  final String body;
  final DateTime? at;
}

/// One of the resident's support tickets, as GET /citizen/support/tickets
/// lists it (CitizenPortalController::ticketRow()), with the office's reply
/// once it has answered; GET /citizen/support/tickets/{ref} adds the whole
/// conversation ([replies]).
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
  final String? office;
  final int messagesCount;

  /// The conversation after the first message, oldest first; empty on a list
  /// row (the detail carries it).
  final List<TicketMessage> replies;

  /// Closed by the office: it takes no more replies.
  bool get closed => status == 'Cancelled';

  /// The whole conversation as the website shows it: the ticket itself is
  /// the resident's first message; a ticket answered before conversations
  /// existed has its one reply in [response].
  List<TicketMessage> get conversation => [
    TicketMessage(fromStaff: false, name: 'You', body: body, at: createdAt),
    ...replies,
    if (response != null && !replies.any((m) => m.fromStaff))
      TicketMessage(fromStaff: true, name: 'LGU Esperanza', body: response!, at: respondedAt),
  ];

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
    this.office,
    this.messagesCount = 0,
    this.replies = const [],
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
      office: JsonRead.nonEmpty(row['office']),
      messagesCount: JsonRead.integer(row['messages_count']) ?? 0,
      replies: JsonRead.rows(row['messages'], (m) {
        final body = JsonRead.nonEmpty(m['body']);
        if (body == null) return null;
        final staff = JsonRead.nonEmpty(m['from']) == 'staff';
        return TicketMessage(
          fromStaff: staff,
          name: staff ? (JsonRead.nonEmpty(m['name']) ?? 'LGU Esperanza') : 'You',
          body: body,
          at: JsonRead.date(m['at']),
        );
      }),
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

  /// GET /citizen/support/tickets/{ref}: the ticket with its conversation.
  static Future<SupportTicket> ticket(String ref) async {
    final res = await api.get('/citizen/support/tickets/${ApiClient.segment(ref)}');
    return SupportTicket.fromJson(res.map) ?? (throw const ApiException(messageEn: 'The conversation could not be read.', messageFil: 'Hindi mabasa ang usapan.'));
  }

  /// POST /citizen/support/tickets/{ref}/reply: answers the office. A ticket
  /// the office closed refuses with 409 TICKET_CLOSED.
  static Future<SupportTicket> reply(String ref, String message) async {
    final res = await api.post('/citizen/support/tickets/${ApiClient.segment(ref)}/reply', body: {'message': message.trim()});
    return SupportTicket.fromJson(res.map) ?? (throw const ApiException(messageEn: 'Your reply was sent, but the answer could not be read. Pull down to refresh.', messageFil: 'Naipadala ang tugon, ngunit hindi mabasa ang sagot. Hilahin pababa para i-refresh.'));
  }

  /// GET /citizen/support/tickets, newest first.
  static Future<List<SupportTicket>> myTickets() async {
    final rows = await api.getAllPages('/citizen/support/tickets', query: {'per_page': 50}, maxPages: 4);
    return JsonRead.rows(rows, SupportTicket.fromJson);
  }
}
