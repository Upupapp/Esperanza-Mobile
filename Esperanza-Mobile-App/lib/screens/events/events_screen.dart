import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/json_read.dart';
import '../../widgets/event_card.dart';
import '../../widgets/async_state_view.dart';
import '../home/root_shell.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_art.dart';

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
      // Clear, over RootShell's GlassBackdrop: the glass cards show its colour.
      backgroundColor: AppColors.clear,
      appBar: AppBar(
        leading: const ShellMenuButton(),title: const Text('Events'), actions: const [AlertsAction()]),
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
            EmptyState(
              glyph: ClayGlyph.calendar,
              title: 'No ${_period == _Period.upcoming ? 'upcoming' : 'past'} events right now.',
              description: 'Municipal and barangay events appear here as they are announced.',
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
            )
          else
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.itemGap),
              EventCard(event: list[i]),
            ],
        ],
      ),
    );
  }
}

/// PAAIPE `.filter-pills` button: 44pt tall, pill-shaped. Chosen: a raised
/// navy pill with white text and a gold dot (2026-10 refinement), the same
/// navy-for-selected as SegmentedTabs; not chosen: plain white with a slate
/// hairline, so the difference is plain without colour alone.
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.navy800 : AppColors.slate200)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected ? const [AppColors.navy700, AppColors.navy900] : const [AppColors.surface, AppColors.surface],
          ),
          shadows: selected
              ? [BoxShadow(color: AppColors.navy900.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 5), spreadRadius: -3)]
              : [BoxShadow(color: AppColors.navy900.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold400),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTextSize.helper,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? AppColors.surface : AppColors.navy700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
