import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/document_preview.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'document_paper.dart';

/// The document page, which the resident can pinch to zoom in and out, drag
/// to move around, and double-tap to zoom in on a spot (or back to the whole
/// width). It starts at the screen's width; zoomed out, the page settles in
/// the middle.
class ZoomableDocument extends StatefulWidget {
  const ZoomableDocument({super.key, required this.sheet, this.barangaySealUrl, this.captureKey});

  final DocumentSheet sheet;
  final String? barangaySealUrl;

  /// Passed on to [DocumentPaper], for Download PDF.
  final GlobalKey? captureKey;

  /// How far a pinch may zoom in, and out.
  static const maxScale = 5.0;
  static const minScale = 0.5;

  /// How far a double-tap zooms in.
  static const doubleTapScale = 2.5;

  @override
  State<ZoomableDocument> createState() => _ZoomableDocumentState();
}

class _ZoomableDocumentState extends State<ZoomableDocument> {
  final _zoom = TransformationController();
  Offset _tapAt = Offset.zero;
  Size _viewport = Size.zero;
  double _pageHeight = 0;

  /// Smaller than the screen: back to the middle, not left in a corner.
  void _settle() {
    final s = _zoom.value.getMaxScaleOnAxis();
    if (s >= 1) return;
    final w = _viewport.width;
    final dx = (w - w * s) / 2;
    final dy = math.max(0.0, (_viewport.height - _pageHeight * s) / 2);
    _zoom.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, s, 1);
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _doubleTap() {
    if (_zoom.value.getMaxScaleOnAxis() > 1.01) {
      _zoom.value = Matrix4.identity();
      return;
    }
    const s = ZoomableDocument.doubleTapScale;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(-_tapAt.dx * (s - 1), -_tapAt.dy * (s - 1), 0, 1)
      ..scaleByDouble(s, s, s, 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.hasBoundedHeight ? constraints.maxHeight : width * 1.5;
        _viewport = Size(width, height);
        _pageHeight = width * DocumentPage.height / DocumentPage.width;
        return GestureDetector(
          onDoubleTapDown: (d) => _tapAt = d.localPosition,
          onDoubleTap: _doubleTap,
          child: InteractiveViewer(
            transformationController: _zoom,
            constrained: false,
            minScale: ZoomableDocument.minScale,
            maxScale: ZoomableDocument.maxScale,
            // Room to hold a zoomed-out page in the middle.
            boundaryMargin: EdgeInsets.symmetric(horizontal: width / 2, vertical: height / 2),
            onInteractionEnd: (_) => _settle(),
            child: SizedBox(
              width: width,
              child: DocumentPaper(
                sheet: widget.sheet,
                barangaySealUrl: widget.barangaySealUrl,
                captureKey: widget.captureKey,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The page on its own, full screen, to pinch and read (the request form's
/// Review preview opens this).
class DocumentFullScreen extends StatelessWidget {
  const DocumentFullScreen({super.key, required this.sheet, this.barangaySealUrl, this.title = 'Preview'});

  final DocumentSheet sheet;
  final String? barangaySealUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: ZoomableDocument(sheet: sheet, barangaySealUrl: barangaySealUrl),
                ),
              ),
            ),
            const DocumentZoomHint(),
          ],
        ),
      ),
    );
  }
}

/// How to zoom, said under the page.
class DocumentZoomHint extends StatelessWidget {
  const DocumentZoomHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pinch_outlined, size: AppSizes.iconSm, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Pinch to zoom in or out · double-tap to zoom',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
