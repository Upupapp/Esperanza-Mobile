import 'dart:io';
import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../theme/app_colors.dart';

/// A capped-height, responsive-width preview of a locally-selected media
/// attachment in the Balita composer, with a clearly visible remove
/// control. Fixed height (rather than an aspect-ratio-preserving box) is
/// deliberate here: it's what actually caps how much of the composer a
/// large photo can consume, satisfying "don't let an attached image
/// consume almost the entire modal" without depending on the source
/// image's own dimensions.
class SelectedMediaPreview extends StatelessWidget {
  final PostMedia media;
  final VoidCallback onRemove;

  const SelectedMediaPreview({super.key, required this.media, required this.onRemove});

  static const double _height = 200;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            media.type == PostMediaType.image ? _imagePreview() : _videoPreview(),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview() {
    return media.isAsset
        ? Image.asset(media.path, fit: BoxFit.cover)
        : Image.file(File(media.path), fit: BoxFit.cover);
  }

  Widget _videoPreview() {
    return Container(
      color: AppColors.navy900,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              media.fileName ?? 'Video attached',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
