import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/balita_media.dart';
import '../../services/api_client.dart';
import '../../services/balita_service.dart';
import '../../services/balita_uploads.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/cross_platform_image.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_section.dart';
import '../../theme/app_typography.dart';

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

  /// The photos and videos being attached, uploading while the resident
  /// types (2026-10-18); the post names them when it is sent.
  final List<BalitaUpload> _uploads = [];
  bool _submitting = false;
  bool _posted = false;
  String? _error;

  bool get _uploading => _uploads.any((u) => u.busy);
  bool get _anyFailed => _uploads.any((u) => u.status == BalitaUploadStatus.failed);

  /// Kept here: a widget's context must not be read once it is disposed.
  late BalitaService _balita;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _balita = context.read<BalitaService>();
  }

  @override
  void dispose() {
    final balita = _balita;
    for (final u in _uploads) {
      u.cancel();
      u.removeListener(_changed);
      // Uploaded for a post that was not sent: the server forgets it.
      final id = u.media?.id;
      if (!_posted && id != null) balita.discardMedia(id);
    }
    _body.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _pickMedia() async {
    final room = BalitaUploader.maxItems - _uploads.length;
    if (room <= 0) {
      setState(() => _error = 'Up to ${BalitaUploader.maxItems} photos or videos per post.');
      return;
    }
    final files = await pickMediaProtected(
      context,
      limit: room,
      explanation: 'Esperanza needs access to your photos and videos so you can add them to your post.',
    );
    if (!mounted || files.isEmpty) return;
    setState(() {
      _error = files.length > room ? 'Only the first $room were added: up to ${BalitaUploader.maxItems} per post.' : null;
      for (final f in files.take(room)) {
        final upload = BalitaUpload(file: f, kind: BalitaUploader.kindOf(f))..addListener(_changed);
        _uploads.add(upload);
        _start(upload);
      }
    });
  }

  Future<void> _start(BalitaUpload upload) async {
    if (upload.kind == BalitaMediaKind.image && upload.previewBytes == null) {
      try {
        upload.previewBytes = await upload.file.readAsBytes();
      } catch (_) {
        // No thumbnail; it still uploads.
      }
    }
    if (upload.kind == BalitaMediaKind.video && upload.durationMs == null) await _measure(upload);
    await BalitaUploader.run(upload);
  }

  /// A video's length and frame size, for its tile here and in the feed.
  Future<void> _measure(BalitaUpload upload) async {
    if (kIsWeb) return;
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(upload.file.path));
      await controller.initialize().timeout(const Duration(seconds: 8));
      upload.durationMs = controller.value.duration.inMilliseconds;
      final size = controller.value.size;
      if (size.width > 0 && size.height > 0) {
        upload.width = size.width.round();
        upload.height = size.height.round();
      }
    } catch (_) {
      // Unknown here; the server reads an MP4's length itself.
    } finally {
      await controller?.dispose();
    }
  }

  void _remove(BalitaUpload upload) {
    upload.cancel();
    upload.removeListener(_changed);
    final id = upload.media?.id;
    if (id != null) _balita.discardMedia(id);
    setState(() => _uploads.remove(upload));
  }

  Future<void> _submit() async {
    final text = _body.text.trim();
    if (_uploading) {
      setState(() => _error = 'Wait for your photos and videos to finish uploading.');
      return;
    }
    if (_anyFailed) {
      setState(() => _error = 'Some files did not upload. Try them again or remove them.');
      return;
    }
    final mediaIds = [for (final u in _uploads) if (u.media != null) u.media!.id];
    if (text.isEmpty && mediaIds.isEmpty) {
      setState(() => _error = 'Please write something to post, or add a photo or video.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<BalitaService>().createPost(body: text, category: _category, mediaIds: mediaIds);
      if (!mounted) return;
      _posted = true;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // CAPABILITY_DENIED (403) reads exactly as intended without any
        // special-casing -- ApiException carries the server's own bilingual
        // copy for it.
        _error = e.explain();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
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
                      'right away marked "Pending review" -- only you can see it until then, and you are told '
                      'when it is published.',
                      style: TextStyle(fontSize: AppTextSize.label, color: AppColors.brand700, height: 1.4),
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
                  maxLength: BalitaService.postMaxLength,
                ),
                _MediaField(
                  uploads: _uploads,
                  onPick: _pickMedia,
                  onRemove: _remove,
                  onRetry: _start,
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _uploading ? 'Uploading…' : 'Post',
              fullWidth: true,
              size: AppButtonSize.lg,
              loading: _submitting,
              onPressed: _submitting || _uploading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// The photos and videos of the post: a tile each, with its upload's
/// progress, Try again when it failed, and remove.
class _MediaField extends StatelessWidget {
  final List<BalitaUpload> uploads;
  final VoidCallback onPick;
  final void Function(BalitaUpload) onRemove;
  final void Function(BalitaUpload) onRetry;

  const _MediaField({required this.uploads, required this.onPick, required this.onRemove, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final failed = uploads.where((u) => u.status == BalitaUploadStatus.failed && u.error != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos and videos (optional) · ${uploads.length} / ${BalitaUploader.maxItems}',
          style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Photos are made smaller before sending. Videos up to 100 MB, MP4 or WebM.',
          style: TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (uploads.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < uploads.length; i++)
                _UploadTile(upload: uploads[i], index: i, count: uploads.length, onRemove: onRemove, onRetry: onRetry),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final u in failed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '${u.file.name}: ${u.error}',
              style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.rose600),
            ),
          ),
        if (uploads.length < BalitaUploader.maxItems)
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
            label: const Text('Add photos or videos'),
          ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  final BalitaUpload upload;
  final int index;
  final int count;
  final void Function(BalitaUpload) onRemove;
  final void Function(BalitaUpload) onRetry;

  const _UploadTile({
    required this.upload,
    required this.index,
    required this.count,
    required this.onRemove,
    required this.onRetry,
  });

  static const _size = 88.0;

  @override
  Widget build(BuildContext context) {
    final video = upload.kind == BalitaMediaKind.video;
    final bytes = upload.previewBytes;
    final duration = upload.durationMs == null
        ? null
        : BalitaMedia(id: 0, kind: BalitaMediaKind.video, durationMs: upload.durationMs).durationLabel;
    return Semantics(
      label: '${video ? 'Video' : 'Photo'} ${index + 1} of $count',
      child: SizedBox(
        width: _size,
        height: _size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null && !video)
                Image(image: pickedFileImageProvider(bytes: bytes)!, fit: BoxFit.cover)
              else
                Container(
                  color: video ? AppColors.slate800 : AppColors.slate100,
                  alignment: Alignment.center,
                  child: Icon(
                    video ? Icons.videocam_rounded : Icons.image_outlined,
                    color: video ? AppColors.onMedia : AppColors.slate400,
                  ),
                ),
              if (video && duration != null)
                Positioned(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                  child: Text(
                    duration,
                    style: const TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w600, color: AppColors.onMedia),
                  ),
                ),
              if (upload.busy)
                Container(
                  color: AppColors.mediaScrim,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(upload.progress * 100).round()}%',
                        style: const TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w700, color: AppColors.onMedia),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(
                        value: upload.status == BalitaUploadStatus.waiting ? null : upload.progress,
                        color: AppColors.onMedia,
                        backgroundColor: AppColors.onMediaFaint,
                      ),
                    ],
                  ),
                ),
              if (upload.status == BalitaUploadStatus.failed)
                Material(
                  color: AppColors.mediaScrimStrong,
                  child: InkWell(
                    onTap: () => onRetry(upload),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: AppColors.onMedia, size: 20),
                          Text(
                            'Try again',
                            style: TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w600, color: AppColors.onMedia),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 2,
                right: 2,
                child: Material(
                  color: AppColors.mediaScrim,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onRemove(upload),
                    child: Tooltip(
                      message: 'Remove',
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.xs),
                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.onMedia),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
