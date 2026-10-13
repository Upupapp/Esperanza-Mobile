import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_colors.dart';
import '../utils/ambient_motion.dart';

/// The opening screens' gold action (owner's design, 2026-10-12): a gold
/// pill, a band of light passing over it every few seconds, an optional arrow
/// (nudging forward on the welcome pages), pressing in when touched. Next and
/// Get Started on the welcome pages, Sign In on the sign-in screen.
///
/// Its shadow is a plain drop shadow: no gold glow under buttons (owner,
/// 2026-10-09). The shine and the nudge are [AmbientMotion]: still under
/// reduce motion and in widget tests.
class GoldActionButton extends StatefulWidget {
  const GoldActionButton({
    super.key,
    required this.label,
    required this.textStyle,
    required this.height,
    required this.onPressed,
    this.arrow = false,
    this.nudge = false,
    this.loading = false,
  });

  final String label;
  final TextStyle textStyle;
  final double height;
  final VoidCallback? onPressed;

  /// A trailing arrow, and whether it nudges forward.
  final bool arrow;
  final bool nudge;

  /// A spinner in place of the label, as while signing in.
  final bool loading;

  @override
  State<GoldActionButton> createState() => _GoldActionButtonState();
}

class _GoldActionButtonState extends State<GoldActionButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  final _clock = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker((elapsed) => _clock.value = elapsed.inMicroseconds / 1e6);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ambient = AmbientMotion.of(context);
    if (ambient && !_ticker.isActive) {
      _ticker.start();
    } else if (!ambient && _ticker.isActive) {
      _ticker.stop();
      _clock.value = 0;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  /// 0 → 1 → 0 over [period], eased in and out.
  static double _swing(double t, double period) {
    if (t <= 0) return 0;
    final phase = (t % period) / period;
    return Curves.easeInOut.transform(phase < 0.5 ? phase * 2 : 2 - phase * 2);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.textStyle.color ?? AppColors.navy900;
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: widget.onPressed != null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: widget.height,
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.gold300, AppColors.gold400],
              ),
              shadows: [BoxShadow(color: AppColors.navy950.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: Material(
                color: AppColors.clear,
                child: InkWell(
                  onTap: widget.onPressed,
                  onHighlightChanged: (v) => setState(() => _pressed = v),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Shine(clock: _clock),
                      Center(
                        child: widget.loading
                            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: color))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis, style: widget.textStyle)),
                                  if (widget.arrow) ...[
                                    const SizedBox(width: 10),
                                    ValueListenableBuilder<double>(
                                      valueListenable: _clock,
                                      builder: (context, t, child) => Transform.translate(
                                        offset: Offset(widget.nudge ? 5 * _swing(t, 1.6) : 0, 0),
                                        child: child,
                                      ),
                                      child: Icon(Icons.arrow_forward_rounded, size: 22, color: color),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ],
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

/// A band of light sweeping across the button: 4.2 s cycles after a 1.2 s
/// wait, crossing in the first 45% of each.
class _Shine extends StatelessWidget {
  const _Shine({required this.clock});

  final ValueNotifier<double> clock;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => ValueListenableBuilder<double>(
          valueListenable: clock,
          builder: (context, t, _) {
            if (t <= 1.2) return const SizedBox.shrink();
            final phase = ((t - 1.2) % 4.2) / 4.2;
            if (phase >= 0.45) return const SizedBox.shrink();
            final x = -1.6 + 4.2 * Curves.easeInOut.transform(phase / 0.45);
            final band = box.maxWidth * 0.34;
            return Stack(
              children: [
                Positioned(
                  left: band * x,
                  top: -box.maxHeight * 0.1,
                  width: band,
                  height: box.maxHeight * 1.2,
                  child: Transform(
                    transform: Matrix4.skewX(-18 * math.pi / 180),
                    alignment: Alignment.center,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.surface.withValues(alpha: 0),
                            AppColors.surface.withValues(alpha: 0.55),
                            AppColors.surface.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
