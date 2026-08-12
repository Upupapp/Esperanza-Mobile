import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/attachment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Real device attachment picker — camera, photo gallery, or document
/// browser, backed by image_picker/file_picker (not a fake button). Per
/// Section 6 of the alignment doc: "the user should actually be able to
/// select a file/image from the device in the development build."
class AttachmentPicker extends StatelessWidget {
  final String documentTypeLabel;
  final List<Attachment> attachments;
  final ValueChanged<Attachment> onAdd;
  final ValueChanged<String> onRemove;

  const AttachmentPicker({
    super.key,
    required this.documentTypeLabel,
    required this.attachments,
    required this.onAdd,
    required this.onRemove,
  });

  Future<void> _pickFromCamera(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file == null) return;
    await _addImage(file);
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    await _addImage(file);
  }

  Future<void> _addImage(XFile file) async {
    final bytes = await file.length();
    onAdd(Attachment(
      id: 'att-${DateTime.now().microsecondsSinceEpoch}',
      fileName: file.name,
      category: AttachmentCategoryX.fromExtension(file.name.split('.').last),
      sizeBytes: bytes,
      localPath: file.path,
      addedAt: DateTime.now(),
      documentTypeLabel: documentTypeLabel,
    ));
  }

  Future<void> _pickDocument(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    if (f.path == null) return;
    onAdd(Attachment(
      id: 'att-${DateTime.now().microsecondsSinceEpoch}',
      fileName: f.name,
      category: AttachmentCategoryX.fromExtension(f.extension ?? ''),
      sizeBytes: f.size,
      localPath: f.path!,
      addedAt: DateTime.now(),
      documentTypeLabel: documentTypeLabel,
    ));
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetOption(ctx, Icons.photo_camera_outlined, 'Take a photo', () {
                Navigator.pop(ctx);
                _pickFromCamera(context);
              }),
              _sheetOption(ctx, Icons.image_outlined, 'Choose from gallery', () {
                Navigator.pop(ctx);
                _pickFromGallery(context);
              }),
              _sheetOption(ctx, Icons.description_outlined, 'Choose a document (PDF/DOCX)', () {
                Navigator.pop(ctx);
                _pickDocument(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brand600),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in attachments) _AttachmentTile(attachment: a, onRemove: () => onRemove(a.id)),
        if (attachments.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () => _showPickerSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brand200, style: BorderStyle.solid),
              color: AppColors.brand50,
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: AppColors.brand500, size: 22),
                SizedBox(height: 6),
                Text('Add photo or document', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;

  const _AttachmentTile({required this.attachment, required this.onRemove});

  ({Color bg, Color fg, IconData icon}) get _style => switch (attachment.category) {
        AttachmentCategory.image => (bg: AppColors.brand50, fg: AppColors.brand500, icon: Icons.image_outlined),
        AttachmentCategory.pdf => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.picture_as_pdf_outlined),
        AttachmentCategory.docx => (bg: AppColors.blue50, fg: AppColors.blue700, icon: Icons.description_outlined),
        AttachmentCategory.video => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.videocam_outlined),
        AttachmentCategory.other => (bg: AppColors.slate100, fg: AppColors.slate500, icon: Icons.insert_drive_file_outlined),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final isImage = attachment.category == AttachmentCategory.image && File(attachment.localPath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isImage
                ? Image.file(File(attachment.localPath), width: 40, height: 40, fit: BoxFit.cover)
                : Container(
                    width: 40,
                    height: 40,
                    color: s.bg,
                    child: Icon(s.icon, size: 18, color: s.fg),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attachment.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700)),
                const SizedBox(height: 2),
                Text('${attachment.category.shortLabel} · ${attachment.readableSize}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate400),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
