import 'package:flutter/material.dart';

import '../../models/announcement.dart';
import '../../theme/app_spacing.dart';
import '../../utils/calendar_export.dart';
import '../../widgets/app_button.dart';
import '../../widgets/event_card.dart';
import '../shared/event_poster_viewer.dart';

/// One event, opened from its card, laid out like the PAAIPE Mobile App's
/// event page (Upupapp/PAAIPE-Mobile-APP `EventsView` detail): the banner,
/// the title, then the date/time/place rows.
///
/// The description (written in the Web Admin) shows in full here; the card
/// shows its first lines.
///
/// PAAIPE's page goes on to registration, tickets and feedback. Esperanza's
/// backend publishes events without any of those (GET /events has no
/// registration), so this page stops at what an event actually carries
/// rather than offering buttons that could not work.
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final EventItem event;

  static Future<void> open(BuildContext context, EventItem event) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          GestureDetector(
            // Bundled artwork can hold dates and names printed small: open
            // it full screen, as before. Real events have no artwork.
            onTap: event.imagePath != null ? () => EventPosterViewer.open(context, event) : null,
            child: EventPoster(event: event, radius: AppRadius.xl),
          ),
          const SizedBox(height: AppSpacing.lg),
          EventTitleRow(event: event),
          const SizedBox(height: AppSpacing.md),
          EventMeta(event: event),
          if (event.description != null) ...[const SizedBox(height: AppSpacing.lg), EventDescription(event: event)],
          // As on the website: onto the phone's calendar, reminded the day
          // before; not offered once the event is over.
          if (event.startsAt != null && !event.isPast(DateTime.now())) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Add to calendar',
              icon: Icons.event_available_outlined,
              variant: AppButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => CalendarExport.offer(
                context,
                CalendarEntry(
                  uid: 'event-${event.title.hashCode}-${event.startsAt!.toIso8601String()}@esperanza-lgu',
                  title: event.title,
                  date: event.startsAt!,
                  time: event.time,
                  place: event.venue,
                  description: event.description,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
