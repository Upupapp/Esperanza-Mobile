import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'esperanza_art.dart';

import '../l10n/tr.dart';
/// Mirrors `resources/views/components/ui/empty-state.blade.php`.
/// The empty state (2026-10 design): a clay illustration on a clay tile,
/// a friendly title, a line of explanation and, where there is one, the
/// next action. [glyph] picks the illustration; without one it is chosen
/// from [icon] (a bell for notifications, a folder for documents…), and an
/// icon with no clay counterpart is shown in navy on the clay tile.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final ClayGlyph? glyph;
  final String title;
  final String? description;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.glyph,
    required this.title,
    this.description,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.page, horizontal: AppSpacing.xxl),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          ClayTile(
            size: 84,
            radius: 26,
            child: (glyph ?? _glyphFor(icon)) != null
                ? ClayIcon((glyph ?? _glyphFor(icon))!, size: 52)
                : Icon(icon, size: 34, color: AppColors.navy700),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.navy900),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted),
            ),
          ],
          if (action != null) ...[const SizedBox(height: AppSpacing.xl), action!],
        ],
      ),
    );
  }
}

/// A shimmering skeleton block, mirroring the Web Admin's `.skeleton` class
/// (used while mock data "loads" on screen entry, matching the Web Admin's
/// deliberate skeleton-then-content pattern on e.g. citizen/dashboard.blade.php).
/// The clay illustration that matches an empty state's Material icon.
ClayGlyph? _glyphFor(IconData icon) {
  final names = <IconData, ClayGlyph>{
    Icons.inbox_outlined: ClayGlyph.box,
    Icons.inbox_rounded: ClayGlyph.box,
    Icons.notifications_none_rounded: ClayGlyph.bell,
    Icons.notifications_outlined: ClayGlyph.bell,
    Icons.notifications_off_outlined: ClayGlyph.bell,
    Icons.description_outlined: ClayGlyph.document,
    Icons.article_outlined: ClayGlyph.document,
    Icons.folder_open_outlined: ClayGlyph.folder,
    Icons.folder_outlined: ClayGlyph.folder,
    Icons.search_off_rounded: ClayGlyph.search,
    Icons.search_rounded: ClayGlyph.search,
    Icons.campaign_outlined: ClayGlyph.megaphone,
    Icons.newspaper_outlined: ClayGlyph.megaphone,
    Icons.volunteer_activism_outlined: ClayGlyph.heart,
    Icons.apartment_outlined: ClayGlyph.building,
    Icons.account_balance_outlined: ClayGlyph.building,
    Icons.person_outline_rounded: ClayGlyph.person,
    Icons.report_outlined: ClayGlyph.shield,
  };
  return names[icon];
}

class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const SkeletonBox({super.key, required this.height, this.width, this.radius = 12});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: [
                AppColors.surface.withValues(alpha: 0.55),
                AppColors.brand100.withValues(alpha: 0.75),
                AppColors.surface.withValues(alpha: 0.55),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A centered error state with a retry action — used when a mock/local
/// operation is simulated to fail (e.g. validation, forced demo error).
class ErrorState extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.title, this.description, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.page, horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          const ClayBadge(ClayGlyph.error, size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.navy900),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(tr('Try again')),
            ),
          ],
        ],
      ),
    );
  }
}
