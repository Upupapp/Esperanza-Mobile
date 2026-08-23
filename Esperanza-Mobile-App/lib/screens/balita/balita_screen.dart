import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/balita_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../home/root_shell.dart';
import 'post_card.dart';

/// Balita ("news" in Filipino) — a community social feed. Mirrors
/// citizen/announcements.blade.php in intent. The mobile app is a
/// CONSUMPTION-ONLY surface for Balita: publishing/uploading content is an
/// admin-only capability handled through the Web Admin, so there is
/// deliberately no composer anywhere in this screen (or anywhere else in
/// the mobile app) for any account state — Guest, unverified, or verified.
/// Mobile users may only view, react, comment, view comments, and share
/// what the Web Admin has published. Liking/commenting/sharing remain a
/// pure frontend simulation backed by BalitaService (local state persisted
/// to SharedPreferences) — there is no backend for Balita.
///
/// Events used to live here as a segmented sub-tab; it is now its own
/// top-level nav destination (see screens/events/events_screen.dart) since
/// the bottom nav promoted it to a real tab — this screen is Balita's news
/// feed only.
class BalitaScreen extends StatelessWidget {
  const BalitaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaService>();
    final posts = balita.posts;

    return Scaffold(
      drawer: const EsperanzaDrawer(),
      appBar: AppBar(title: const Text('Balita'), actions: const [AlertsAction()]),
      body: posts.isEmpty
          ? const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No announcements available',
              description: 'Check back soon for updates from Esperanza LGU.',
            )
          // ListView.builder rather than a plain ListView(children: posts.map(...))
          // — post images (some several megapixels, see PostMediaView) only
          // ever get built/decoded for cards actually near the viewport
          // instead of the whole feed at once, without changing scrolling
          // behavior or layout.
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
              itemBuilder: (context, i) {
                final p = posts[i];
                return PostCard(
                  key: ValueKey(p.id),
                  post: p,
                  onLike: () => balita.toggleLike(p.id),
                  onComment: (c) => balita.addComment(p.id, c),
                  onShare: () => balita.share(p.id),
                );
              },
            ),
    );
  }
}
