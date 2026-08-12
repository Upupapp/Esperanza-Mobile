import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/media_picker_action.dart';
import '../../widgets/post_composer_text_field.dart';
import '../../widgets/selected_media_preview.dart';

/// Frontend-only post composer. Publishing pops this sheet with the new
/// [Announcement], which BalitaScreen hands to BalitaService — the same
/// "no backend, local state only" pattern used by every other submit flow
/// in this app (see NewRequestScreen).
///
/// Layout is keyboard-aware by construction: a fixed header (drag handle +
/// identity), a `Flexible` + `SingleChildScrollView` middle section that
/// absorbs the text field, media preview, and Add Media action, and a
/// pinned footer with the Post button — all wrapped in a height-capped
/// `AnimatedPadding` that lifts above `MediaQuery.viewInsets.bottom`. This
/// is what makes it structurally impossible to overflow: previously the
/// whole sheet was one `mainAxisSize.min` `Column` with no scrollable
/// ancestor, so once the keyboard + a media preview + multi-line text
/// exceeded the remaining screen height, there was nowhere for the extra
/// content to go — hence "BOTTOM OVERFLOWED BY 15 PIXELS".
class PostComposerSheet extends StatefulWidget {
  const PostComposerSheet({super.key});

  @override
  State<PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends State<PostComposerSheet> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  PostMedia? _media;
  bool _publishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _media = PostMedia(path: file.path, type: PostMediaType.image, fileName: file.name));
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() => _media = PostMedia(path: file.path, type: PostMediaType.video, fileName: file.name));
  }

  void _removeMedia() => setState(() => _media = null);

  Future<void> _publish() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _media == null) return; // Post button is disabled in this state; belt-and-suspenders.

    setState(() => _publishing = true);
    final account = context.read<CitizenSessionService>().account;
    await Future.delayed(const Duration(milliseconds: 500)); // simulated publish delay
    if (!mounted) return;

    final post = Announcement(
      id: 'bal-local-${DateTime.now().microsecondsSinceEpoch}',
      official: '',
      author: account?.fullName ?? 'You',
      barangay: account?.barangay,
      body: text,
      time: 'Just now',
      media: _media,
      likes: 0,
    );
    Navigator.of(context).pop(post);
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<CitizenSessionService>().account;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed header — always visible, never scrolls away.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(999)),
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.brand50,
                            child: Text(
                              account?.initials ?? '?',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand600),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(account?.fullName ?? 'You', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                if (account != null)
                                  Text('Brgy. ${account.barangay}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Scrollable middle — text field, media preview, Add Media.
                // This is the section that grows/shrinks with keyboard and
                // content, and scrolls internally instead of overflowing.
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PostComposerTextField(controller: _controller, autofocus: true),
                        if (_media != null) ...[
                          const SizedBox(height: 12),
                          SelectedMediaPreview(media: _media!, onRemove: _removeMedia),
                        ],
                        const SizedBox(height: 4),
                        const Divider(height: 24),
                        MediaPickerAction(
                          hasMedia: _media != null,
                          onPickImage: _pickImage,
                          onPickVideo: _pickVideo,
                        ),
                      ],
                    ),
                  ),
                ),
                // Pinned footer — Post stays reachable even with the
                // keyboard open, since AnimatedPadding lifts this whole
                // Container above viewInsets.bottom.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final canPost = value.text.trim().isNotEmpty || _media != null;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: AppButton(
                        label: 'Post',
                        icon: Icons.send_rounded,
                        fullWidth: true,
                        size: AppButtonSize.lg,
                        loading: _publishing,
                        onPressed: canPost ? _publish : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
