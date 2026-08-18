import 'package:flutter/material.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          ConstrainedBox(
            // Bounded, not forced: BoxFit.contain inside these max bounds
            // keeps the poster's real aspect ratio — never stretched,
            // never cropped, never squeezed into a landscape banner shape
            // — regardless of phone width/height.
            constraints: BoxConstraints(maxWidth: size.width * 0.88, maxHeight: size.height * 0.82),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(assetPath, fit: BoxFit.contain),
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
