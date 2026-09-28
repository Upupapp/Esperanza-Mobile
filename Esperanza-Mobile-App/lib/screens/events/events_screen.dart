import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/json_read.dart';
import '../../widgets/esperanza_drawer.dart';
import '../../widgets/event_card.dart';
import '../../widgets/async_state_view.dart';
import '../home/root_shell.dart';
import '../../theme/app_colors.dart';
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
        builder: (context, events, reload) => _EventsBody(events: events, reload: reload),
      ),
    );
  }
}

/// PAAIPE's events list (Upupapp/PAAIPE-Mobile-APP `EventsView`): an
/// Upcoming / Past pill switch, then that period's cards. Past events used
/// to follow the upcoming ones on one list with nothing saying they were
/// over, so a finished clean-up drive read like the next thing on the
/// calendar.
class _EventsBody extends StatefulWidget {
  const _EventsBody({required this.events, required this.reload});

  final List<EventItem> events;
  final VoidCallback reload;

  @override
  State<_EventsBody> createState() => _EventsBodyState();
}

enum _Period { upcoming, past }

class _EventsBodyState extends State<_EventsBody> {
  _Period _period = _Period.upcoming;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final list = [
      for (final e in widget.events)
        if (e.isPast(today) == (_period == _Period.past)) e,
    ];
    return RefreshIndicator(
      onRefresh: () async => widget.reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final p in _Period.values)
                _PeriodPill(
                  label: p == _Period.upcoming ? 'Upcoming' : 'Past',
                  selected: _period == p,
                  onTap: () => setState(() => _period = p),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (list.isEmpty)
            _EmptyNote('No ${_period == _Period.upcoming ? 'upcoming' : 'past'} events right now.')
          else
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              EventCard(event: list[i]),
            ],
        ],
      ),
    );
  }
}

/// PAAIPE `.filter-pills` button: 44pt tall, pill-shaped, solid blue when
/// chosen.
class _PeriodPill extends StatelessWidget {
  const _PeriodPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.brand500 : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.brand500 : AppColors.slate200)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + 2),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTextSize.helper,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PAAIPE `.empty-note`: a quiet bordered note rather than a large empty
/// illustration.
class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        border: Border.all(color: AppColors.slate200),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: AppTextSize.label, height: 1.5, color: AppColors.slate600),
      ),
    );
  }
}
