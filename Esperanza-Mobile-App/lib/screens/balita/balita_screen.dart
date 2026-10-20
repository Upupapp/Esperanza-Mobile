import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/balita_service.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/birthday.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/empty_state.dart';
import '../home/root_shell.dart';
import 'birthday_greeting_card.dart';
import 'post_card.dart';

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

class _Feed extends StatelessWidget {
  const _Feed({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaService>();
    final posts = balita.posts;
    // On the citizen's birthday a private greeting leads the feed.
    final account = context.watch<CitizenSessionService>().account;
    final birthday = Birthday.isToday(account);
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await onRefresh();
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
        itemCount: (birthday ? 1 : 0) + (posts.isEmpty ? 1 : posts.length),
        itemBuilder: (context, i) {
          if (birthday) {
            if (i == 0) return BirthdayGreetingCard(key: ValueKey('birthday-${account!.id}'), account: account);
            i -= 1;
          }
          if (posts.isEmpty) {
            return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No announcements available',
              description: 'Check back soon for updates from Esperanza LGU.',
            );
          }
          return PostCard(key: ValueKey(posts[i].id), post: posts[i]);
        },
      ),
    );
  }
}
