import 'package:flutter/material.dart';

import '../models/balita_media.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A Balita post's photos and videos in its card (2026-10-18), laid out as
/// the website does: one alone at its own shape, two side by side, three
/// with the first across, four or more as a 2x2 grid whose last tile says how
/// many more. Tapping one calls [onOpen] with its index (the full-screen
/// viewer pages through them all).
class BalitaMediaGallery extends StatelessWidget {
  final List<BalitaMedia> media;
  final void Function(int index) onOpen;

  const BalitaMediaGallery({super.key, required this.media, required this.onOpen});

  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    final n = media.length;
    if (n == 0) return const SizedBox.shrink();

    Widget tile(int i, {int more = 0}) => BalitaMediaTile(
          media: media[i],
          index: i,
          count: n,
          more: more,
          onTap: () => onOpen(i),
        );
    Widget square(int i, {int more = 0}) => Expanded(child: AspectRatio(aspectRatio: 1, child: tile(i, more: more)));

    final Widget grid;
    if (n == 1) {
      final m = media.first;
      final ratio = (m.aspectRatio ?? (m.isVideo ? 16 / 9 : 4 / 3)).clamp(0.8, 1.91);
      grid = AspectRatio(aspectRatio: ratio, child: tile(0));
    } else if (n == 2) {
      grid = Row(children: [square(0), const SizedBox(width: _gap), square(1)]);
    } else if (n == 3) {
      grid = Column(children: [
        AspectRatio(aspectRatio: 16 / 9, child: tile(0)),
        const SizedBox(height: _gap),
        Row(children: [square(1), const SizedBox(width: _gap), square(2)]),
      ]);
    } else {
      grid = Column(children: [
        Row(children: [square(0), const SizedBox(width: _gap), square(1)]),
        const SizedBox(height: _gap),
        Row(children: [square(2), const SizedBox(width: _gap), square(3, more: n > 4 ? n - 4 : 0)]),
      ]);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: grid);
  }
}

/// One photo or video tile: the photo, or a video's still (or a dark tile)
/// with a play button and its length; "+N" over the last one shown.
class BalitaMediaTile extends StatelessWidget {
  final BalitaMedia media;
  final int index;
  final int count;
  final int more;
  final VoidCallback onTap;

  const BalitaMediaTile({
    super.key,
    required this.media,
    required this.index,
    required this.count,
    this.more = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = media.isVideo ? media.posterUrl : media.url;
    final ready = media.url != null;
    final label = media.isVideo
        ? 'Video${media.durationLabel != null ? ', ${media.durationLabel}' : ''}, ${index + 1} of $count'
        : 'Photo ${index + 1} of $count';

    return Semantics(
      button: true,
      label: more > 0 ? '$label, and $more more' : label,
      child: Material(
        color: media.isVideo ? AppColors.slate800 : AppColors.slate100,
        child: InkWell(
          onTap: ready ? onTap : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url != null)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  errorBuilder: (context, error, stack) => const Center(
                    child: Icon(Icons.image_not_supported_outlined, color: AppColors.slate400, size: 26),
                  ),
                ),
              if (!ready)
                const Center(
                  child: Text('Being checked', style: TextStyle(fontSize: AppTextSize.label, color: AppColors.slate500)),
                ),
              if (media.isVideo && ready)
                Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(color: AppColors.mediaScrim, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: AppColors.onMedia, size: 30),
                  ),
                ),
              if (media.isVideo && media.durationLabel != null)
                Positioned(
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.mediaScrimStrong,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      media.durationLabel!,
                      style: const TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w600, color: AppColors.onMedia),
                    ),
                  ),
                ),
              if (more > 0)
                Container(
                  color: AppColors.mediaScrim,
                  alignment: Alignment.center,
                  child: Text(
                    '+$more',
                    style: const TextStyle(fontSize: AppTextSize.page, fontWeight: FontWeight.w800, color: AppColors.onMedia),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
