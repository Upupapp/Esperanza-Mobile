import 'package:flutter/widgets.dart';
import '../theme/app_motion.dart';

/// Motion + geometry constants for [EsperanzaCurvedNavBar] — the direct
/// Esperanza port of the Servana Client App's curved main navigation (see
/// `design_reference/ServanaClientAPP-main/ServanaClientAPP-main/lib/common/
/// presentation/navigation/servana_nav_motion.dart`, the actual source this
/// was copied from, not a screenshot or a general impression of it).
/// Durations/curves/geometry are Servana's own values verbatim — only the
/// resolved-through-reduced-motion plumbing was rewired onto Esperanza's own
/// [AppMotion] instead of Servana's `motion_tokens.dart`, since duplicating
/// that whole token file just for one boolean would be its own new design
/// system. Collected in one place, same as the source, so every constant the
/// navbar/center-action tuning touches is auditable together.
abstract final class EsperanzaNavMotion {
  // ── Tab-selection movement ─────────────────────────────────────────────

  /// Travel time for the active bubble and the cradle beneath it.
  static const Duration selection = Duration(milliseconds: 320);

  /// Ease-out dominant: the bubble leaves immediately and settles gently.
  static const Curve selectionCurve = Curves.easeOutCubic;

  // ── Page movement ───────────────────────────────────────────────────────

  static const Duration page = Duration(milliseconds: 260);
  static const Curve pageCurve = Curves.easeOutCubic;
  static const double pageRiseOffset = 8;
  static const double pageStartScale = 0.985;

  // ── Central action press ───────────────────────────────────────────────

  static const Duration press = Duration(milliseconds: 90);
  static const Duration pressRelease = Duration(milliseconds: 70);
  static const double pressScale = 0.94;
  static const double releaseScale = 1.03;

  // ── Badge ───────────────────────────────────────────────────────────────

  static const Duration badge = Duration(milliseconds: 150);

  // ── Geometry ────────────────────────────────────────────────────────────

  /// Bar height before the device's bottom inset.
  static const double barHeight = 72;

  /// Width of the active tab's gold capsule. It sits inside the bar, around
  /// the icon (2026-10-09: it used to float 12pt above the bar as a ball and,
  /// under Emergency, hung past the pill's rounded end).
  static const double bubbleDiameter = 52;

  /// Height of that capsule: the icon plus 4pt above and below.
  static const double bubbleHeight = 32;

  /// Space between the icon row and the label.
  static const double labelGap = 4;

  /// Inset of the tabs from the screen edges, so the outer labels
  /// ("Emergency") stay clear of the pill's rounded ends: at the labels'
  /// height the 30pt end curves in ~13pt past the 8pt side margin.
  static const double tabInset = 22;

  /// The "+" launcher's menu tiles.
  static const double launcherTileDiameter = 52;

  static const double iconSize = 24;

  /// Central action ("+") diameter — larger than a tab bubble so it reads
  /// as a distinct affordance rather than a sixth destination.
  static const double centerDiameter = 56;

  /// Resolved travel time — clamped short under reduced motion, which
  /// disables the travelling character without touching haptics.
  static Duration selectionFor(BuildContext context) => AppMotion.resolve(context, selection);

  static Duration pageFor(BuildContext context) => AppMotion.resolve(context, page);

  static bool reduced(BuildContext context) => AppMotion.reducedMotion(context);
}
