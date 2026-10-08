import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, gold, navy }

enum AppButtonSize { sm, md, lg }

/// The app's one button. Every screen uses this instead of raw
/// ElevatedButton so styling stays centralized (Section 2 of the alignment
/// doc).
///
/// The 2026-10 design: pill-shaped, gently raised (a neumorphic pair of
/// shadows — dark below-right, light above-left — and a clay highlight on
/// the filled ones), pressing in when touched.
///
/// - [AppButtonVariant.primary] / [AppButtonVariant.gold]: gold with navy
///   text, the main action. A module accent (Tulong's purple) overrides it.
/// - [AppButtonVariant.navy]: navy with white text, the strong secondary.
/// - [AppButtonVariant.secondary]: the outline button — light, navy edge,
///   navy text (Back, Cancel, Upload).
/// - [AppButtonVariant.danger]: red with white text, for destructive acts.
/// - [AppButtonVariant.ghost]: text only.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool iconTrailing;
  final bool loading;
  final bool fullWidth;

  /// Overrides the primary fill for a module with its own colour (Tulong's
  /// purple). Null keeps the standard gold. Must carry white text at AA,
  /// which every module accent does.
  final Color? accent;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconTrailing = false,
    this.loading = false,
    this.fullWidth = false,
    this.accent,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  EdgeInsets get _padding => switch (widget.size) {
    AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    AppButtonSize.md => const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
    AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
  };

  /// Minimum heights from the design standard (AppSizes, web `--size-btn-*`).
  /// Padding plus line height already reaches them today (38/44/51 measured
  /// in widget tests), but that sum depends on the font's metrics; the floor
  /// makes the 44pt touch target a guarantee rather than a coincidence.
  double get _minHeight => switch (widget.size) {
    AppButtonSize.sm => AppSizes.buttonHeightCompact,
    AppButtonSize.md => AppSizes.buttonHeight,
    AppButtonSize.lg => AppSizes.buttonHeightLg,
  };

  double get _fontSize => widget.size == AppButtonSize.lg
      ? AppTextSize.card
      : (widget.size == AppButtonSize.sm ? AppTextSize.helper : AppTextSize.body);

  _VariantStyle get _colors {
    final accent = widget.accent;
    return switch (widget.variant) {
      AppButtonVariant.primary => _VariantStyle(
        fill: accent != null
            ? [Color.lerp(accent, AppColors.surface, 0.12)!, accent]
            : const [AppColors.gold300, AppColors.gold400, AppColors.gold500],
        foreground: accent != null ? AppColors.surface : AppColors.navy950,
        glow: accent ?? AppColors.gold400,
        clay: true,
      ),
      AppButtonVariant.gold => const _VariantStyle(
        fill: [AppColors.gold300, AppColors.gold400, AppColors.gold500],
        foreground: AppColors.navy950,
        glow: AppColors.gold400,
        clay: true,
      ),
      AppButtonVariant.navy => const _VariantStyle(
        fill: [AppColors.navy600, AppColors.navy800],
        foreground: AppColors.surface,
        glow: AppColors.navy800,
        clay: true,
      ),
      AppButtonVariant.secondary => _VariantStyle(
        fill: [AppColors.surface.withValues(alpha: 0.95), AppColors.slate100.withValues(alpha: 0.95)],
        foreground: AppColors.navy800,
        border: AppColors.navy700.withValues(alpha: 0.45),
        neu: true,
      ),
      AppButtonVariant.ghost => const _VariantStyle(fill: [AppColors.clear, AppColors.clear], foreground: AppColors.slate600),
      AppButtonVariant.danger => const _VariantStyle(
        fill: [AppColors.rose500, AppColors.rose600],
        foreground: AppColors.surface,
        glow: AppColors.rose600,
        clay: true,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final enabled = !widget.loading && widget.onPressed != null;
    final down = _pressed && enabled;
    final radius = BorderRadius.circular(AppRadius.full);

    final label = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: c.foreground)),
          const SizedBox(width: AppSpacing.sm),
        ] else if (widget.icon != null && !widget.iconTrailing) ...[
          Icon(widget.icon, size: widget.size == AppButtonSize.lg ? 18 : 16, color: c.foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: AppTypography.button.copyWith(color: c.foreground, fontSize: _fontSize, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!widget.loading && widget.icon != null && widget.iconTrailing) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(widget.icon, size: widget.size == AppButtonSize.lg ? 18 : 16, color: c.foreground),
        ],
      ],
    );

    // Raised at rest, pressed in while touched: the shadows tighten and the
    // whole button settles a little.
    final shadows = <BoxShadow>[
      if (enabled && c.glow != null)
        BoxShadow(
          color: c.glow!.withValues(alpha: down ? 0.20 : 0.38),
          blurRadius: down ? 6 : 16,
          offset: Offset(0, down ? 2 : 7),
          spreadRadius: -4,
        ),
      if (enabled && (c.neu || c.clay))
        BoxShadow(
          color: AppColors.surface.withValues(alpha: down ? 0.4 : 0.85),
          blurRadius: down ? 4 : 8,
          offset: Offset(down ? -1 : -3, down ? -1 : -3),
        ),
      if (enabled && c.neu)
        BoxShadow(
          color: AppColors.navy800.withValues(alpha: down ? 0.06 : 0.14),
          blurRadius: down ? 4 : 12,
          offset: Offset(down ? 1 : 3, down ? 2 : 5),
        ),
    ];

    // Announced as a button, with its label, as one node.
    //
    // `InkWell` contributes a tap action and nothing else, so until 2026-08-30
    // every AppButton in the app reached a screen reader as a piece of text
    // that happened to be tappable — never as a button, and never with its
    // enabled/disabled state. `MergeSemantics` is what puts the flag and the
    // label on the same node rather than two siblings.
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        // A disabled button looked exactly like an active one, so Resubmit
        // seemed to do nothing when tapped (QA run 2026-10-04). Loading keeps
        // full strength: its spinner already says why.
        child: Opacity(
          opacity: widget.onPressed == null && !widget.loading ? 0.45 : 1,
          child: AnimatedScale(
            scale: down ? 0.97 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: widget.fullWidth ? double.infinity : null,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.fill),
                border: c.border != null ? Border.all(color: c.border!, width: 1.3) : null,
                boxShadow: shadows,
              ),
              // The clay sheen across the upper half of a filled button.
              foregroundDecoration: c.clay
                  ? BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [AppColors.surface.withValues(alpha: down ? 0.10 : 0.30), AppColors.surface.withValues(alpha: 0)],
                      ),
                    )
                  : null,
              child: Material(
                color: AppColors.clear,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: widget.loading ? null : widget.onPressed,
                  onHighlightChanged: (v) => setState(() => _pressed = v),
                  child: Padding(
                    padding: _padding,
                    // Row centres its children vertically, so a taller floor
                    // keeps the label centred without changing the width.
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: _minHeight - _padding.vertical),
                      child: label,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantStyle {
  final List<Color> fill;
  final Color foreground;
  final Color? border;
  final Color? glow;

  /// A filled button with a clay sheen.
  final bool clay;

  /// A light button with a neumorphic shadow pair.
  final bool neu;

  const _VariantStyle({
    required this.fill,
    required this.foreground,
    this.border,
    this.glow,
    this.clay = false,
    this.neu = false,
  });
}
