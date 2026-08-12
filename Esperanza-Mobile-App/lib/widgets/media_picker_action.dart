import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The "Add Media / Change Media" trigger row used by the Balita post
/// composer. Tapping opens a small chooser (Photo / Video) and reports the
/// choice back via [onPickImage]/[onPickVideo] — actual device picking
/// (image_picker) stays owned by the composer's own state, since it's the
/// one that holds the selected media.
class MediaPickerAction extends StatelessWidget {
  final bool hasMedia;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;

  const MediaPickerAction({
    super.key,
    required this.hasMedia,
    required this.onPickImage,
    required this.onPickVideo,
  });

  void _showChooser(BuildContext context) {
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
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.emerald500),
                title: const Text('Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  onPickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: AppColors.rose600),
                title: const Text('Video', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  onPickVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showChooser(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.perm_media_outlined, size: 19, color: AppColors.emerald500),
            const SizedBox(width: 10),
            Text(
              hasMedia ? 'Change Media' : 'Add Media',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate600),
            ),
          ],
        ),
      ),
    );
  }
}
