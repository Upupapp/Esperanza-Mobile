import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_status.dart';
import '../theme/tulong_status.dart';

/// Direct port of `resources/views/components/ui/badge.blade.php` — a pill
/// with a colored dot, using the exact same color mapping as the Web Admin.
/// Construct from [AppStatus], or with [StatusChip.request] for a request's
/// status, which for a Tulong case may be one of [TulongStatus]'s own. Never
/// from an arbitrary string: an unrecognized status can't silently render
/// wrong (it falls back to Draft the same way the Blade component does).
class StatusChip extends StatelessWidget {
  final AppStatus? status;

  /// A request's status label (see [RequestStatusView]); set only by
  /// [StatusChip.request].
  final String? requestStatus;
  final bool small;

  /// Shown instead of the status name where residents use other words for
  /// it (an incident's "Dispatched" for Processing); the colour still
  /// follows [requestStatus].
  final String? label;

  const StatusChip({super.key, required AppStatus this.status, this.small = false}) : requestStatus = null, label = null;

  const StatusChip.request(String this.requestStatus, {super.key, this.small = false, this.label}) : status = null;

  @override
  Widget build(BuildContext context) {
    final style = status?.style ?? RequestStatusView(requestStatus!).style;
    final label = status?.label ?? this.label ?? requestStatus!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : AppSpacing.sm, vertical: small ? 3 : AppSpacing.xs),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: style.foreground.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Flexible + longestLine: a Row with no flex child measures its
          // content at unconstrained natural width, so a longer label
          // ("Under Verification", "Pending Review") can overflow a
          // narrow parent (e.g. VerificationStatusPanel's icon+chip row)
          // even though every existing call site happened to have enough
          // room. Flexible makes it wrap instead, harmlessly, everywhere
          // it's used — see SectionStatusChip for the same fix.
          Flexible(
            child: Text(
              label,
              textWidthBasis: TextWidthBasis.longestLine,
              style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w500, color: style.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
