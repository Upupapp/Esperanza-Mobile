import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/balita_service.dart';
import '../../services/mock_catalog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../../widgets/event_card.dart';
import '../../widgets/promotional_banner_dialog.dart';
import '../../widgets/segmented_tabs.dart';
import '../home/root_shell.dart';
import 'post_card.dart';

/// Balita ("news" in Filipino) — a community social feed — plus Events.
/// Mirrors citizen/announcements.blade.php and citizen/events.blade.php in
/// intent. The mobile app is a CONSUMPTION-ONLY surface for Balita:
/// publishing/uploading content is an admin-only capability handled
/// through the Web Admin, so there is deliberately no composer anywhere in
/// this screen (or anywhere else in the mobile app) for any account state
/// — Guest, unverified, or verified. Mobile users may only view, react,
/// comment, view comments, and share what the Web Admin has published.
/// Liking/commenting/sharing remain a pure frontend simulation backed by
/// BalitaService (local state persisted to SharedPreferences) — there is
/// no backend for Balita. Reached from Home's "View all" action and the
/// Profile menu rather than a dedicated bottom-nav tab (see
/// root_shell.dart's IA note).
class BalitaScreen extends StatefulWidget {
  const BalitaScreen({super.key});

  @override
  State<BalitaScreen> createState() => _BalitaScreenState();
}

class _BalitaScreenState extends State<BalitaScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this)..addListener(_onTabChanged);

  // Balita's own promotional popup is offered by RootShell the first time
  // this tab is opened (see RootShell's own doc comment) — it owns Home/
  // Dokyu/Tulong/Balita/Emergency's "first time this *tab* is opened"
  // popups centrally, since IndexedStack builds every tab's State
  // immediately at launch, so a plain initState here would fire long
  // before the citizen ever actually looks at Balita. The Events *sub*-tab
  // is different: it's only ever reached by an explicit in-screen
  // selection (this TabController), which is a real, first-hand "the
  // citizen just chose Events" signal — so that one popup is owned here.
  bool _eventsBannerOffered = false;

  void _onTabChanged() {
    setState(() {});
    if (_tabController.index == 1 && !_eventsBannerOffered) {
      _eventsBannerOffered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          PromotionalBannerDialog.show(context, assetPath: 'assets/images/Balita tab_Events.png', label: 'Events');
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
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
            child: TabBarView(controller: _tabController, children: const [_BalitaFeed(), _EventsList()]),
          ),
        ],
      ),
    );
  }
}

class _BalitaFeed extends StatelessWidget {
  const _BalitaFeed();

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaService>();
    final posts = balita.posts;
    if (posts.isEmpty) {
      return const EmptyState(
        icon: Icons.campaign_outlined,
        title: 'No announcements available',
        description: 'Check back soon for updates from Esperanza LGU.',
      );
    }
    // ListView.builder rather than a plain ListView(children: posts.map(...))
    // — post images (some several megapixels, see PostMediaView) only ever
    // get built/decoded for cards actually near the viewport instead of the
    // whole feed at once, without changing scrolling behavior or layout.
    return ListView.builder(
      // Balita posts (including their now-tappable images) are plain
      // scrolled content sitting directly on RootShell's IndexedStack body,
      // not a floating element, so they only need the inherited navbar
      // MediaQuery inset itself (see NavStyle.floatingElementGap's doc
      // comment on why extendBody publishes this) — without it, the last
      // post's image can end up laid out underneath the floating navbar's
      // full hit-testable bounding box and become untappable even though
      // it looks like ordinary scrolled content.
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
    );
  }
}

/// Events stay deliberately distinct from the social feed above — no
/// like/comment/share affordances here, just clearer date/time/location
/// scanability and a tappable card (opens the full poster). Each event is
/// its own separate [EventCard]/list item — never combined into one
/// shared container, even when several share a venue or topic.
class _EventsList extends StatelessWidget {
  const _EventsList();

  @override
  Widget build(BuildContext context) {
    final events = MockCatalog.events;
    if (events.isEmpty) {
      return const EmptyState(icon: Icons.event_outlined, title: 'No upcoming events');
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.paddingOf(context).bottom),
      itemCount: events.length,
      itemBuilder: (context, i) => EventCard(event: events[i]),
    );
  }
}
