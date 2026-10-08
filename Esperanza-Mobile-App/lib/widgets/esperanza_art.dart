import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/service_request.dart';

/// The 2026-10 visual language: claymorphism (soft, puffy, lit-from-above
/// objects with an inner shade and a drop shadow) and glassmorphism (frosted,
/// translucent panels over a gradient). Everything here is painted in code
/// from the AppColors palette — no new colour, no image asset — so it stays
/// crisp at any size and follows the design tokens.

// ─── Glass and clay surfaces ───────────────────────────────────────────────

/// A frosted-glass panel: blurs what is behind it, with a translucent white
/// fill, a bright hairline and a soft shadow. [dark] is the variant for a
/// navy ground (lower opacity, so the colour behind still reads through).
class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final bool dark;
  final double blur;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = EdgeInsets.zero,
    this.dark = false,
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    // Light glass is near-opaque (2026-10 refinement): the page behind is
    // quiet now, and a pane that let it through blended into it.
    final top = dark ? 0.16 : 0.97;
    final bottom = dark ? 0.06 : 0.92;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy900.withValues(alpha: dark ? 0.25 : 0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface.withValues(alpha: top), AppColors.surface.withValues(alpha: bottom)],
              ),
              border: Border.all(color: AppColors.surface.withValues(alpha: dark ? 0.28 : 0.85), width: 1.2),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// A clay tile: a soft, slightly inflated pillow lit from the top-left — an
/// opaque body, a pooled highlight in the upper-left, an inner shade along
/// the lower edge, and a two-part shadow (a tight contact shadow and a wide
/// soft one) so it sits *on* the card rather than printed into it. Holds a
/// [ClayIcon]: service and quick-action icons, empty and success states.
///
/// [warm] gives the lower edge a gold inner shade instead of a cool one —
/// the navy-and-gold pairing for Home's quick actions.
class ClayTile extends StatelessWidget {
  final Widget child;
  final double size;
  final double radius;
  final bool warm;

  const ClayTile({super.key, required this.child, this.size = 68, this.radius = 22, this.warm = false});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.slate50, AppColors.brand50],
          stops: [0, 0.5, 1],
        ),
        border: Border.all(color: AppColors.surface, width: 1.5),
        boxShadow: [
          // Wide and soft: the lift.
          BoxShadow(color: AppColors.navy800.withValues(alpha: 0.20), blurRadius: 22, offset: const Offset(0, 12), spreadRadius: -4),
          // Tight: where it touches the card.
          BoxShadow(color: AppColors.navy800.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            // The inner shade along the lower edge that makes it read as
            // soft and rounded rather than flat.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surface.withValues(alpha: 0),
                      (warm ? AppColors.gold200 : AppColors.brand100).withValues(alpha: warm ? 0.70 : 0.80),
                    ],
                    stops: const [0.50, 1],
                  ),
                ),
              ),
            ),
            // The pooled highlight in the upper-left: the inflated look.
            Positioned(
              left: -size * 0.15,
              top: -size * 0.20,
              width: size * 0.85,
              height: size * 0.70,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}

/// The card surface of the 2026-10 design: frosted glass. A high-opacity
/// fill running from white to a breath of blue, a soft sheen in the upper-
/// left, a rim that is bright where the light hits and fades to a cool edge
/// away from it, and a clear, soft navy shadow beneath.
///
/// Refined after review: the first version was translucent (a 0.58 tint over
/// a colourful backdrop) and the cards blended into the page. The page is
/// quiet now and the default near-opaque — the clean, solid card most of the
/// app uses. [blur] frosts what is behind as well; it is off by default,
/// because a long list of blurred cards is costly to scroll on a low-end
/// phone.
///
/// [GlassSurface.glass] is the subtle glass layer, used selectively (the
/// Resident Profile card, Home's quick actions, event and notification
/// cards, the verification panel): about 88% white, a brighter pooled
/// highlight, a white rim and a slightly deeper shadow, so it is visibly a
/// pane over the page while its text stays fully readable.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool blur;

  /// The colour the glass leans toward through its middle; null is white.
  final Color? tint;

  /// The colour the glass ends on at the lower-right; null is a breath of
  /// blue. An alert sets both tints to its own red.
  final Color? tintEnd;

  /// The colour the rim fades to away from the light; null is the standard
  /// blue-into-gold.
  final Color? rim;

  /// How solid the glass is, 1 being the standard card. Lower lets more of
  /// what is behind show — for a panel over a coloured ground, with [blur].
  final double opacity;

  /// How strongly the glass takes [tint] through its middle and [tintEnd] at
  /// its lower-right. Near-opaque by default, so a card never disappears
  /// into the page; a panel over a coloured ground lowers [opacity] instead.
  final double tintAlpha;
  final double tintEndAlpha;

  /// The colour of the soft glow beneath; null is the standard navy shadow.
  final Color? glow;

  /// How opaque the white at the top-left of the glass is.
  final double baseAlpha;

  /// The subtle glass layer rather than the clean card (see the class doc).
  final bool glass;

  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.blur = false,
    this.tint,
    this.tintEnd,
    this.rim,
    this.opacity = 1,
    this.tintAlpha = 0.95,
    this.tintEndAlpha = 0.94,
    this.glow,
    this.baseAlpha = 0.98,
  }) : glass = false;

  /// The subtle glass layer: ~88% white over the page, a white rim, a
  /// pooled highlight and a soft navy shadow. [blur] only where something
  /// sits behind it (a panel over the Home hero); on the flat page it would
  /// cost scrolling for nothing.
  const GlassSurface.glass({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.blur = false,
    this.tint,
    this.tintEnd,
    this.rim,
    this.glow,
  })  : glass = true,
        opacity = 1,
        baseAlpha = 0.92,
        tintAlpha = 0.86,
        tintEndAlpha = 0.84;

  /// Frosted white, for the feeds read at length (Balita posts, Events).
  /// Since the 2026-10 refinement this is the standard card; the name stays
  /// so those call sites say what they need.
  const GlassSurface.frosted({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.rim,
    this.glow,
  })  : blur = false,
        glass = false,
        tint = null,
        tintEnd = null,
        opacity = 1,
        baseAlpha = 0.98,
        tintAlpha = 0.95,
        tintEndAlpha = 0.94;

  /// A clear but soft navy shadow: the card lifts off the quiet page.
  static List<BoxShadow> get shadow => [
    BoxShadow(color: AppColors.navy900.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -6),
    BoxShadow(color: AppColors.navy900.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1)),
  ];

  /// The glass layer floats a little higher than a clean card.
  static List<BoxShadow> get glassShadow => [
    BoxShadow(color: AppColors.navy900.withValues(alpha: 0.11), blurRadius: 28, offset: const Offset(0, 12), spreadRadius: -6),
    BoxShadow(color: AppColors.navy900.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget body = Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface.withValues(alpha: baseAlpha * opacity),
                  (tint ?? AppColors.surface).withValues(alpha: tintAlpha * opacity),
                  (tintEnd ?? AppColors.brand50).withValues(alpha: tintEndAlpha * opacity),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
        ),
        // The sheen: soft light pooled in the upper-left. The crisp diagonal
        // glare band it used to have is gone — too glossy for a government
        // app, and it ran across text.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surface.withValues(alpha: glass ? 0.85 : 0.60), AppColors.surface.withValues(alpha: 0.0)],
                  stops: [0, glass ? 0.45 : 0.35],
                ),
              ),
            ),
          ),
        ),
        Padding(padding: padding, child: child),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GlassRimPainter(radius, rim, glass)))),
      ],
    );
    if (blur) {
      body = BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: glass ? 10 : 14, sigmaY: glass ? 10 : 14), child: body);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: glow == null
            ? (glass ? glassShadow : shadow)
            : [
                BoxShadow(color: glow!.withValues(alpha: 0.22), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -8),
                BoxShadow(color: AppColors.navy900.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
              ],
      ),
      child: ClipRRect(borderRadius: r, child: body),
    );
  }
}

/// The glass edge: a rim lit white at the top-left, fading toward the
/// bottom-right into a cool blue and a hint of gold, which keep the card's
/// edge visible on the light page. The glass layer's rim stays white longer
/// (a pane's edge catching the light) and is a touch heavier.
class _GlassRimPainter extends CustomPainter {
  final double radius;
  final Color? rim;
  final bool glass;
  const _GlassRimPainter(this.radius, this.rim, [this.glass = false]);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glass ? 1.6 : 1.4
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            glass ? AppColors.surface.withValues(alpha: 0.95) : (rim ?? AppColors.slate200).withValues(alpha: 0.70),
            (rim ?? AppColors.brand200).withValues(alpha: 0.75),
            (rim ?? AppColors.gold200).withValues(alpha: 0.85),
          ],
          stops: [0, glass ? 0.50 : 0.40, 0.78, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassRimPainter old) => old.radius != radius || old.rim != rim || old.glass != glass;
}

/// Wraps a platform's page transition so every page paints the soft colour
/// backdrop beneath itself (scaffolds are clear in the theme). Painted inside
/// the route, so a page that slides over another is opaque, never a see-
/// through overlap of the two.
class BackdropPageTransitionsBuilder extends PageTransitionsBuilder {
  final PageTransitionsBuilder inner;
  const BackdropPageTransitionsBuilder(this.inner);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return inner.buildTransitions(route, context, animation, secondaryAnimation, GlassBackdrop(child: child));
  }
}

/// The quiet page ground behind every screen ([SoftBackdropPainter]): near-
/// solid light blue-gray, so the cards above it stand clear of it.
class GlassBackdrop extends StatelessWidget {
  final Widget child;
  const GlassBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: SoftBackdropPainter()))),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// A neumorphic well: a soft, slightly sunken surface pressed into the page
/// (darker along the upper-left inner edge, lit along the lower-right),
/// for input fields, toggles and small icon containers. Used sparingly, as
/// the brief asks: neumorphism supports, it does not lead.
class NeuWell extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Gold edge while the field it holds has focus.
  final bool focused;

  /// Rose edge while the field it holds is in error.
  final bool error;

  const NeuWell({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding = EdgeInsets.zero,
    this.focused = false,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final edge = error ? AppColors.rose500 : (focused ? AppColors.gold500 : AppColors.surface);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: r,
        // The sunken face: shade at the upper-left, light at the lower-right.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.slate200.withValues(alpha: 0.85), AppColors.slate50.withValues(alpha: 0.95)],
        ),
        // A slate hairline at rest, so a field is identifiable at a glance
        // on white and on the light page alike.
        border: Border.all(color: focused || error ? edge : AppColors.slate300, width: focused || error ? 1.6 : 1.2),
        boxShadow: [
          // The lit lip below and to the right of the well.
          BoxShadow(color: AppColors.surface.withValues(alpha: 0.9), blurRadius: 6, offset: const Offset(2, 3)),
          if (focused) BoxShadow(color: AppColors.gold400.withValues(alpha: 0.30), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The navy header band of a form wizard (2026-10 design, as the design's
/// "Apply for Business Permit"): deep navy flowing on from a navy app bar,
/// a warm glow at the right, rounded at the bottom, holding the stepper.
class NavyBand extends StatelessWidget {
  final Widget child;
  const NavyBand({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy900, AppColors.navy800, AppColors.brand800],
        ),
        boxShadow: [BoxShadow(color: AppColors.navy900.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

  /// The matching app bar: navy, white title and icons, light status bar.
  static AppBar appBar({required Widget title, List<Widget>? actions, Widget? leading}) => AppBar(
    title: title,
    actions: actions,
    leading: leading,
    backgroundColor: AppColors.navy900,
    foregroundColor: AppColors.surface,
    iconTheme: const IconThemeData(color: AppColors.surface),
    titleTextStyle: AppTypography.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.surface),
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: AppColors.clear,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
}

/// The padding inside a wizard's glass form card: roomy on a normal phone,
/// tighter on a narrow one, where every point goes to the fields.
EdgeInsets wizardCardPadding(BuildContext context) =>
    EdgeInsets.all(MediaQuery.sizeOf(context).width < 360 ? 14 : 20);

/// The success moment (2026-10 design): a big glossy clay check on a soft
/// green halo, with gold sparkles — friendly, not festive.
class SuccessIllustration extends StatelessWidget {
  final double size;
  const SuccessIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.green500.withValues(alpha: 0.28), AppColors.green500.withValues(alpha: 0)],
              ),
            ),
          ),
          ClayIcon(ClayGlyph.check, size: size, semanticLabel: 'Success'),
        ],
      ),
    );
  }
}

/// The loading state: a navy spinner over a gold track inside a frosted
/// glass disc, so waiting looks like part of the app, not a default.
class EsperanzaLoader extends StatelessWidget {
  final double size;
  const EsperanzaLoader({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.22),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface.withValues(alpha: 0.95), AppColors.brand50.withValues(alpha: 0.85)],
        ),
        border: Border.all(color: AppColors.surface, width: 1.4),
        boxShadow: [BoxShadow(color: AppColors.brand500.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: const CircularProgressIndicator(strokeWidth: 3.2, color: AppColors.navy700, backgroundColor: AppColors.gold200),
    );
  }
}

/// The small clay icon at the head of a request card: a document for
/// Dokyu, a heart for Tulong, a shield for an incident report.
class RequestClayIcon extends StatelessWidget {
  final ServiceCategory category;
  const RequestClayIcon(this.category, {super.key});

  @override
  Widget build(BuildContext context) {
    final glyph = switch (category) {
      ServiceCategory.tulong => ClayGlyph.heart,
      ServiceCategory.sakunaIncident => ClayGlyph.shield,
      _ => ClayGlyph.document,
    };
    return ClayTile(size: 46, radius: 15, child: ClayIcon(glyph, size: 28));
  }
}

/// A clay status ball: a glossy round badge for a dialog, a notification or
/// an empty/error state. Its tone carries the meaning, and [glyph] (check,
/// warning, info…) says it again, so colour is never the only signal.
class ClayBadge extends StatelessWidget {
  final ClayGlyph glyph;
  final double size;
  const ClayBadge(this.glyph, {super.key, this.size = 56});

  @override
  Widget build(BuildContext context) => ClayIcon(glyph, size: size);
}

// ─── Clay icons ────────────────────────────────────────────────────────────

enum ClayGlyph { document, heart, folder, pin, megaphone, building, shield, card, bell, check, warning, info, camera, box, search, person, error, calendar }

/// One of the design's 3D icons, painted: glossy, lit from the top-left,
/// with an inner shade and its own drop shadow.
class ClayIcon extends StatelessWidget {
  final ClayGlyph glyph;
  final double size;
  final String? semanticLabel;

  const ClayIcon(this.glyph, {super.key, this.size = 40, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final icon = SizedBox.square(dimension: size, child: CustomPaint(painter: _ClayIconPainter(glyph)));
    if (semanticLabel == null) return ExcludeSemantics(child: icon);
    return Semantics(label: semanticLabel, image: true, child: icon);
  }
}

class _ClayIconPainter extends CustomPainter {
  final ClayGlyph glyph;
  _ClayIconPainter(this.glyph);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Offset p(double x, double y) => Offset(x * s, y * s);
    Rect r(double l, double t, double rr, double b) => Rect.fromLTRB(l * s, t * s, rr * s, b * s);

    switch (glyph) {
      case ClayGlyph.document:
        final page = Path()
          ..moveTo(0.30 * s, 0.10 * s)
          ..lineTo(0.60 * s, 0.10 * s)
          ..lineTo(0.80 * s, 0.30 * s)
          ..lineTo(0.80 * s, 0.80 * s)
          ..quadraticBezierTo(0.80 * s, 0.90 * s, 0.70 * s, 0.90 * s)
          ..lineTo(0.30 * s, 0.90 * s)
          ..quadraticBezierTo(0.20 * s, 0.90 * s, 0.20 * s, 0.80 * s)
          ..lineTo(0.20 * s, 0.20 * s)
          ..quadraticBezierTo(0.20 * s, 0.10 * s, 0.30 * s, 0.10 * s)
          ..close();
        clay(canvas, page, const [AppColors.brand500, AppColors.navy800]);
        final fold = Path()
          ..moveTo(0.60 * s, 0.10 * s)
          ..lineTo(0.60 * s, 0.26 * s)
          ..quadraticBezierTo(0.60 * s, 0.30 * s, 0.64 * s, 0.30 * s)
          ..lineTo(0.80 * s, 0.30 * s)
          ..close();
        clay(canvas, fold, const [AppColors.brand200, AppColors.brand400], shadow: false);
        final line = Paint()..color = AppColors.surface.withValues(alpha: 0.92);
        for (final (y, end) in [(0.46, 0.68), (0.59, 0.68), (0.72, 0.56)]) {
          canvas.drawRRect(RRect.fromRectAndRadius(r(0.32, y, end, y + 0.055), Radius.circular(0.03 * s)), line);
        }
      case ClayGlyph.heart:
        final heart = Path()
          ..moveTo(0.50 * s, 0.86 * s)
          ..cubicTo(0.16 * s, 0.64 * s, 0.06 * s, 0.42 * s, 0.18 * s, 0.26 * s)
          ..cubicTo(0.30 * s, 0.11 * s, 0.46 * s, 0.17 * s, 0.50 * s, 0.30 * s)
          ..cubicTo(0.54 * s, 0.17 * s, 0.70 * s, 0.11 * s, 0.82 * s, 0.26 * s)
          ..cubicTo(0.94 * s, 0.42 * s, 0.84 * s, 0.64 * s, 0.50 * s, 0.86 * s)
          ..close();
        clay(canvas, heart, const [AppColors.purple500, AppColors.purple700]);
        sparkle(canvas, p(0.83, 0.16), 0.09 * s);
      case ClayGlyph.folder:
        final back = Path()
          ..addRRect(RRect.fromRectAndRadius(r(0.10, 0.16, 0.48, 0.34), Radius.circular(0.07 * s)))
          ..addRRect(RRect.fromRectAndRadius(r(0.10, 0.24, 0.90, 0.84), Radius.circular(0.09 * s)));
        clay(canvas, back, const [AppColors.gold500, AppColors.gold700]);
        final paper = Paint()
          ..shader = const LinearGradient(colors: [AppColors.surface, AppColors.slate200]).createShader(r(0.2, 0.3, 0.8, 0.6));
        canvas.drawRRect(RRect.fromRectAndRadius(r(0.20, 0.30, 0.80, 0.62), Radius.circular(0.05 * s)), paper);
        final front = Path()
          ..moveTo(0.14 * s, 0.42 * s)
          ..lineTo(0.86 * s, 0.42 * s)
          ..quadraticBezierTo(0.93 * s, 0.42 * s, 0.92 * s, 0.50 * s)
          ..lineTo(0.88 * s, 0.80 * s)
          ..quadraticBezierTo(0.87 * s, 0.88 * s, 0.79 * s, 0.88 * s)
          ..lineTo(0.21 * s, 0.88 * s)
          ..quadraticBezierTo(0.13 * s, 0.88 * s, 0.12 * s, 0.80 * s)
          ..lineTo(0.08 * s, 0.50 * s)
          ..quadraticBezierTo(0.07 * s, 0.42 * s, 0.14 * s, 0.42 * s)
          ..close();
        clay(canvas, front, const [AppColors.gold300, AppColors.gold500]);
      case ClayGlyph.pin:
        floorShadow(canvas, r(0.30, 0.86, 0.70, 0.95));
        final pin = Path.combine(
          PathOperation.union,
          Path()..addOval(Rect.fromCircle(center: p(0.5, 0.38), radius: 0.28 * s)),
          Path()
            ..moveTo(0.27 * s, 0.50 * s)
            ..quadraticBezierTo(0.40 * s, 0.70 * s, 0.50 * s, 0.88 * s)
            ..quadraticBezierTo(0.60 * s, 0.70 * s, 0.73 * s, 0.50 * s)
            ..close(),
        );
        clay(canvas, pin, const [AppColors.brand400, AppColors.navy800]);
        clay(canvas, Path()..addOval(Rect.fromCircle(center: p(0.5, 0.38), radius: 0.12 * s)), const [AppColors.gold300, AppColors.gold600], shadow: false);
      case ClayGlyph.megaphone:
        final arcs = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.055 * s
          ..color = AppColors.gold400;
        canvas.drawArc(Rect.fromCircle(center: p(0.70, 0.50), radius: 0.17 * s), -0.7, 1.4, false, arcs);
        canvas.drawArc(Rect.fromCircle(center: p(0.70, 0.50), radius: 0.26 * s), -0.6, 1.2, false, arcs);
        clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(0.28, 0.56, 0.40, 0.84), Radius.circular(0.05 * s))), const [AppColors.gold300, AppColors.gold600]);
        final body = Path()
          ..moveTo(0.16 * s, 0.40 * s)
          ..lineTo(0.60 * s, 0.18 * s)
          ..lineTo(0.60 * s, 0.82 * s)
          ..lineTo(0.16 * s, 0.60 * s)
          ..close();
        clay(canvas, body, const [AppColors.brand500, AppColors.navy800]);
        clay(canvas, Path()..addOval(r(0.53, 0.17, 0.68, 0.83)), const [AppColors.brand300, AppColors.brand600], shadow: false);
        clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(0.08, 0.38, 0.20, 0.62), Radius.circular(0.04 * s))), const [AppColors.gold300, AppColors.gold600], shadow: false);
      case ClayGlyph.building:
        floorShadow(canvas, r(0.12, 0.86, 0.88, 0.95));
        final flagPole = Paint()
          ..color = AppColors.slate500
          ..strokeWidth = 0.025 * s;
        canvas.drawLine(p(0.5, 0.18), p(0.5, 0.04), flagPole);
        canvas.drawPath(
          Path()
            ..moveTo(0.51 * s, 0.04 * s)
            ..lineTo(0.68 * s, 0.08 * s)
            ..lineTo(0.51 * s, 0.13 * s)
            ..close(),
          Paint()..color = AppColors.gold400,
        );
        clay(
          canvas,
          Path()
            ..moveTo(0.10 * s, 0.40 * s)
            ..lineTo(0.50 * s, 0.17 * s)
            ..lineTo(0.90 * s, 0.40 * s)
            ..close(),
          const [AppColors.brand500, AppColors.navy800],
        );
        clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(0.14, 0.38, 0.86, 0.46), Radius.circular(0.02 * s))), const [AppColors.surface, AppColors.slate300], shadow: false);
        for (final x in [0.19, 0.36, 0.53, 0.70]) {
          clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(x, 0.47, x + 0.11, 0.80), Radius.circular(0.03 * s))), const [AppColors.surface, AppColors.slate300], shadow: false);
        }
        clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(0.10, 0.79, 0.90, 0.89), Radius.circular(0.03 * s))), const [AppColors.slate100, AppColors.slate400], shadow: false);
      case ClayGlyph.shield:
        final shield = Path()
          ..moveTo(0.50 * s, 0.09 * s)
          ..lineTo(0.84 * s, 0.22 * s)
          ..lineTo(0.84 * s, 0.48 * s)
          ..cubicTo(0.84 * s, 0.70 * s, 0.68 * s, 0.84 * s, 0.50 * s, 0.92 * s)
          ..cubicTo(0.32 * s, 0.84 * s, 0.16 * s, 0.70 * s, 0.16 * s, 0.48 * s)
          ..lineTo(0.16 * s, 0.22 * s)
          ..close();
        clay(canvas, shield, const [AppColors.rose500, AppColors.rose700]);
        final cross = Paint()..color = AppColors.surface.withValues(alpha: 0.95);
        canvas.drawRRect(RRect.fromRectAndRadius(r(0.44, 0.32, 0.56, 0.70), Radius.circular(0.03 * s)), cross);
        canvas.drawRRect(RRect.fromRectAndRadius(r(0.31, 0.45, 0.69, 0.57), Radius.circular(0.03 * s)), cross);
      case ClayGlyph.card:
        clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(0.08, 0.22, 0.92, 0.80), Radius.circular(0.10 * s))), const [AppColors.gold300, AppColors.gold600]);
        canvas.drawRect(r(0.08, 0.34, 0.92, 0.45), Paint()..color = AppColors.navy800);
        canvas.drawRRect(RRect.fromRectAndRadius(r(0.18, 0.58, 0.44, 0.68), Radius.circular(0.03 * s)), Paint()..color = AppColors.surface.withValues(alpha: 0.9));
      case ClayGlyph.bell:
        final bell = Path()
          ..moveTo(0.50 * s, 0.14 * s)
          ..cubicTo(0.30 * s, 0.14 * s, 0.26 * s, 0.32 * s, 0.26 * s, 0.48 * s)
          ..lineTo(0.18 * s, 0.70 * s)
          ..lineTo(0.82 * s, 0.70 * s)
          ..lineTo(0.74 * s, 0.48 * s)
          ..cubicTo(0.74 * s, 0.32 * s, 0.70 * s, 0.14 * s, 0.50 * s, 0.14 * s)
          ..close();
        clay(canvas, bell, const [AppColors.gold300, AppColors.gold600]);
        clay(canvas, Path()..addOval(Rect.fromCircle(center: p(0.5, 0.78), radius: 0.08 * s)), const [AppColors.gold400, AppColors.gold700], shadow: false);
      case ClayGlyph.check:
        clay(canvas, Path()..addOval(r(0.10, 0.10, 0.90, 0.90)), const [AppColors.green500, AppColors.emerald700]);
        canvas.drawPath(
          Path()
            ..moveTo(0.31 * s, 0.51 * s)
            ..lineTo(0.45 * s, 0.65 * s)
            ..lineTo(0.70 * s, 0.37 * s),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.09 * s
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = AppColors.surface,
        );
        sparkle(canvas, p(0.86, 0.14), 0.08 * s);
      case ClayGlyph.warning:
        clay(canvas, Path()..addOval(r(0.10, 0.10, 0.90, 0.90)), const [AppColors.gold300, AppColors.gold600]);
        final mark = Paint()..color = AppColors.navy900;
        canvas.drawRRect(RRect.fromRectAndRadius(r(0.455, 0.26, 0.545, 0.58), Radius.circular(0.045 * s)), mark);
        canvas.drawCircle(p(0.5, 0.70), 0.055 * s, mark);
      case ClayGlyph.info:
        clay(canvas, Path()..addOval(r(0.10, 0.10, 0.90, 0.90)), const [AppColors.brand500, AppColors.navy800]);
        final mark = Paint()..color = AppColors.surface;
        canvas.drawCircle(p(0.5, 0.31), 0.055 * s, mark);
        canvas.drawRRect(RRect.fromRectAndRadius(r(0.455, 0.42, 0.545, 0.74), Radius.circular(0.045 * s)), mark);
      case ClayGlyph.camera:
        clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(0.34, 0.20, 0.60, 0.34), Radius.circular(0.04 * s))), const [AppColors.brand400, AppColors.navy700]);
        clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(0.10, 0.28, 0.90, 0.82), Radius.circular(0.12 * s))), const [AppColors.brand500, AppColors.navy800]);
        clay(canvas, Path()..addOval(Rect.fromCircle(center: p(0.5, 0.55), radius: 0.19 * s)), const [AppColors.surface, AppColors.slate300], shadow: false);
        clay(canvas, Path()..addOval(Rect.fromCircle(center: p(0.5, 0.55), radius: 0.12 * s)), const [AppColors.gold300, AppColors.gold600], shadow: false);
        canvas.drawCircle(p(0.77, 0.38), 0.035 * s, Paint()..color = AppColors.gold300);
      case ClayGlyph.box:
        floorShadow(canvas, r(0.14, 0.86, 0.86, 0.96));
        final body = Path()
          ..moveTo(0.16 * s, 0.42 * s)
          ..lineTo(0.84 * s, 0.42 * s)
          ..lineTo(0.80 * s, 0.86 * s)
          ..lineTo(0.20 * s, 0.86 * s)
          ..close();
        clay(canvas, body, const [AppColors.brand300, AppColors.brand600]);
        final flapL = Path()
          ..moveTo(0.16 * s, 0.42 * s)
          ..lineTo(0.50 * s, 0.42 * s)
          ..lineTo(0.36 * s, 0.24 * s)
          ..lineTo(0.04 * s, 0.28 * s)
          ..close();
        clay(canvas, flapL, const [AppColors.brand200, AppColors.brand400], shadow: false);
        final flapR = Path()
          ..moveTo(0.50 * s, 0.42 * s)
          ..lineTo(0.84 * s, 0.42 * s)
          ..lineTo(0.96 * s, 0.28 * s)
          ..lineTo(0.64 * s, 0.24 * s)
          ..close();
        clay(canvas, flapR, const [AppColors.brand200, AppColors.brand400], shadow: false);
        canvas.drawRRect(RRect.fromRectAndRadius(r(0.38, 0.54, 0.62, 0.60), Radius.circular(0.03 * s)), Paint()..color = AppColors.surface.withValues(alpha: 0.85));
        sparkle(canvas, p(0.82, 0.14), 0.07 * s);
      case ClayGlyph.search:
        final handle = Paint()
          ..strokeWidth = 0.13 * s
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(colors: [AppColors.gold300, AppColors.gold600]).createShader(r(0.55, 0.55, 0.9, 0.9));
        canvas.drawLine(p(0.62, 0.62), p(0.84, 0.84), handle);
        clay(canvas, Path()..addOval(Rect.fromCircle(center: p(0.42, 0.42), radius: 0.30 * s)), const [AppColors.brand500, AppColors.navy800]);
        clay(canvas, Path()..addOval(Rect.fromCircle(center: p(0.42, 0.42), radius: 0.19 * s)), const [AppColors.brand100, AppColors.brand300], shadow: false);
      case ClayGlyph.calendar:
        clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(0.12, 0.18, 0.88, 0.88), Radius.circular(0.12 * s))), const [AppColors.surface, AppColors.slate300]);
        canvas.save();
        canvas.clipRRect(RRect.fromRectAndRadius(r(0.12, 0.18, 0.88, 0.88), Radius.circular(0.12 * s)));
        clay(canvas, Path()..addRect(r(0.12, 0.18, 0.88, 0.40)), const [AppColors.brand500, AppColors.navy800], shadow: false);
        canvas.restore();
        for (final x in [0.32, 0.68]) {
          clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(x - 0.04, 0.10, x + 0.04, 0.28), Radius.circular(0.04 * s))), const [AppColors.gold300, AppColors.gold600], shadow: false);
        }
        final dot = Paint()..color = AppColors.navy700.withValues(alpha: 0.55);
        for (final y in [0.54, 0.70]) {
          for (final x in [0.30, 0.46, 0.62]) {
            canvas.drawRRect(RRect.fromRectAndRadius(r(x, y, x + 0.09, y + 0.09), Radius.circular(0.02 * s)), dot);
          }
        }
        clay(canvas, Path()..addRRect(RRect.fromRectAndRadius(r(0.62, 0.70, 0.71, 0.79), Radius.circular(0.02 * s))), const [AppColors.gold300, AppColors.gold600], shadow: false);
      case ClayGlyph.error:
        clay(canvas, Path()..addOval(r(0.10, 0.10, 0.90, 0.90)), const [AppColors.rose500, AppColors.rose700]);
        final mark = Paint()..color = AppColors.surface;
        canvas.drawRRect(RRect.fromRectAndRadius(r(0.455, 0.26, 0.545, 0.58), Radius.circular(0.045 * s)), mark);
        canvas.drawCircle(p(0.5, 0.70), 0.055 * s, mark);
      case ClayGlyph.person:
        clay(canvas, Path()..addOval(Rect.fromCircle(center: p(0.5, 0.32), radius: 0.18 * s)), const [AppColors.gold300, AppColors.gold600]);
        final torso = Path()
          ..moveTo(0.16 * s, 0.88 * s)
          ..cubicTo(0.16 * s, 0.62 * s, 0.32 * s, 0.54 * s, 0.50 * s, 0.54 * s)
          ..cubicTo(0.68 * s, 0.54 * s, 0.84 * s, 0.62 * s, 0.84 * s, 0.88 * s)
          ..close();
        clay(canvas, torso, const [AppColors.brand500, AppColors.navy800]);
    }
  }

  @override
  bool shouldRepaint(_ClayIconPainter old) => old.glyph != glyph;
}

/// Fills [path] as a clay object: drop shadow, gradient body, an inner shade
/// along the lower-right edge and a soft highlight at the upper-left.
void clay(Canvas canvas, Path path, List<Color> colors, {bool shadow = true}) {
  final b = path.getBounds();
  final k = b.shortestSide;
  if (shadow) {
    canvas.drawPath(
      path.shift(Offset(k * 0.04, k * 0.10)),
      Paint()
        ..color = colors.last.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, k * 0.10),
    );
  }
  canvas.drawPath(
    path,
    Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors).createShader(b),
  );
  canvas.save();
  canvas.clipPath(path);
  canvas.drawPath(
    path.shift(Offset(-k * 0.08, -k * 0.08)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = k * 0.22
      ..color = colors.last.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, k * 0.08),
  );
  final glow = Rect.fromLTWH(b.left + b.width * 0.06, b.top + b.height * 0.04, b.width * 0.62, b.height * 0.42);
  canvas.drawOval(
    glow,
    Paint()
      ..shader = RadialGradient(
        colors: [AppColors.surface.withValues(alpha: 0.55), AppColors.surface.withValues(alpha: 0)],
      ).createShader(glow),
  );
  canvas.restore();
}

/// A four-pointed gold sparkle.
void sparkle(Canvas canvas, Offset c, double r) {
  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + r * 0.18, c.dy - r * 0.18, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + r * 0.18, c.dy + r * 0.18, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - r * 0.18, c.dy + r * 0.18, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - r * 0.18, c.dy - r * 0.18, c.dx, c.dy - r)
    ..close();
  canvas.drawPath(path, Paint()..color = AppColors.gold400);
}

/// The soft contact shadow an object casts on the ground.
void floorShadow(Canvas canvas, Rect r) {
  canvas.drawOval(
    r,
    Paint()
      ..color = AppColors.navy900.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.height * 0.6),
  );
}

// ─── Scenes ────────────────────────────────────────────────────────────────

/// The design's opening scene: a deep navy sky, a gold sun with rays and
/// glow, rolling navy hills, a sweeping gold ribbon and (optionally) the
/// municipal hall, all as clay. [sun] and [ground] are fractions of the
/// height; [hall] places the building's base centre.
class EsperanzaScenePainter extends CustomPainter {
  final double sun;
  final double ground;
  final bool showHall;
  final double hallWidth;
  final double progress;

  /// Horizontal centre of the hall (and of the sun, unless [sunX] is set),
  /// as a fraction of the width.
  final double focusX;
  final double? sunX;
  final double sunScale;

  const EsperanzaScenePainter({
    this.focusX = 0.5,
    this.sunX,
    this.sunScale = 1,
    this.sun = 0.22,
    this.ground = 0.78,
    this.showHall = true,
    this.hallWidth = 0.62,
    this.progress = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navy950, AppColors.navy800, AppColors.brand800],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    // Two soft swells across the sky, as in the design's opening screen.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.10)
        ..cubicTo(w * 0.30, h * 0.02, w * 0.45, h * 0.40, w * 0.05, h * 0.62)
        ..lineTo(0, h * 0.62)
        ..close(),
      Paint()..color = AppColors.brand700.withValues(alpha: 0.28),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, h * 0.30)
        ..cubicTo(w * 0.70, h * 0.36, w * 0.62, h * 0.60, w, h * 0.70)
        ..close(),
      Paint()..color = AppColors.brand600.withValues(alpha: 0.18),
    );

    // Sun: glow, rays, then the disc.
    final sunC = Offset(w * (sunX ?? focusX), h * sun);
    final sunR = math.min(w * 0.12, h * 0.11) * sunScale;
    final glow = Rect.fromCircle(center: sunC, radius: sunR * 3.4);
    canvas.drawCircle(
      sunC,
      sunR * 3.4,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.gold300.withValues(alpha: 0.30 * progress), AppColors.brand500.withValues(alpha: 0.10 * progress), AppColors.navy900.withValues(alpha: 0)],
          stops: const [0, 0.45, 1],
        ).createShader(glow),
    );
    final ray = Paint()
      ..color = AppColors.gold400.withValues(alpha: progress)
      ..strokeWidth = sunR * 0.28
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final a = math.pi + (i + 0.5) * math.pi / 7;
      final from = sunC + Offset(math.cos(a), math.sin(a)) * sunR * 1.45;
      final to = sunC + Offset(math.cos(a), math.sin(a)) * sunR * (1.45 + 0.55 * progress);
      canvas.drawLine(from, to, ray);
    }
    clay(canvas, Path()..addOval(Rect.fromCircle(center: sunC, radius: sunR)), const [AppColors.gold300, AppColors.gold500]);

    // Hills behind the hall.
    final gy = h * ground;
    final back = Path()
      ..moveTo(0, gy - h * 0.10)
      ..cubicTo(w * 0.25, gy - h * 0.20, w * 0.55, gy - h * 0.02, w, gy - h * 0.14)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.navy700, AppColors.navy900]).createShader(rect));

    if (showHall) {
      paintMunicipalHall(canvas, Offset(w * focusX, gy + h * 0.02), w * hallWidth);
    }

    // The gold ribbon sweeping across the foreground.
    final ribbon = Path()
      ..moveTo(0, gy - h * 0.02)
      ..cubicTo(w * 0.30, gy + h * 0.10, w * 0.55, gy - h * 0.06, w, gy + h * 0.04)
      ..lineTo(w, gy + h * 0.10)
      ..cubicTo(w * 0.55, gy + h * 0.02, w * 0.30, gy + h * 0.18, 0, gy + h * 0.06)
      ..close();
    clay(canvas, ribbon, const [AppColors.gold300, AppColors.gold500], shadow: true);

    final front = Path()
      ..moveTo(0, gy + h * 0.06)
      ..cubicTo(w * 0.30, gy + h * 0.18, w * 0.55, gy + h * 0.02, w, gy + h * 0.10)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.brand700, AppColors.navy800]).createShader(rect));
  }

  @override
  bool shouldRepaint(EsperanzaScenePainter old) =>
      old.focusX != focusX || old.sunX != sunX || old.sunScale != sunScale || old.sun != sun || old.ground != ground || old.showHall != showHall || old.progress != progress || old.hallWidth != hallWidth;
}

/// The municipal hall as a clay model: steps, white columns, a navy
/// pediment, a gold-domed cupola with the flag, and two round trees.
/// [base] is the centre of its lowest step; [width] its overall width.
void paintMunicipalHall(Canvas canvas, Offset base, double width) {
  final u = width / 100;
  Rect r(double l, double t, double rr, double b) => Rect.fromLTRB(base.dx + l * u, base.dy + t * u, base.dx + rr * u, base.dy + b * u);
  RRect rr(double l, double t, double ri, double b, double rad) => RRect.fromRectAndRadius(r(l, t, ri, b), Radius.circular(rad * u));
  const white = [AppColors.surface, AppColors.slate300];

  floorShadow(canvas, r(-52, -6, 52, 6));

  // Trees either side.
  for (final x in [-44.0, 44.0]) {
    clay(canvas, Path()..addRRect(rr(x - 1.5, -14, x + 1.5, 0, 1)), const [AppColors.amber700, AppColors.orange700], shadow: false);
    clay(canvas, Path()..addOval(Rect.fromCircle(center: Offset(base.dx + x * u, base.dy - 20 * u), radius: 10 * u)), const [AppColors.green500, AppColors.green700]);
  }

  // Steps and body.
  clay(canvas, Path()..addRRect(rr(-40, -6, 40, 0, 1.5)), const [AppColors.slate100, AppColors.slate400]);
  clay(canvas, Path()..addRRect(rr(-36, -11, 36, -5, 1.5)), white, shadow: false);
  clay(canvas, Path()..addRRect(rr(-34, -42, 34, -10, 2)), const [AppColors.slate50, AppColors.slate300]);
  for (final x in [-28.0, -16.0, -4.0, 8.0, 20.0]) {
    clay(canvas, Path()..addRRect(rr(x, -40, x + 6, -11, 2)), white, shadow: false);
  }
  // Door.
  clay(canvas, Path()..addRRect(rr(-3.5, -24, 3.5, -11, 3)), const [AppColors.brand500, AppColors.navy800], shadow: false);

  // Architrave and pediment.
  clay(canvas, Path()..addRRect(rr(-38, -47, 38, -41, 1.5)), white);
  final ped = Path()
    ..moveTo(base.dx - 40 * u, base.dy - 47 * u)
    ..lineTo(base.dx, base.dy - 62 * u)
    ..lineTo(base.dx + 40 * u, base.dy - 47 * u)
    ..close();
  clay(canvas, ped, const [AppColors.brand500, AppColors.navy800]);

  // Cupola, gold dome and flag.
  clay(canvas, Path()..addRRect(rr(-8, -72, 8, -58, 2)), white);
  clay(canvas, Path()..addArc(r(-9, -82, 9, -64), math.pi, math.pi), const [AppColors.gold300, AppColors.gold600]);
  final pole = Paint()
    ..color = AppColors.slate300
    ..strokeWidth = 1.2 * u;
  canvas.drawLine(Offset(base.dx, base.dy - 81 * u), Offset(base.dx, base.dy - 96 * u), pole);
  final flag = Path()
    ..moveTo(base.dx + 0.6 * u, base.dy - 96 * u)
    ..quadraticBezierTo(base.dx + 8 * u, base.dy - 98 * u, base.dx + 14 * u, base.dy - 93 * u)
    ..quadraticBezierTo(base.dx + 8 * u, base.dy - 91 * u, base.dx + 0.6 * u, base.dy - 89 * u)
    ..close();
  clay(canvas, flag, const [AppColors.surface, AppColors.brand200], shadow: false);
}

/// The page ground behind every screen: quiet by design (2026-10
/// refinement). Light blue-gray (slate-100) with only a breath of brand blue
/// at the top. It used to carry drifting gold, blue, purple and sky blobs,
/// and with translucent cards over it everything blended together; strong
/// gradients now live only in the branded areas (splash, onboarding, the
/// Home hero, banners, the wizard header).
class SoftBackdropPainter extends CustomPainter {
  const SoftBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.slate100);
    final top = Rect.fromLTWH(0, 0, size.width, size.height * 0.40);
    canvas.drawRect(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.brand50, AppColors.brand50.withValues(alpha: 0)],
        ).createShader(top),
    );
  }

  @override
  bool shouldRepaint(SoftBackdropPainter old) => false;
}
