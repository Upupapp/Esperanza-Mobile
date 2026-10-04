import '../services/json_read.dart';

/// One file the resident attached to a request (GET /citizen/uploads), from
/// the app or the website. [current] is false for a file a later upload
/// replaced; [url] is set only once the server's malware scan has cleared it.
class UploadedDocument {
  final String ref;
  final String type;
  final String? service;
  final String requirement;
  final bool current;
  final String fileName;
  final int bytes;
  final String scanStatus;
  final String? url;
  final DateTime? uploadedAt;

  const UploadedDocument({
    required this.ref,
    required this.type,
    required this.service,
    required this.requirement,
    required this.current,
    required this.fileName,
    required this.bytes,
    required this.scanStatus,
    required this.url,
    required this.uploadedAt,
  });

  bool get isDokyu => type == 'dokyu';

  String get extension => fileName.contains('.') ? fileName.split('.').last : '';

  /// Why the file cannot be opened, when it cannot.
  String? get unavailableReason => url != null
      ? null
      : switch (scanStatus) {
          'pending' => 'This file is still being checked for viruses. Try again in a minute.',
          'infected' => 'This file failed the virus check and cannot be opened.',
          'error' => 'The virus check could not run on this file yet, so it cannot be opened.',
          _ => 'This file cannot be opened right now.',
        };

  static UploadedDocument? fromJson(Map<String, dynamic> json) {
    final ref = JsonRead.nonEmpty(json['ref']);
    final file = JsonRead.map(json['file']);
    if (ref == null || file == null) return null;
    final name = JsonRead.nonEmpty(file['name']);
    if (name == null) return null;
    return UploadedDocument(
      ref: ref,
      type: JsonRead.nonEmpty(json['type']) ?? 'dokyu',
      service: JsonRead.nonEmpty(json['service']),
      requirement: JsonRead.nonEmpty(json['requirement']) ?? name,
      current: JsonRead.boolean(json['current']) ?? true,
      fileName: name,
      bytes: JsonRead.integer(file['bytes']) ?? 0,
      scanStatus: JsonRead.nonEmpty(file['scan_status']) ?? 'pending',
      url: JsonRead.nonEmpty(file['url']),
      uploadedAt: JsonRead.date(file['uploaded_at'])?.toLocal(),
    );
  }
}
