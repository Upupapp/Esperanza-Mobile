import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/calendar_export.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/event_card.dart';
import '../balita/balita_post_screen.dart';
import '../shared/event_poster_viewer.dart';
import 'event_registration_panel.dart';

import '../../l10n/tr.dart';
/// One event, opened from its card, laid out like the PAAIPE Mobile App's
/// event page (Upupapp/PAAIPE-Mobile-APP `EventsView` detail): the banner,
/// the title, then the date/time/place rows.
///
/// The description (written in the Web Admin) shows in full here; the card
/// shows its first lines.
///
/// An event reaches residents (2026-10-21): "Remind me a day before" has the
/// server remind the resident in the bell and on this phone, and tell them if
/// it moves or is cancelled; "Add to calendar" still puts it on the phone's
/// own calendar. An event posted in Balita links to its post.
///
/// Registration and e-certificates (round 2, 2026-10-30): when the LGU takes
/// registrations, a resident registers here, shows the code at the event,
/// and opens the certificate once it is issued ([EventRegistrationPanel]).
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final EventItem event;

  static Future<void> open(BuildContext context, EventItem event) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Events'))),
      body: EventDetailBody(event: event),
    );
  }
}

/// An event opened by its key: what a notification about it opens
/// (`/citizen/events?event=KEY`, GET /events/{key}).
class EventLinkScreen extends StatelessWidget {
  const EventLinkScreen({super.key, required this.eventKey});

  final String eventKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Events'))),
      body: AsyncStateView<EventItem>(
        loader: () async {
          final res = await api.get('/events/${ApiClient.segment(eventKey)}');
          return EventItem.fromApi(res.map);
        },
        builder: (context, event, _) => EventDetailBody(event: event),
      ),
    );
  }
}

class EventDetailBody extends StatefulWidget {
  const EventDetailBody({super.key, required this.event});

  final EventItem event;

  @override
  State<EventDetailBody> createState() => _EventDetailBodyState();
}

class _EventDetailBodyState extends State<EventDetailBody> {
  /// Whether this resident asked to be reminded; null until known (or when
  /// it cannot be: signed out, a mock event, an event that has passed).
  bool? _reminded;
  bool _saving = false;

  EventItem get event => widget.event;

  bool get _upcoming => event.startsAt != null && !event.isPast(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final key = event.key;
    if (key == null || !_upcoming || !context.read<CitizenSessionService>().isSignedIn) return;
    try {
      final res = await api.get('/citizen/event-reminders');
      if (mounted) setState(() => _reminded = res.list.contains(key));
    } catch (_) {
      // The button stays hidden; the calendar file is still offered.
    }
  }

  Future<void> _toggleReminder() async {
    final key = event.key;
    final on = _reminded != true;
    if (key == null || _saving) return;
    setState(() => _saving = true);
    try {
      final path = '/citizen/events/${ApiClient.segment(key)}/reminder';
      if (on) {
        await api.post(path);
      } else {
        await api.delete(path);
      }
      if (!mounted) return;
      setState(() => _reminded = on);
      AppDialogs.toast(
        context,
        on
            ? 'We will remind you the day before. You will also be told if it moves or is cancelled.'
            : 'Reminder turned off.',
      );
    } on ApiException catch (e) {
      if (mounted) AppDialogs.toast(context, e.message(), success: false);
    } catch (_) {
      if (mounted) AppDialogs.toast(context, tr('Could not change the reminder. Try again.'), success: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balitaPost = event.balitaPostId;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        GestureDetector(
          // A poster can hold dates and names printed small: open it full
          // screen.
          onTap: event.imagePath != null || event.imageUrl != null
              ? () => EventPosterViewer.open(context, event)
              : null,
          child: EventPoster(event: event, radius: AppRadius.xl),
        ),
        const SizedBox(height: AppSpacing.lg),
        EventTitleRow(event: event),
        const SizedBox(height: AppSpacing.md),
        EventMeta(event: event),
        if (event.description != null) ...[const SizedBox(height: AppSpacing.lg), EventDescription(event: event)],
        // Spaces itself; nothing at all when the event takes no registrations.
        EventRegistrationPanel(
          event: event,
          // The server turned the day-before reminder on with it.
          onRegistered: () {
            if (_reminded != null) setState(() => _reminded = true);
          },
        ),
        // Not offered once the event is over.
        if (_upcoming && _reminded != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _reminded! ? 'Reminder on · Turn off' : 'Remind me a day before',
            icon: _reminded! ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
            variant: _reminded! ? AppButtonVariant.secondary : AppButtonVariant.primary,
            fullWidth: true,
            onPressed: _saving ? null : _toggleReminder,
          ),
        ],
        if (_upcoming) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: tr('Add to calendar'),
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
        if (balitaPost != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: tr('See it in Balita'),
            icon: Icons.campaign_outlined,
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => BalitaPostScreen(announcementId: balitaPost))),
          ),
        ],
      ],
    );
  }
}
