enum AttachmentCategory { image, pdf, docx, video, other }

extension AttachmentCategoryX on AttachmentCategory {
  /// Matches the Web Admin's file-picker category tags (IMG/PDF/DOCX/VID) —
  /// see resources/views/components/ui/file-picker.blade.php.
  String get shortLabel => switch (this) {
        AttachmentCategory.image => 'IMG',
        AttachmentCategory.pdf => 'PDF',
        AttachmentCategory.docx => 'DOCX',
        AttachmentCategory.video => 'VID',
        AttachmentCategory.other => 'FILE',
      };

  static AttachmentCategory fromExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    if (['jpg', 'jpeg', 'png', 'heic', 'webp'].contains(e)) return AttachmentCategory.image;
    if (e == 'pdf') return AttachmentCategory.pdf;
    if (['doc', 'docx'].contains(e)) return AttachmentCategory.docx;
    if (['mp4', 'mov'].contains(e)) return AttachmentCategory.video;
    return AttachmentCategory.other;
  }
}

/// A file/photo attached to a request. `localPath` points at the file the
/// user actually picked on-device (real image_picker/file_picker output —
/// not a placeholder). This shape is intentionally backend-ready: once a
/// real API exists, `localPath` is replaced by an uploaded `remoteUrl` and
/// nothing else about this model needs to change.
class Attachment {
  final String id;
  final String fileName;
  final AttachmentCategory category;
  final int sizeBytes;
  final String localPath;
  final DateTime addedAt;
  final String documentTypeLabel;

  Attachment({
    required this.id,
    required this.fileName,
    required this.category,
    required this.sizeBytes,
    required this.localPath,
    required this.addedAt,
    required this.documentTypeLabel,
  });

  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'category': category.name,
        'sizeBytes': sizeBytes,
        'localPath': localPath,
        'addedAt': addedAt.toIso8601String(),
        'documentTypeLabel': documentTypeLabel,
      };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'],
        fileName: json['fileName'],
        category: AttachmentCategory.values.firstWhere((c) => c.name == json['category']),
        sizeBytes: json['sizeBytes'],
        localPath: json['localPath'],
        addedAt: DateTime.parse(json['addedAt']),
        documentTypeLabel: json['documentTypeLabel'],
      );
}
