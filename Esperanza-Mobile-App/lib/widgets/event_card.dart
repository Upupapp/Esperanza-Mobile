import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../screens/events/event_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// One event as its own card, laid out like the PAAIPE Mobile App's events
/// list (Upupapp/PAAIPE-Mobile-APP `EventsView`, `.teresa-event-card`):
/// a 16:9 poster slot, the title with a category chip beside it, then the
/// date/time/place rows. PAAIPE's own sizes and radii are mapped onto the
/// nearest Esperanza tokens, and its colours onto Esperanza's palette (the
/// only colours this app may use, CLAUDE.md).
///
/// Tapping opens [EventDetailScreen], as a PAAIPE card opens its event.
/// [compact] (Home's preview) drops the poster so two events fit the teaser.
class EventCard extends StatelessWidget {
  final EventItem event;
  final bool compact;

  const EventCard({super.key, required this.event, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? AppSpacing.md : 0),
      child: Semantics(
        button: true,
        label: event.title,
        excludeSemantics: false,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => EventDetailScreen.open(context, event),
            child: Ink(
              decoration: BoxDecoration(
                // The fill is not optional: without it the shadow paints
                // through and the card reads grey.
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.slate200),
                boxShadow: AppShadows.card,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!compact) EventPoster(event: event),
                  Padding(
                    padding: EdgeInsets.fromLTRB(2, compact ? 0 : AppSpacing.md, 2, AppSpacing.sm),
                    child: EventTitleRow(event: event),
                  ),
                  EventMeta(event: event),
                  if (event.description != null && !compact)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, AppSpacing.sm, 2, 0),
                      child: EventDescription(event: event, maxLines: 3),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The description under the rows (PAAIPE `.teresa-event-card > p`): muted,
/// 13pt, a short preview on the card and in full on the event's page.
class EventDescription extends StatelessWidget {
  const EventDescription({super.key, required this.event, this.maxLines});

  final EventItem event;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      event.description ?? '',
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: const TextStyle(fontSize: AppTextSize.helper, height: 1.5, color: AppColors.textMuted),
    );
  }
}

/// The 16:9 poster slot (PAAIPE `.event-poster`): the event's own artwork
/// when it has one, otherwise a soft blue panel with a calendar and who is
/// putting it on. Real events have no artwork (the events table has no image
/// column), so the panel is what residents normally see.
class EventPoster extends StatelessWidget {
  const EventPoster({super.key, required this.event, this.radius = AppRadius.lg});

  final EventItem event;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: event.imagePath != null
            ? Image.asset(event.imagePath!, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brand100, AppColors.cyan50],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 32, color: AppColors.brand600),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      event.barangay != null ? 'Brgy. ${event.barangay}' : 'Municipality of Esperanza',
                      style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.brand600),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Title with the category chip beside it (PAAIPE `.event-title-row` and
/// `.soft-chip`; the chip is capped at 40% of the row so a long category
/// never squeezes the title out).
class EventTitleRow extends StatelessWidget {
  const EventTitleRow({super.key, required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              event.title,
              style: const TextStyle(
                fontSize: AppTextSize.card,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (event.category != null) ...[
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  event.category!,
                  style: const TextStyle(
                    fontSize: AppTextSize.fine,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: AppColors.brand500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The icon rows under the title (PAAIPE `.event-meta`): only what the event
/// actually has. Time and venue are optional in the Web Admin, and an empty
/// one used to leave a bare icon with nothing beside it.
class EventMeta extends StatelessWidget {
  const EventMeta({super.key, required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String)>[
      (Icons.calendar_today_outlined, event.date.isEmpty ? 'Date to be announced' : event.date),
      if (event.recurrence != null) (Icons.repeat_rounded, event.recurrence!),
      if (event.time.trim().isNotEmpty) (Icons.schedule_rounded, event.time.trim()),
      if (_place(event).isNotEmpty) (Icons.place_outlined, _place(event)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(rows[i].$1, size: 14, color: AppColors.textMuted),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Baras Plaza · Brgy. Baras": the venue, and the barangay when the event is
/// for one barangay only.
String _place(EventItem event) =>
    [event.venue.trim(), if (event.barangay != null) 'Brgy. ${event.barangay}'].where((s) => s.isNotEmpty).join(' · ');
