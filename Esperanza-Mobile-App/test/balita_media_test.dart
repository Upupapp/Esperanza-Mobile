// Balita photos and videos in the app (2026-10-18): a post carries up to ten
// of them, the card lays them out like the website, the composer sends each
// in resumable 4 MB pieces, and the author's own post says where it stands.
import 'dart:convert';
import 'dart:typed_data';

import 'package:esperanza_mobile/models/announcement.dart';
import 'package:esperanza_mobile/models/balita_media.dart';
import 'package:esperanza_mobile/screens/balita/post_card.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/balita_uploads.dart';
import 'package:esperanza_mobile/services/notification_feed.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/screens/balita/balita_post_screen.dart';
import 'package:esperanza_mobile/widgets/balita_media_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

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

Widget _host(Widget child, BalitaService balita) => ChangeNotifierProvider<BalitaService>.value(
      value: balita,
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    FakeApi.restore();
    BalitaUploader.retryDelays = const [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)];
  });

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

    test('the author learns where their post stands, and why', () {
      final hidden = Announcement.fromCommunityApi({
        'id': 3,
        'author': 'Liza',
        'body': 'Selling puppies',
        'status': 'Pending Review',
        'visible': false,
        'mine': true,
        'review_state': 'hidden',
        'moderation_reason': 'Selling is not allowed on Balita.',
      });
      expect(hidden.reviewState, 'hidden');
      expect(hidden.heldBack, isTrue);
      expect(hidden.engageable, isFalse);
      expect(hidden.moderationReason, 'Selling is not allowed on Balita.');

      // An older server: read from visible/status.
      final old = Announcement.fromCommunityApi({'id': 4, 'author': 'Liza', 'body': 'x', 'status': 'Released', 'visible': true});
      expect(old.reviewState, 'published');
      expect(old.engageable, isTrue);
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

    testWidgets("the author's hidden post says so, with the reason, and offers Delete", (tester) async {
      final requests = <String>[];
      FakeApi.installFull((r) {
        requests.add('${r.method} ${r.path}');
        return {'id': 3, 'withdrawn': true};
      });
      final balita = BalitaService();
      final post = Announcement.fromCommunityApi({
        'id': 3,
        'author': 'Liza',
        'body': 'Selling puppies',
        'status': 'Pending Review',
        'visible': false,
        'mine': true,
        'review_state': 'hidden',
        'moderation_reason': 'Selling is not allowed on Balita.',
      });
      await tester.pumpWidget(_host(PostCard(post: post), balita));
      expect(find.textContaining('Hidden by Esperanza LGU'), findsOneWidget);
      expect(find.text('Reason: Selling is not allowed on Balita.'), findsOneWidget);
      expect(find.text('Like'), findsNothing, reason: 'nothing to like until it is live');

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Delete post'), findsOneWidget);
      expect(find.text('Report post'), findsNothing);
      await tester.tap(find.text('Delete post'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(requests, contains('DELETE /citizen/community-posts/3'));
    });
  });

  group('upload', () {
    // A small in-memory server for the upload protocol: it keeps what it
    // received per upload, refuses an offset that leaves a gap, and answers
    // the start/chunk/complete calls as BalitaMediaController does.
    late List<String> calls;
    late int received;
    late bool refuseNextChunk;

    void installServer({int chunkBytes = 4}) {
      calls = [];
      received = 0;
      refuseNextChunk = false;
      api = ApiClient(
        baseUrl: 'https://test.invalid',
        httpClient: MockClient((request) async {
          final path = request.url.path;
          calls.add('${request.method} $path');
          Map<String, dynamic> row() => {'id': 'u-1', 'declared_bytes': 10, 'received_bytes': received, 'chunk_bytes': chunkBytes, 'status': 'open'};
          http.Response ok(Object data, [int status = 200]) =>
              http.Response(jsonEncode({'data': data}), status, headers: {'content-type': 'application/json'});

          if (path == '/citizen/balita/uploads') return ok(row(), 201);
          if (path == '/citizen/balita/uploads/u-1' && request.method == 'GET') return ok(row());
          if (path == '/citizen/balita/uploads/u-1/chunk') {
            final body = latin1.decode(request.bodyBytes);
            final offset = int.parse(RegExp(r'name="offset"\r\n\r\n(\d+)').firstMatch(body)!.group(1)!);
            // package:http writes a file part's content-type before its
            // content-disposition, so the bytes follow the filename's line.
            final piece = RegExp(r'filename="piece"(?:\r\n[^\r]+)*\r\n\r\n([\s\S]*?)\r\n--').firstMatch(body)!.group(1)!;
            if (refuseNextChunk) {
              refuseNextChunk = false;
              received = offset + piece.length; // the server already had this piece
              return http.Response(
                jsonEncode({
                  'error': {'code': 'UPLOAD_OFFSET_MISMATCH', 'message': {'en': 'Resume', 'fil': 'Ituloy'}},
                }),
                409,
                headers: {'content-type': 'application/json'},
              );
            }
            if (offset != received) {
              return http.Response(jsonEncode({'error': {'code': 'UPLOAD_OFFSET_MISMATCH', 'message': {'en': 'x', 'fil': 'x'}}}), 409);
            }
            received += piece.length;
            return ok(row());
          }
          if (path == '/citizen/balita/uploads/u-1/complete') {
            return ok(_media(42, 'image', width: 2, height: 2), 201);
          }
          return http.Response('{}', 404);
        }),
      );
    }

    XFile file(String name, String text, String mime) =>
        XFile.fromData(Uint8List.fromList(ascii.encode(text)), name: name, mimeType: mime, length: text.length);

    test('a photo goes up in pieces and comes back as media', () async {
      installServer();
      final upload = BalitaUpload(file: file('a.jpg', 'ABCDEFGHIJ', 'image/jpeg'), kind: BalitaMediaKind.image);
      await BalitaUploader.run(upload);
      expect(upload.status, BalitaUploadStatus.done, reason: '${upload.error} / $calls');
      expect(upload.media!.id, 42);
      expect(received, 10);
      expect(calls.where((c) => c.endsWith('/chunk')), hasLength(3), reason: '10 bytes in pieces of 4');
    });

    test('a piece the server already had resumes from where it stopped', () async {
      installServer();
      refuseNextChunk = true;
      final upload = BalitaUpload(file: file('a.jpg', 'ABCDEFGHIJ', 'image/jpeg'), kind: BalitaMediaKind.image);
      await BalitaUploader.run(upload);
      expect(upload.status, BalitaUploadStatus.done);
      expect(calls, contains('GET /citizen/balita/uploads/u-1'));
      expect(received, 10);
    });

    test('a video over the limit is refused before anything is sent', () async {
      installServer();
      final upload = BalitaUpload(
        file: XFile.fromData(Uint8List(0), name: 'long.mp4', mimeType: 'video/mp4', length: BalitaUploader.maxVideoBytes + 1),
        kind: BalitaMediaKind.video,
      );
      await BalitaUploader.run(upload);
      expect(upload.status, BalitaUploadStatus.failed);
      expect(upload.error, contains('100 MB'));
      expect(calls, isEmpty);
    });

    test('photo or video is read from the picked file', () {
      expect(BalitaUploader.kindOf(XFile('x/clip.MOV')), BalitaMediaKind.video);
      expect(BalitaUploader.kindOf(XFile('x/pic.heic')), BalitaMediaKind.image);
      expect(BalitaUploader.kindOf(XFile.fromData(Uint8List(0), mimeType: 'video/mp4')), BalitaMediaKind.video);
    });
  });

  test('a post names its uploaded media', () async {
    Map<String, dynamic>? sent;
    FakeApi.installFull((r) {
      sent = r.body;
      return {'id': 9, 'author': 'Liza', 'body': '', 'status': 'Pending Review', 'visible': false, 'mine': true, 'review_state': 'pending', 'media': [_media(42, 'image')]};
    });
    final post = await BalitaService().createPost(body: '', category: 'Community', mediaIds: [42, 43]);
    expect(sent!['media_ids'], [42, 43]);
    expect(post.media, hasLength(1));
  });

  test("a notification about the resident's own post opens it", () {
    final screen = serverNotificationDestination(ServerNotification(
      id: 1,
      category: 'community',
      title: 'Your Balita post is live',
      body: 'b',
      pill: 'Published',
      ref: null,
      link: '/citizen/announcements?community=5',
      unread: true,
      pinned: false,
      at: DateTime(2026, 10, 18),
    ));
    expect(screen, isA<BalitaPostScreen>());
    expect((screen! as BalitaPostScreen).communityPostId, 5);
  });
}
