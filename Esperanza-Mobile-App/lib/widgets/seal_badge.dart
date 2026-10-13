import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/esperanza_seal.dart';

/// The one tag the opening screen's seal and the welcome pages' seal share,
/// so Flutter flies the first into the second as the screens change (owner,
/// 2026-10-12: "the logo remains and morphs to the logo on the upper left").
const esperanzaSealHeroTag = 'esperanza-seal';

/// The municipal seal on its white plate, at whatever size it is given.
///
/// The plate's rim follows the size — 5 at the opening screen's 196, 2 at the
/// welcome header's 46 — so in flight between the two only the size changes,
/// never the drawing. [shadow] (0 to 1) is the opening screen's deep drop
/// shadow; it fades out as the seal flies, since the header's seal has none.
class SealBadge extends StatelessWidget {
  const SealBadge({super.key, this.shadow = 0, this.semanticLabel});

  final double shadow;

  /// Announced when set; otherwise the seal is decoration beside a label
  /// that already names the municipality.
  final String? semanticLabel;

  /// Decoded once at the largest size it is shown, so a flight between sizes
  /// never decodes it again.
  static int cacheWidth(BuildContext context) => (196 * MediaQuery.devicePixelRatioOf(context)).round();

  @override
  Widget build(BuildContext context) {
    final cache = cacheWidth(context);
    return LayoutBuilder(
      builder: (context, box) {
        final d = box.biggest.shortestSide;
        final rim = lerpDouble(2, 5, ((d - 46) / 150).clamp(0.0, 1.0))!;
        return Container(
          width: d,
          height: d,
          padding: EdgeInsets.all(rim),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: shadow <= 0
                ? null
                : [
                    BoxShadow(color: AppColors.navy950.withValues(alpha: 0.45 * shadow), blurRadius: 40, offset: const Offset(0, 16)),
                    BoxShadow(color: AppColors.gold400.withValues(alpha: 0.08 * shadow), spreadRadius: 6),
                  ],
          ),
          child: ClipOval(
            child: Image.asset(
              esperanzaSealAsset,
              fit: BoxFit.cover,
              cacheWidth: cache,
              semanticLabel: semanticLabel,
              excludeFromSemantics: semanticLabel == null,
            ),
          ),
        );
      },
    );
  }
}

/// The seal in flight: its shadow fading from the opening screen's to none.
Widget sealFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) => SealBadge(shadow: direction == HeroFlightDirection.push ? 1 - animation.value : animation.value),
  );
}
