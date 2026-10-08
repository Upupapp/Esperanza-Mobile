import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'esperanza_art.dart';

/// The app's card: glass with a gradient (2026-10 design, see
/// [GlassSurface]) — a translucent white-to-blue-to-gold fill, a sheen, a
/// lit gradient rim and a soft blue glow, rounded 20px.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// The colour the glass leans toward (a notification's own tone); null is
  /// the standard breath of blue.
  final Color? tint;

  /// Frosted white: nearly opaque, with only a faint cool tint, for cards
  /// people read at length (the Balita feed), where the standard glass let
  /// too much of the coloured backdrop through. Same rim, sheen, radius and
  /// glow as every other card.
  final bool frosted;

  /// The subtle glass layer ([GlassSurface.glass]) rather than the clean
  /// card. Used selectively — the Resident Profile card, notification cards,
  /// the verification panel — never on every card.
  final bool glass;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.tint,
    this.frosted = false,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    // A transparent Material so descendants have somewhere to paint ink.
    //
    // Without it a non-tappable card gave its children no Material ancestor,
    // and any ListTile inside one rendered with no ripple and no tileColor —
    // Flutter says so out loud ("ListTile background color or ink splashes
    // may be invisible") but only at runtime on a device, which is why the
    // widget suite never saw it. Settings was the visible case: four
    // notification and language controls that changed value with no feedback
    // at all under the finger. Found by the FE 03 device walk.
    final inner = Material(type: MaterialType.transparency, child: child);
    final content = glass
        ? GlassSurface.glass(radius: AppRadius.xl, padding: padding, tint: tint, child: inner)
        : frosted
        ? GlassSurface.frosted(radius: AppRadius.xl, padding: padding, child: inner)
        : GlassSurface(radius: AppRadius.xl, padding: padding, tint: tint, child: inner);

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(borderRadius: BorderRadius.circular(AppRadius.xl), onTap: onTap, child: content),
    );
  }
}
