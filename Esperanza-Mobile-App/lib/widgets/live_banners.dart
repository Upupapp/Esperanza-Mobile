import 'package:flutter/material.dart';

import '../screens/home/root_shell.dart';
import '../services/api_client.dart';
import '../services/json_read.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'service_launcher_menu.dart';

/// A banner staff publish to the dashboard (Communications, Banners on the
/// web admin), from the public `GET /banners`. The server sends only the
/// banners that are published and inside their date window - and, given the
/// resident's token, for their audience. The app showed none of them before
/// (QA run 2026-10-05).
class LiveBanner {
  final int? id;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final String? ctaRoute;
  final String? theme;

  /// An inline signed `/api/v1/media/...` link, like a Balita photo's.
  final String? imageUrl;

  /// What a screen reader says for the picture (2026-10-21).
  final String? altText;

  const LiveBanner({
    this.id,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.ctaRoute,
    this.theme,
    this.imageUrl,
    this.altText,
  });

  /// The picture's spoken label: its alt text, or the banner's title.
  String get imageLabel => altText ?? title;

  static LiveBanner fromApi(Map<String, dynamic> json) => LiveBanner(
    id: JsonRead.integer(json['id']),
    title: JsonRead.nonEmpty(json['title']) ?? '',
    subtitle: JsonRead.nonEmpty(json['subtitle']),
    ctaLabel: JsonRead.nonEmpty(json['cta_label']),
    ctaRoute: JsonRead.nonEmpty(json['cta_route']),
    theme: JsonRead.nonEmpty(json['theme']),
    // Resolved against the API's origin, as Balita's photos are.
    imageUrl: JsonRead.mediaUrl(json['image_url']),
    altText: JsonRead.nonEmpty(json['alt_text']),
  );

  /// The live banners; none when the list cannot be read, since Home has no
  /// error state for a teaser (like its events preview).
  static Future<List<LiveBanner>> load() async {
    try {
      final res = await api.get('/banners');
      return JsonRead.rows(res.list, LiveBanner.fromApi).where((b) => b.title.isNotEmpty).toList();
    } on ApiException {
      return const [];
    }
  }

  /// The web admin's theme ("from-purple-600 to-navy-900") in app colours.
  List<Color> get colors => switch (theme) {
    'from-purple-600 to-navy-900' => const [AppColors.purple700, AppColors.navy900],
    'from-emerald-600 to-teal-800' => const [AppColors.emerald700, AppColors.teal700],
    'from-gold-500 to-orange-700' => const [AppColors.gold500, AppColors.orange700],
    'from-rose-600 to-navy-900' => const [AppColors.rose600, AppColors.navy900],
    'from-slate-700 to-navy-950' => const [AppColors.slate700, AppColors.navy950],
    _ => const [AppColors.brand600, AppColors.navy800],
  };

  /// Where the button leads in the app; none for the web dashboard, which on
  /// the phone is this screen.
  void Function(BuildContext)? get action => switch (ctaRoute) {
    'citizen.document-requests' => (c) => RootShell.openService(c, ServiceLauncherTarget.dokyu),
    'citizen.assistance-requests' => (c) => RootShell.openService(c, ServiceLauncherTarget.tulong),
    'citizen.announcements' => (c) => RootShell.jumpTo(c, 1),
    'citizen.events' => (c) => RootShell.jumpTo(c, 2),
    _ => null,
  };
}

/// The live banners as swipeable cards, with dots when there are several.
class LiveBannersStrip extends StatefulWidget {
  final List<LiveBanner> banners;
  const LiveBannersStrip({super.key, required this.banners});

  @override
  State<LiveBannersStrip> createState() => _LiveBannersStripState();
}

class _LiveBannersStripState extends State<LiveBannersStrip> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    return Column(
      children: [
        SizedBox(
          // Grows with the text size, so a two-line title, subtitle and
          // button still fit at a large accessibility setting.
          height: MediaQuery.textScalerOf(context).scale(172),
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _BannerCard(banner: banners[i]),
            ),
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < banners.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.brand600 : AppColors.slate300,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final LiveBanner banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    final action = banner.action;
    final image = banner.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image.network(
              image,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              semanticLabel: banner.imageLabel,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [for (final c in banner.colors) image != null ? c.withValues(alpha: 0.85) : c],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.surface, height: 1.25),
                ),
                if (banner.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.surface.withValues(alpha: 0.88), height: 1.35),
                  ),
                ],
                if (banner.ctaLabel != null && action != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: () => action(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              banner.ctaLabel!,
                              style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: AppColors.navy900),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.navy900),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
