import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The KPI card colours, the same six the Web Admin dashboard uses
/// ("Registered Residents", "Dokyu Open", "Waiting on Staff", "Tulong Open",
/// "Released This Month", "Submitted Today"), all from the app palette.
enum StatTileColor { royal, azure, amber, indigo, navy, gold }

/// A KPI card in the Web Admin dashboard's style: filled glass in one of
/// its six gradients, white text on the darker left, a translucent glass
/// illustration of [icon] on the lighter right, a soft glow of the colour
/// beneath. The text always sits on the dark end, so white stays readable
/// (gold and amber included).
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final StatTileColor color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = StatTileColor.azure,
    this.onTap,
  });

  /// Dark (left, under the text) to light (right, under the illustration).
  List<Color> get _gradient => switch (color) {
    StatTileColor.royal => const [AppColors.brand600, AppColors.brand500, AppColors.brand400],
    StatTileColor.azure => const [AppColors.brand700, AppColors.brand500, AppColors.brand400],
    StatTileColor.amber => const [AppColors.amber700, AppColors.orange700, AppColors.orange500],
    StatTileColor.indigo => const [AppColors.brand900, AppColors.brand800, AppColors.brand600],
    StatTileColor.navy => const [AppColors.navy800, AppColors.navy700, AppColors.brand700],
    StatTileColor.gold => const [AppColors.gold700, AppColors.gold600, AppColors.gold500],
  };

  @override
  Widget build(BuildContext context) {
    final g = _gradient;
    final radius = BorderRadius.circular(AppRadius.xl);
    // The glow on its own layer, outside the ink: painted on the ink it
    // showed square corners.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: g[1].withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10), spreadRadius: -6)],
      ),
      child: Material(
      color: AppColors.clear,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: g, stops: const [0, 0.55, 1]),
            border: Border.all(color: AppColors.surface.withValues(alpha: 0.35), width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // The glass sheen across the top half.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [AppColors.surface.withValues(alpha: 0.20), AppColors.surface.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
                // The translucent glass illustration, tilted, at the bottom-
                // right beside the value: at the top it pushed a longer label
                // ("Tulong Requests") onto two lines, so the tiles no longer
                // lined up.
                Positioned(
                  right: -4,
                  bottom: 6,
                  child: IgnorePointer(child: _GlassGlyph(icon: icon)),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: AppTextSize.label,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface.withValues(alpha: 0.92),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        value,
                        style: const TextStyle(
                          // 24: a step under the display size, still well
                          // above the 12pt label.
                          fontSize: AppTextSize.page,
                          fontWeight: FontWeight.w800,
                          color: AppColors.surface,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// A frosted glass plate with the tile's icon on it, tilted — the mobile
/// counterpart of the web cards' glass illustrations.
class _GlassGlyph extends StatelessWidget {
  final IconData icon;
  const _GlassGlyph({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.14,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg + 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface.withValues(alpha: 0.42), AppColors.surface.withValues(alpha: 0.12)],
          ),
          border: Border.all(color: AppColors.surface.withValues(alpha: 0.55), width: 1.2),
        ),
        child: Icon(icon, size: 28, color: AppColors.surface.withValues(alpha: 0.9)),
      ),
    );
  }
}
