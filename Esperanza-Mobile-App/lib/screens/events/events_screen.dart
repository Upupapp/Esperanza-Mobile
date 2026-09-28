import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/json_read.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../../widgets/event_card.dart';
import '../../widgets/async_state_view.dart';
import '../home/root_shell.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

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
          final rows = await api.getAllPages('/events', query: {'per_page': 100}, maxPages: 5);
          return EventItem.inCalendarOrder(JsonRead.rows(rows, EventItem.fromApi).where((e) => e.title.isNotEmpty));
        },
        builder: (context, events, reload) => RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: _sections(events),
          ),
        ),
      ),
    );
  }
}

/// Upcoming first, then past, each under its own heading. Past events used
/// to follow the upcoming ones with nothing to say they were over, so a
/// finished clean-up drive read like the next thing on the calendar.
List<Widget> _sections(List<EventItem> events) {
  final today = DateTime.now();
  final upcoming = [
    for (final e in events)
      if (!e.isPast(today)) e,
  ];
  final past = [
    for (final e in events)
      if (e.isPast(today)) e,
  ];
  return [
    if (upcoming.isEmpty) const EmptyState(icon: Icons.event_outlined, title: 'No upcoming events'),
    for (final e in upcoming) EventCard(event: e),
    if (past.isNotEmpty) ...[
      const Padding(
        padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm, left: AppSpacing.xs),
        child: Text('Past events', style: AppTypography.cardHeading),
      ),
      for (final e in past) EventCard(event: e),
    ],
  ];
}
