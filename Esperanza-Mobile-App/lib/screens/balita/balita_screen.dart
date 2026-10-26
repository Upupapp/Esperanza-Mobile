import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/balita_service.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/empty_state.dart';
import '../home/root_shell.dart';
import 'post_card.dart';

import '../../l10n/tr.dart';
/// Balita ("news" in Filipino) — the LGU's announcements, real now
/// (production-readiness programme, 2026-09-25). Mirrors
/// citizen/announcements.blade.php in intent. Residents read, react,
/// comment and share; only the LGU posts (owner, 2026-10-20), so there is
/// no New Post entry point and no residents' community posts in the feed.
///
/// Events used to live here as a segmented sub-tab; it is now its own
/// top-level nav destination (see screens/events/events_screen.dart) since
/// the bottom nav promoted it to a real tab — this screen is Balita's news
/// feed only.
class BalitaScreen extends StatelessWidget {
  const BalitaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final balita = context.read<BalitaService>();

    return Scaffold(
      // Clear, over RootShell's GlassBackdrop: the glass cards show its colour.
      backgroundColor: AppColors.clear,
      appBar: AppBar(
        leading: const ShellMenuButton(),
        title: const Text('Balita'),
        actions: const [AlertsAction()],
      ),
      // Keyed by sign-in state so a Guest continuing as a signed-in citizen
      // (or signing out) re-fetches through AsyncStateView's own initState
      // rather than silently keeping a stale Guest (or stale
      // previous-citizen) feed on screen: GET /announcements says which
      // posts the signed-in citizen liked.
      body: AsyncStateView<List<Announcement>>(
        key: ValueKey(session.account?.id ?? (session.isGuest ? 'guest' : 'signed-out')),
        loader: () async {
          await balita.loadFeed();
          return balita.posts;
        },
        // The list is read live from BalitaService, not from the loader's
        // snapshot, so a post a notification opened (BalitaService
        // .loadAnnouncement adds it) and every like and comment count show
        // here too.
        builder: (context, _, reload) => _Feed(onRefresh: balita.loadFeed),
      ),
    );
  }
}

/// The website's Balita categories (scope-citizen.js), in its order.
const balitaCategories = ['Community', 'Health', 'Public Service', 'Advisory', 'Livelihood', 'Governance'];

/// The feed: All or Barangay (the resident's own barangay's posts) as
/// underlined tabs, a Filter that opens the categories beneath them (the
/// redesign, 2026-10-22), and "Load more posts" at the end. The tabs and the
/// category narrow what is loaded, as on the website.
class _Feed extends StatefulWidget {
  const _Feed({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  State<_Feed> createState() => _FeedState();
}

class _FeedState extends State<_Feed> {
  int _tab = 0; // 0 All, 1 Barangay
  String? _category;
  bool _categoriesOpen = false;

  Future<void> _loadMore(BalitaService balita) async {
    try {
      await balita.loadMore();
    } on ApiException {
      if (mounted) AppDialogs.toast(context, tr('Could not load more posts.'), success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaService>();
    final mine = context.watch<CitizenSessionService>().account?.barangay;
    final hasBarangay = mine != null && mine.trim().isNotEmpty;
    final tab = hasBarangay ? _tab : 0;
    final posts = [
      for (final p in balita.posts)
        if ((tab == 0 || p.barangay == mine) && (_category == null || p.category == _category)) p,
    ];
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate200))),
          child: Row(
            children: [
              _FeedTab(label: tr('All'), selected: tab == 0, onTap: () => setState(() => _tab = 0)),
              if (hasBarangay) _FeedTab(label: 'Barangay', selected: tab == 1, onTap: () => setState(() => _tab = 1)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _categoriesOpen = !_categoriesOpen),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.slate700,
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                ),
                icon: const Icon(Icons.filter_list_rounded, size: AppSizes.iconSm),
                label: Text(_category ?? 'Filter', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        if (_categoriesOpen)
          DecoratedBox(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate200))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.lg,
                children: [
                  for (final c in [null, ...balitaCategories])
                    TextButton(
                      onPressed: () => setState(() {
                        _category = c;
                        _categoriesOpen = false;
                      }),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        foregroundColor: c == _category ? AppColors.navy800 : AppColors.textMuted,
                      ),
                      child: Text(
                        c ?? 'All categories',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: c == _category ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await widget.onRefresh();
        } on ApiException catch (e) {
          if (context.mounted) AppDialogs.toast(context, e.message(), success: false);
        }
      },
      // ListView.builder rather than a plain ListView(children: posts.map(...))
      // — post images only ever get built/decoded for cards actually
      // near the viewport instead of the whole feed at once, without
      // changing scrolling behavior or layout.
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        // Balita posts (including their now-tappable images) are plain
        // scrolled content sitting directly on RootShell's IndexedStack
        // body, not a floating element, so they only need the
        // inherited navbar MediaQuery inset itself (RootShell's
        // extendBody: true keeps this in sync with whatever the curved
        // nav bar actually renders — see
        // widgets/esperanza_curved_navbar.dart) — without it, the last
        // post's image can end up laid out underneath the navbar's
        // full hit-testable bounding box and become untappable even
        // though it looks like ordinary scrolled content.
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 24 + MediaQuery.paddingOf(context).bottom),
        // The header, the posts (or the empty state), then Load more.
        itemCount: 1 + (posts.isEmpty ? 1 : posts.length) + (balita.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0) return header;
          i -= 1;
          if (posts.isEmpty) {
            if (i == 0) {
              return EmptyState(
                icon: Icons.campaign_outlined,
                title: tr('No Balita posts here yet.'),
                description: 'Check back soon for updates from Esperanza LGU.',
              );
            }
            i -= 1;
          } else if (i < posts.length) {
            return PostCard(key: ValueKey(posts[i].id), post: posts[i]);
          }
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: AppButton(
              label: balita.loadingMore ? 'Loading…' : 'Load more posts',
              variant: AppButtonVariant.secondary,
              fullWidth: true,
              loading: balita.loadingMore,
              onPressed: balita.loadingMore ? null : () => _loadMore(balita),
            ),
          );
        },
      ),
    );
  }
}

/// One underlined tab of the feed (All, Barangay).
class _FeedTab extends StatelessWidget {
  const _FeedTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          margin: const EdgeInsets.only(right: AppSpacing.xl),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: selected ? AppColors.navy800 : Colors.transparent, width: 2),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodyText.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
