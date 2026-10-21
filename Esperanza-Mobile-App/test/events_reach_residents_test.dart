import 'package:flutter_test/flutter_test.dart';
import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/screens/events/event_detail_screen.dart';
import 'package:esperanza_mobile/services/notification_feed.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';

/// Events that reach residents (owner, 2026-10-21): a published event is told
/// to the residents it is for, a resident can ask to be reminded the day
/// before, and an event can be posted in Balita. The app reads what the
/// server sends and opens the event from any of its notifications.
void main() {
  test('an event carries its key, its poster and its Balita post', () {
    final e = EventItem.fromApi({
      'key': 'medical-mission-x1',
      'name': 'Libreng Medical Mission',
      'date': '2026-10-25',
      'time': '2:00 PM',
      'venue': 'Municipal Plaza',
      'image_url': 'https://api.example.test/media/7?signature=abc',
      'balita_post_id': 42,
    });
    expect(e.key, 'medical-mission-x1');
    expect(e.imageUrl, 'https://api.example.test/media/7?signature=abc');
    expect(e.balitaPostId, 42);

    final plain = EventItem.fromApi({'key': 'k', 'name': 'Pulong', 'date': '2026-10-25'});
    expect(plain.imageUrl, isNull);
    expect(plain.balitaPostId, isNull);
  });

  test('a Balita post made from an event says when and where', () {
    final post = Announcement.fromAnnouncementApi({
      'id': 9,
      'title': 'Libreng Medical Mission',
      'body': 'Libreng konsulta.',
      'event': {'key': 'medical-mission-x1', 'date': '2026-10-25', 'time': '2:00 PM', 'venue': 'Municipal Plaza'},
    });
    expect(post.event?.key, 'medical-mission-x1');
    expect(post.event?.line, 'Sun, Oct 25 · 2:00 PM · Municipal Plaza');

    expect(Announcement.fromAnnouncementApi({'id': 10, 'body': 'b'}).event, isNull);
    expect(Announcement.fromAnnouncementApi({'id': 11, 'body': 'b', 'event': null}).event, isNull);
  });

  test('every event notification opens that event', () {
    ServerNotification n(String link) => ServerNotification(
      id: 1,
      category: 'community',
      title: 'New event: Libreng Medical Mission',
      body: 'b',
      pill: 'Event',
      ref: null,
      link: link,
      unread: true,
      pinned: false,
      at: DateTime(2026, 10, 21),
    );

    final d = serverNotificationDestination(n('/citizen/events?event=medical-mission-x1'));
    expect(d, isA<EventLinkScreen>());
    expect((d! as EventLinkScreen).eventKey, 'medical-mission-x1');

    final encoded = serverNotificationDestination(n('/citizen/events?event=fiesta%20mass-y2'));
    expect((encoded! as EventLinkScreen).eventKey, 'fiesta mass-y2');
  });
}
