import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The one full-screen, pinch-to-zoom image viewer: government ID, Digital
/// ID credential, event poster, uploaded document and attachment previews.
///
/// Until 2026-09-28 each of those five screens carried its own copy, and
/// every copy set an AppBar title style with no font family, so the title
/// fell back to the platform font (not Inter) and a long title ran off the
/// bar. A missing image showed an empty black screen, a screen reader heard
/// nothing, and nothing said the picture could be zoomed.
class ImageViewerScaffold extends StatelessWidget {
  const ImageViewerScaffold({super.key, required this.title, required this.image, required this.semanticLabel});

  final String title;

  /// Null when there is nothing to show (bytes not kept across a restart).
  final ImageProvider? image;

  /// What a screen reader announces for the image.
  final String semanticLabel;

  static const unavailableText = 'Preview not available.';
  static const zoomHint = 'Pinch to zoom';

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.surface.withValues(alpha: 0.72);
    final unavailable = Text(unavailableText, style: AppTypography.helper.copyWith(color: muted));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.surface,
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.surface),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: image == null
                    ? unavailable
                    : InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Image(
                          image: image!,
                          fit: BoxFit.contain,
                          semanticLabel: semanticLabel,
                          errorBuilder: (_, _, _) => unavailable,
                        ),
                      ),
              ),
            ),
            if (image != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pinch_outlined, size: AppSizes.iconSm, color: muted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(zoomHint, style: AppTypography.fine.copyWith(color: muted)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
