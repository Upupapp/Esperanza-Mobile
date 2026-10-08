import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'esperanza_nav_motion.dart';

/// The central "+" launcher — direct port of Servana's `ServanaBookAction`.
/// Same press choreography (scale down, overshoot past 1.0, settle) and the
/// same rule for when [onPressed] fires: after the press animation BEGINS
/// (so whatever it opens starts appearing while the button is still
/// settling), guarded by `mounted` so it can never fire for a widget
/// disposed mid-animation.
///
/// [activeIcon]/[activeAccent] are Esperanza's own addition to Servana's
/// source: Servana's Book action never renders as selected, because Servana
/// has no in-app destination "beneath" it that stays reachable while its
/// sheet is open. Esperanza's "+" launches Dokyu/Tulong, which the citizen
/// can navigate while the launcher's affordance should still read as the
/// current context — so when non-null, this circle swaps from the resting
/// gold "+" to that destination's own icon/color, crossfading exactly like
/// a tab's active bubble (see EsperanzaActiveBubble) swaps icons, rather
/// than just gaining a ring. Driven by the root shell, not by this widget's
/// own press state.
class EsperanzaCenterAction extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData? activeIcon;
  final Color? activeAccent;

  const EsperanzaCenterAction({super.key, required this.onPressed, this.activeIcon, this.activeAccent});

  @override
  State<EsperanzaCenterAction> createState() => _EsperanzaCenterActionState();
}

class _EsperanzaCenterActionState extends State<EsperanzaCenterAction> {
  double _scale = 1;

  Future<void> _run() async {
    final reduced = EsperanzaNavMotion.reduced(context);
    if (!reduced) {
      setState(() => _scale = EsperanzaNavMotion.pressScale);
      await Future<void>.delayed(EsperanzaNavMotion.press);
      if (!mounted) return;
      setState(() => _scale = EsperanzaNavMotion.releaseScale);
      await Future<void>.delayed(EsperanzaNavMotion.pressRelease);
      if (!mounted) return;
      setState(() => _scale = 1);
    }
    if (!mounted) return;
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeIcon != null;
    // Navy with a gold plus (2026-10 refresh): the active tab's bubble is
    // gold now, and two gold circles side by side read as one control.
    final fill = widget.activeAccent ?? AppColors.navy800;
    final reduced = EsperanzaNavMotion.reduced(context);

    return Semantics(
      button: true,
      label: active ? 'Dokyu and Tulong launcher, active' : 'Open Dokyu and Tulong',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _run,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _scale,
          duration: EsperanzaNavMotion.press,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: EsperanzaNavMotion.press,
            width: EsperanzaNavMotion.centerDiameter,
            height: EsperanzaNavMotion.centerDiameter,
            // Clay (2026-10 design): a deep navy ball lit from the top-left
            // (or the open module's own colour), with a soft highlight.
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.activeAccent != null
                    ? [Color.lerp(fill, AppColors.surface, 0.25)!, fill]
                    : const [AppColors.brand700, AppColors.navy800, AppColors.navy950],
              ),
              border: Border.all(color: AppColors.surface, width: 3),
              // Floating above the bar: a wide soft lift and a tight contact
              // shadow, as a physical control. Pressed, the lift shrinks, so
              // it sinks toward the bar as well as scaling down.
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy900.withValues(alpha: _scale < 1 ? 0.26 : 0.38),
                  blurRadius: _scale < 1 ? 10 : 20,
                  offset: Offset(0, _scale < 1 ? 4 : 10),
                  spreadRadius: -3,
                ),
                BoxShadow(color: AppColors.navy900.withValues(alpha: 0.20), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            // Clay shading: a highlight pooled at the upper-left, an inner
            // shade deepening to the lower-right — slightly inflated.
            foregroundDecoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.40, -0.50),
                radius: 0.95,
                colors: [
                  AppColors.surface.withValues(alpha: 0.34),
                  AppColors.surface.withValues(alpha: 0),
                  AppColors.navy950.withValues(alpha: 0.35),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: reduced ? const Duration(milliseconds: 1) : EsperanzaNavMotion.selection,
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Icon(
                  widget.activeIcon ?? Icons.add_rounded,
                  key: ValueKey(widget.activeIcon ?? Icons.add_rounded),
                  color: widget.activeAccent != null ? AppColors.surface : AppColors.gold400,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
