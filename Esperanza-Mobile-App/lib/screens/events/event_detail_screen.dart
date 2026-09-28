import 'package:flutter/material.dart';

import '../../models/announcement.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/event_card.dart';
import '../shared/event_poster_viewer.dart';

/// One event, opened from its card, laid out like the PAAIPE Mobile App's
/// event page (Upupapp/PAAIPE-Mobile-APP `EventsView` detail): the banner,
/// the title, then the date/time/place rows.
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
        ],
      ),
    );
  }
}
