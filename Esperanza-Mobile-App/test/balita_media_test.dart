// Balita photos and videos in the app (2026-10-18): an LGU post carries up to
// ten of them and the card lays them out like the website. Residents no
// longer post (owner, 2026-10-20), so the composer's uploads and the
// author's own post status went with it.
import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/models/balita_media.dart';
import 'package:esperanza_mobile/services/notification_feed.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/screens/balita/balita_post_screen.dart';
import 'package:esperanza_mobile/widgets/balita_media_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _media(int id, String kind, {int? durationMs, int? width, int? height}) => {
      'id': id,
      'kind': kind,
      'url': 'https://test.invalid/api/v1/media/$id',
      'poster_url': null,
      'mime': kind == 'video' ? 'video/mp4' : 'image/jpeg',
      'width': width,
      'height': height,
      'duration_ms': durationMs,
      'ready': true,
    };

ServerNotification _balitaNotification(String link) => ServerNotification(
      id: 1,
      category: 'community',
      title: 'Balita',
      body: 'b',
      pill: 'Published',
      ref: null,
      link: link,
      unread: true,
      pinned: false,
      at: DateTime(2026, 10, 18),
    );

void main() {
  group('model', () {
    test('a post reads all its photos and videos, in order', () {
      final post = Announcement.fromAnnouncementApi({
        'id': 7,
        'title': 'Medical mission',
        'body': 'Sa plaza.',
        'image_url': 'https://test.invalid/api/v1/media/1',
        'media': [_media(1, 'image', width: 1200, height: 800), _media(2, 'video', durationMs: 65000)],
      });
      expect(post.media.map((m) => m.kind), [BalitaMediaKind.image, BalitaMediaKind.video]);
      expect(post.media[1].durationLabel, '1:05');
      expect(post.media[0].aspectRatio, 1.5);
    });

    test('a server that sends only image_url still shows that photo', () {
      final post = Announcement.fromAnnouncementApi({'id': 8, 'body': 'x', 'image_url': 'https://test.invalid/a.jpg'});
      expect(post.media, hasLength(1));
      expect(post.media.first.url, 'https://test.invalid/a.jpg');
    });
  });

  group('card', () {
    testWidgets('four or more media show as a grid whose last tile says how many more', (tester) async {
      final media = [for (var i = 1; i <= 6; i++) BalitaMedia.fromApi(_media(i, i == 2 ? 'video' : 'image', durationMs: 5000))];
      var opened = -1;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SizedBox(width: 360, child: BalitaMediaGallery(media: media, onOpen: (i) => opened = i))),
      ));
      expect(find.byType(BalitaMediaTile), findsNWidgets(4));
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('0:05'), findsOneWidget, reason: 'the video says how long it is');
      await tester.tap(find.byType(BalitaMediaTile).at(1));
      expect(opened, 1);
    });
  });

  test('a "New in Balita" notification opens the announcement', () {
    final screen = serverNotificationDestination(_balitaNotification('/citizen/announcements?post=5'));
    expect(screen, isA<BalitaPostScreen>());
    expect((screen! as BalitaPostScreen).announcementId, 5);
  });

  test("an older notification about a resident's own post leads nowhere", () {
    // Residents' community posts are gone (owner, 2026-10-20); the server no
    // longer sends `?community=` links, and one already in the list must not
    // open a post that no longer exists.
    expect(serverNotificationDestination(_balitaNotification('/citizen/announcements?community=5')), isNull);
  });
}
