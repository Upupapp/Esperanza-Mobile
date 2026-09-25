import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/access_level.dart';
import '../../models/announcement.dart';
import '../../services/balita_service.dart';
import '../../services/citizen_session_service.dart';
import '../../utils/balita_post_actions.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../home/root_shell.dart';
import 'compose_post_screen.dart';
import 'post_card.dart';

/// Balita ("news" in Filipino) — announcements and the community feed,
/// both real now (production-readiness programme, 2026-09-25). Mirrors
/// citizen/announcements.blade.php in intent, including that page's own
/// merge of GET /announcements + GET /community-posts into one sorted
/// feed. Citizens may view, react, comment, report, and — unlike the Web
/// Admin's own citizen page, which has no composer either — post to the
/// community feed themselves (see [ComposePostScreen]'s own doc comment
/// for why that's a deliberate scope decision, not an oversight).
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
      drawer: const EsperanzaDrawer(),
      appBar: AppBar(
        title: const Text('Balita'),
        actions: [
          IconButton(
            tooltip: 'New Post',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => requireAccountForBalita(
              context,
              'Posting to Balita',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ComposePostScreen())),
              minLevel: AccessLevel.unverified,
            ),
          ),
          const AlertsAction(),
        ],
      ),
      // Keyed by sign-in state so a Guest continuing as a signed-in citizen
      // (or signing out) re-fetches through AsyncStateView's own initState
      // rather than silently keeping a stale Guest-only (or stale
      // previous-citizen) feed on screen.
      body: AsyncStateView<List<Announcement>>(
        key: ValueKey(session.account?.id ?? (session.isGuest ? 'guest' : 'signed-out')),
        loader: () async {
          await balita.loadFeed(signedIn: session.account != null);
          return balita.posts;
        },
        builder: (context, posts, reload) => posts.isEmpty
            ? const EmptyState(
                icon: Icons.campaign_outlined,
                title: 'No announcements available',
                description: 'Check back soon for updates from Esperanza LGU.',
              )
            // ListView.builder rather than a plain ListView(children: posts.map(...))
            // — post images only ever get built/decoded for cards actually
            // near the viewport instead of the whole feed at once, without
            // changing scrolling behavior or layout.
            : ListView.builder(
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
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
                itemCount: posts.length,
                itemBuilder: (context, i) => PostCard(key: ValueKey(posts[i].id), post: posts[i]),
              ),
      ),
    );
  }
}
