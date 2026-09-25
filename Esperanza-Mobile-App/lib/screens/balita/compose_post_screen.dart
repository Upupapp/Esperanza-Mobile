import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/balita_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/cross_platform_image.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_section.dart';

/// Same category vocabulary the Web Admin's own "New Balita" composer
/// offers for an announcement (communications.blade.php) -- there is no
/// separate citizen-facing category list anywhere, and reusing this one
/// keeps filtering consistent between admin- and citizen-authored posts.
const _categories = ['Community', 'Health', 'Public Service', 'Advisory', 'Livelihood', 'Governance'];

/// POST /community-posts -- a real citizen-posting capability (production-
/// readiness programme, 2026-09-25, confirmed against the backend
/// directly) that neither this app nor the Web Admin's own citizen Balita
/// page used before this. Pre-moderated: the post this creates is visible
/// only to its own author until an information officer approves it -- the
/// feed shows it with a "Pending review" badge in the meantime (see
/// PostCard), never silently as if it were already public.
class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({super.key});

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  final _body = TextEditingController();
  String _category = _categories.first;
  XFile? _image;
  Uint8List? _imageBytes;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await pickImageProtected(context, source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _image = file;
      _imageBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (_body.text.trim().isEmpty) {
      setState(() => _error = 'Please write something to post.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<BalitaService>().createPost(
        body: _body.text.trim(),
        category: _category,
        imageFilePath: _image?.path,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // CAPABILITY_DENIED (403) reads exactly as intended without any
        // special-casing -- ApiException.message() already carries the
        // server's own bilingual copy for it ("Hindi pinapayagan ang
        // account na ito na mag-post sa komunidad." / "This account may
        // not post to the community feed.").
        _error = e.message();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.brand600),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "Your post is reviewed by Esperanza LGU before it appears to other residents. You'll see it "
                      'right away marked "Pending review" -- only you can see it until then.',
                      style: TextStyle(fontSize: 12, color: AppColors.brand700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FormSection(
              title: 'Post Details',
              children: [
                AppSelectField<String>(
                  label: 'Category',
                  value: _category,
                  options: _categories,
                  labelBuilder: (c) => c,
                  onChanged: (v) => setState(() => _category = v!),
                ),
                AppTextField(
                  label: 'What do you want to share?',
                  controller: _body,
                  hintText: 'News, an update, or something happening in your barangay...',
                  maxLines: 5,
                ),
                _ImageField(
                  bytes: _imageBytes,
                  fileName: _image?.name,
                  onPick: _pickImage,
                  onRemove: () => setState(() {
                    _image = null;
                    _imageBytes = null;
                  }),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Post',
              fullWidth: true,
              size: AppButtonSize.lg,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageField extends StatelessWidget {
  final Uint8List? bytes;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImageField({required this.bytes, required this.fileName, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo (optional)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (bytes != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: pickedFileImageProvider(bytes: bytes)!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    fileName ?? 'Photo attached',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.slate700),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove photo',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate400),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
            label: const Text('Attach a photo'),
          ),
      ],
    );
  }
}
