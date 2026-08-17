import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/attachment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/cross_platform_image.dart';

/// Real device attachment picker — camera, photo gallery, or document
/// browser, backed by image_picker/file_picker (not a fake button). Per
/// Section 6 of the alignment doc: "the user should actually be able to
/// select a file/image from the device in the development build."
///
/// Reused across Dokyu, Tulong, and any future service-request wizard step
/// that needs attachments — all platform-specific file handling lives here
/// and in `lib/utils/cross_platform_image.dart`, not in the screens that
/// use this widget.
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

  /// Reads the picked file's bytes up front (works on every platform,
  /// including Flutter Web where `XFile.path`/`PlatformFile.path` is a
  /// blob: URL or absent) so preview never depends on `dart:io`.
  Future<void> _addImage(XFile file, {String? replaceId}) async {
    final bytes = await file.readAsBytes();
    _commit(
      Attachment(
        id: 'att-${DateTime.now().microsecondsSinceEpoch}',
        fileName: file.name,
        category: AttachmentCategoryX.fromExtension(file.name.split('.').last),
        sizeBytes: bytes.length,
        localPath: file.path,
        bytes: bytes,
        addedAt: DateTime.now(),
        documentTypeLabel: documentTypeLabel,
      ),
      replaceId: replaceId,
    );
  }

  Future<void> _pickFromCamera(BuildContext context, {String? replaceId}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file == null) return; // user cancelled — just return to the form
    await _addImage(file, replaceId: replaceId);
  }

  Future<void> _pickFromGallery(BuildContext context, {String? replaceId}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    await _addImage(file, replaceId: replaceId);
  }

  Future<void> _pickDocument(BuildContext context, {String? replaceId}) async {
    // withData: true is required for this to work at all on Flutter Web —
    // web never provides PlatformFile.path, only .bytes.
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    if (f.bytes == null) return;
    _commit(
      Attachment(
        id: 'att-${DateTime.now().microsecondsSinceEpoch}',
        fileName: f.name,
        category: AttachmentCategoryX.fromExtension(f.extension ?? ''),
        sizeBytes: f.size,
        localPath: f.path,
        bytes: f.bytes,
        addedAt: DateTime.now(),
        documentTypeLabel: documentTypeLabel,
      ),
      replaceId: replaceId,
    );
  }

  void _commit(Attachment attachment, {String? replaceId}) {
    if (replaceId != null) onRemove(replaceId);
    onAdd(attachment);
  }

  void _showPickerSheet(BuildContext context, {String? replaceId}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          // Material (not a plain Container+BoxDecoration) so the ListTiles
          // below paint their ink splashes correctly against this
          // background instead of being hidden behind it.
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetOption(ctx, Icons.photo_camera_outlined, 'Take a photo', () {
                    Navigator.pop(ctx);
                    _pickFromCamera(context, replaceId: replaceId);
                  }),
                  _sheetOption(ctx, Icons.image_outlined, 'Choose from gallery', () {
                    Navigator.pop(ctx);
                    _pickFromGallery(context, replaceId: replaceId);
                  }),
                  _sheetOption(ctx, Icons.description_outlined, 'Choose a document (PDF/DOCX)', () {
                    Navigator.pop(ctx);
                    _pickDocument(context, replaceId: replaceId);
                  }),
                ],
              ),
            ),
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
        for (final a in attachments)
          _AttachmentTile(
            attachment: a,
            onRemove: () => onRemove(a.id),
            onReplace: () => _showPickerSheet(context, replaceId: a.id),
          ),
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

class _AttachmentTile extends StatefulWidget {
  final Attachment attachment;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const _AttachmentTile({required this.attachment, required this.onRemove, required this.onReplace});

  @override
  State<_AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends State<_AttachmentTile> {
  bool _previewFailed = false;

  ({Color bg, Color fg, IconData icon}) get _style => switch (widget.attachment.category) {
        AttachmentCategory.image => (bg: AppColors.brand50, fg: AppColors.brand500, icon: Icons.image_outlined),
        AttachmentCategory.pdf => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.picture_as_pdf_outlined),
        AttachmentCategory.docx => (bg: AppColors.blue50, fg: AppColors.blue700, icon: Icons.description_outlined),
        AttachmentCategory.video => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.videocam_outlined),
        AttachmentCategory.other => (bg: AppColors.slate100, fg: AppColors.slate500, icon: Icons.insert_drive_file_outlined),
      };

  @override
  void didUpdateWidget(covariant _AttachmentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.id != widget.attachment.id) _previewFailed = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final provider = widget.attachment.category == AttachmentCategory.image && !_previewFailed
        ? pickedFileImageProvider(bytes: widget.attachment.bytes, path: widget.attachment.localPath)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: provider != null
                    ? Image(
                        image: provider,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        // Never let a decode failure take down the whole
                        // form — fall back to the category icon and show
                        // an inline message instead.
                        errorBuilder: (context, error, stackTrace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _previewFailed = true);
                          });
                          return Container(width: 48, height: 48, color: s.bg, child: Icon(s.icon, size: 20, color: s.fg));
                        },
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: s.bg,
                        child: Icon(s.icon, size: 20, color: s.fg),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.attachment.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700)),
                    const SizedBox(height: 2),
                    Text('${widget.attachment.category.shortLabel} · ${widget.attachment.readableSize}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              TextButton(
                onPressed: widget.onReplace,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32)),
                child: const Text('Replace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand600)),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate400),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (_previewFailed) ...[
            const SizedBox(height: 6),
            const Text('Unable to load this image. Please try another file.', style: TextStyle(fontSize: 11, color: AppColors.rose600)),
          ],
        ],
      ),
    );
  }
}
