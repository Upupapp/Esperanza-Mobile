import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../../widgets/event_card.dart';
import '../../widgets/async_state_view.dart';
import '../home/root_shell.dart';

/// Events — previously a segmented sub-tab inside Balita
/// (`BalitaScreen`'s `_EventsList`), promoted to its own bottom-nav
/// destination now that the navbar is Home / Balita / + / Events /
/// Emergency. Events stay deliberately distinct from the Balita social
/// feed: no like/comment/share affordances, just clear date/time/location
/// scanability and a tappable card that opens the full poster.
///
/// Real data now (GET /events, production-readiness programme,
/// 2026-09-25) instead of `MockCatalog.events` — see
/// [EventItem.fromApi]'s own doc comment for why a real event never has a
/// poster image, unlike the bundled artwork the old mock events shipped.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const EsperanzaDrawer(),
      appBar: AppBar(title: const Text('Events'), actions: const [AlertsAction()]),
      body: AsyncStateView<List<EventItem>>(
        loader: () async {
          final res = await api.get('/events', query: {'per_page': 100});
          return res.list.map((e) => EventItem.fromApi(e as Map<String, dynamic>)).toList();
        },
        builder: (context, events, reload) => events.isEmpty
            ? const EmptyState(icon: Icons.event_outlined, title: 'No upcoming events')
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
                itemCount: events.length,
                itemBuilder: (context, i) => EventCard(event: events[i]),
              ),
      ),
    );
  }
}
