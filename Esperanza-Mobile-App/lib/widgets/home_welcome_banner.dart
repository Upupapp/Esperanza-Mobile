import 'package:flutter/material.dart';

/// The post-entry promotional pop-up shown once Home has loaded — the
/// municipal welcome/services poster, never a normal card inside the Home
/// feed. Deliberately a plain `showDialog` (its default barrier already
/// dims the screen behind it) rather than a bespoke overlay: this is
/// informational/promotional content the user must be free to dismiss
/// immediately, never a blocking gate in front of Home.
class HomeWelcomeBanner extends StatelessWidget {
  const HomeWelcomeBanner({super.key});

  static const _assetPath = 'assets/images/Home_Banner.png';

  /// Shows the banner once. Callers are responsible for only invoking
  /// this once per session (see HomeScreen's `_bannerOffered` flag) — this
  /// method itself has no "already shown" memory, by design, so it stays
  /// a simple, reusable presentation widget rather than owning session
  /// state that belongs to its caller.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const HomeWelcomeBanner(),
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
            // never cropped, so the mayor's message, logos, and the
            // bottom "Tayo ang Pag-Asa" band all stay fully visible
            // regardless of phone width/height.
            constraints: BoxConstraints(maxWidth: size.width * 0.88, maxHeight: size.height * 0.82),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(_assetPath, fit: BoxFit.contain),
            ),
          ),
          // Positioned just outside the poster's own corner (not
          // overlapping it) so it can never cover any banner text/logo,
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
                tooltip: 'Close',
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
