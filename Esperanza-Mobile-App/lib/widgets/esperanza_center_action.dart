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
    final fill = widget.activeAccent ?? AppColors.gold500;
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
          child: Container(
            width: EsperanzaNavMotion.centerDiameter,
            height: EsperanzaNavMotion.centerDiameter,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 3),
              boxShadow: [
                BoxShadow(color: fill.withValues(alpha: 0.34), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: reduced ? const Duration(milliseconds: 1) : EsperanzaNavMotion.selection,
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Icon(
                  widget.activeIcon ?? Icons.add_rounded,
                  key: ValueKey(widget.activeIcon ?? Icons.add_rounded),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
