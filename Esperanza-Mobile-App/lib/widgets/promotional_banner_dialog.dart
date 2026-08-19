import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// The one shared implementation behind every promotional popup in this
/// app (Home, Dokyu, Tulong, Balita, Events, Emergency) — extracted
/// verbatim from [HomeWelcomeBanner], the original and still the visual
/// source of truth for this presentation: a centered modal dialog (default
/// `showDialog` barrier dims the screen behind it) showing one portrait
/// poster at `BoxFit.contain` inside width/height-bounded constraints
/// (never squeezed into a horizontal banner, never stretched or cropped),
/// with a dark-circle X close button floating just outside its corner.
/// `HomeWelcomeBanner` now delegates to this directly; every other tab
/// calls [show] rather than maintaining its own copy of this same popup.
class PromotionalBannerDialog extends StatelessWidget {
  final String assetPath;
  final String label;

  const PromotionalBannerDialog({super.key, required this.assetPath, required this.label});

  // The one shared sizing rule every promotional banner in the app uses —
  // calibrated to read as large/prominent as the onboarding Welcome
  // Screens' full-bleed artwork, while still staying a bounded rounded
  // modal (never fullscreen/edge-to-edge like onboarding itself). Kept as
  // named fractions, not scattered literals, so Dokyu/Tulong/Balita/
  // Events/Emergency/Home can never drift out of sync with each other —
  // every one of them renders through this single widget.
  static const _maxWidthFraction = 0.94;
  static const _maxHeightFraction = 0.90;
  // Small, comfortable floor margin for the rare case a screen is narrow/
  // short enough that this — not the fractions above — ends up binding
  // (e.g. a very small phone) — the poster still never touches the
  // screen edge.
  static const _insetPadding = EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxl);

  /// Shows the popup once. Callers are responsible for only invoking this
  /// once per session per tab (each screen owns its own dismissed-flag,
  /// kept separate per tab so closing one never dismisses another) — this
  /// method itself has no "already shown" memory, by design.
  static Future<void> show(BuildContext context, {required String assetPath, required String label}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => PromotionalBannerDialog(assetPath: assetPath, label: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final maxWidth = size.width * _maxWidthFraction;
    final maxHeight = size.height * _maxHeightFraction;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: _insetPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          ConstrainedBox(
            // Bounded, not forced: BoxFit.contain inside these max bounds
            // keeps the poster's real aspect ratio — never stretched,
            // never cropped, never squeezed into a landscape banner shape
            // — regardless of phone width/height.
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              // These source posters are ~1024x1536 — bigger than this
              // dialog ever displays them at (it's width-bound in
              // practice, per maxWidth/maxHeight above). cacheWidth tells
              // the decoder to produce a bitmap sized for the dialog's own
              // physical-pixel width instead of the full source
              // resolution — height scales automatically to match, so the
              // real aspect ratio is preserved exactly (never distorted
              // the way independently setting both cacheWidth and
              // cacheHeight could). Cuts decode time and image-cache
              // memory with no visible quality loss, since the cache size
              // is still >= what the screen can actually show.
              child: Image.asset(assetPath, fit: BoxFit.contain, cacheWidth: (maxWidth * dpr).round()),
            ),
          ),
          // Positioned just outside the poster's own corner (not
          // overlapping it) so it can never cover any poster text/logo,
          // with its own dark circular backdrop so it stays clearly
          // visible regardless of what's directly behind it.
          Positioned(
            top: -14,
            right: -14,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: 'Close $label banner',
                iconSize: 22,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
