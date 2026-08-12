import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../models/citizen_account.dart';
import '../../services/balita_service.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../../widgets/restricted_feature_notice.dart';
import '../../widgets/segmented_tabs.dart';
import '../home/root_shell.dart';
import 'post_card.dart';
import 'post_composer_sheet.dart';

/// Balita ("news" in Filipino) — a community social feed — plus Events.
/// Mirrors citizen/announcements.blade.php and citizen/events.blade.php in
/// intent, but the feed itself (posting/liking/commenting/sharing) is a
/// pure frontend simulation backed by BalitaService (local state persisted
/// to SharedPreferences) — there is no backend for Balita. Reached from
/// Home's "View all" action and the Profile menu rather than a dedicated
/// bottom-nav tab (see root_shell.dart's IA note).
class BalitaScreen extends StatefulWidget {
  const BalitaScreen({super.key});

  @override
  State<BalitaScreen> createState() => _BalitaScreenState();
}

class _BalitaScreenState extends State<BalitaScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this)..addListener(_onTabChanged);

  void _onTabChanged() => setState(() {});

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openComposer() async {
    // Viewing Balita is public (Section 6), but publishing a post is an
    // account action — a Guest gets the same reusable notice any other
    // protected feature would show, rather than a silently-broken sheet.
    if (context.read<CitizenSessionService>().isGuest) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RestrictedFeatureNotice(reason: RestrictionReason.guestOnly, featureName: 'Posting to Balita'),
        ),
      );
      return;
    }
    final result = await showModalBottomSheet<Announcement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PostComposerSheet(),
    );
    if (result != null && mounted) {
      await context.read<BalitaService>().addPost(result);
      if (mounted) AppDialogs.toast(context, 'Posted to Balita.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const EsperanzaDrawer(),
      appBar: AppBar(title: const Text('Balita & Events'), actions: const [AlertsAction()]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SegmentedTabs(
              labels: const ['Balita', 'Events'],
              selectedIndex: _tabController.index,
              onChanged: (i) => _tabController.animateTo(i),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BalitaFeed(onCompose: _openComposer),
                const _EventsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalitaFeed extends StatelessWidget {
  final VoidCallback onCompose;

  const _BalitaFeed({required this.onCompose});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<CitizenSessionService>().account;
    final balita = context.watch<BalitaService>();
    final posts = balita.posts;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _Composer(account: account, onTap: onCompose),
        const SizedBox(height: 14),
        if (posts.isEmpty)
          const EmptyState(icon: Icons.campaign_outlined, title: 'No announcements yet')
        else
          ...posts.map(
            (p) => PostCard(
              key: ValueKey(p.id),
              post: p,
              onLike: () => balita.toggleLike(p.id),
              onComment: (c) => balita.addComment(p.id, c),
              onShare: () => balita.share(p.id),
            ),
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  final CitizenAccount? account;
  final VoidCallback onTap;
  const _Composer({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.brand50,
                  child: Text(account?.initials ?? '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.slate100),
                    ),
                    child: const Text("What's happening in Esperanza?", style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _ComposerAction(icon: Icons.image_outlined, label: 'Photo', color: AppColors.emerald500, onTap: onTap)),
              Expanded(child: _ComposerAction(icon: Icons.edit_note_rounded, label: 'Post', color: AppColors.brand500, onTap: onTap)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ComposerAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Events stay deliberately distinct from the social feed above — no
/// like/comment/share affordances here, just clearer date/time/location
/// scanability and a tappable card, per the "don't turn Events into social
/// posts" requirement.
class _EventsList extends StatelessWidget {
  const _EventsList();

  @override
  Widget build(BuildContext context) {
    final events = MockCatalog.events;
    if (events.isEmpty) {
      return const Center(child: EmptyState(icon: Icons.event_outlined, title: 'No upcoming events'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final e = events[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            onTap: () => AppDialogs.toast(context, 'Event details coming soon.'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.event_outlined, color: AppColors.brand600, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      _EventMeta(icon: Icons.calendar_today_rounded, text: '${e.date} · ${e.time}'),
                      const SizedBox(height: 4),
                      _EventMeta(icon: Icons.place_outlined, text: e.venue),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EventMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.slate400),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3))),
      ],
    );
  }
}
