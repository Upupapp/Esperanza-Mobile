import 'package:flutter/material.dart';
import '../../services/mock_catalog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../../widgets/event_card.dart';
import '../home/root_shell.dart';

/// Events — previously a segmented sub-tab inside Balita
/// (`BalitaScreen`'s `_EventsList`), promoted to its own bottom-nav
/// destination now that the navbar is Home / Balita / + / Events /
/// Emergency. Same content, model ([MockCatalog.events]), and card
/// ([EventCard]) as before — this is a relocation, not a new feature.
/// Events stay deliberately distinct from the Balita social feed: no
/// like/comment/share affordances, just clear date/time/location
/// scanability and a tappable card that opens the full poster.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = MockCatalog.events;
    return Scaffold(
      drawer: const EsperanzaDrawer(),
      appBar: AppBar(title: const Text('Events'), actions: const [AlertsAction()]),
      body: events.isEmpty
          ? const EmptyState(icon: Icons.event_outlined, title: 'No upcoming events')
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
              itemCount: events.length,
              itemBuilder: (context, i) => EventCard(event: events[i]),
            ),
    );
  }
}
