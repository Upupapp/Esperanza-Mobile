import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import 'message_language.dart';
import 'notification_feed.dart';
import 'notifications_service.dart';
import '../theme/app_colors.dart';
import '../utils/esperanza_seal.dart';

/// One push as the app needs it: what it says and where it leads.
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// notification_id, link, ref, category (esperanza-backend DeliveryDispatcher).
  final Map<String, String> data;
}

/// The notice an Android phone shows for a push (owner, 2026-10-16: "look like
/// the app logo of Esperanza, follow the colours of the seal"): the
/// full-colour seal beside the message, and the seal's silhouette as the
/// small icon in the seal's gold. Android draws a small icon in one colour
/// whatever it is given, so the seal's own colours are the large picture's.
/// The server sends Android pushes as data (PushSender) so the app draws this
/// notice itself; an iPhone shows the system's own.
class PushNotices {
  PushNotices._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// [onTap] receives a notice the resident tapped while the app was running.
  static Future<void> init({void Function(PushMessage message)? onTap}) async {
    if (_ready || !_android) return;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_esperanza')),
      onDidReceiveNotificationResponse: (response) {
        final m = decode(response.payload);
        if (m != null) onTap?.call(m);
      },
    );
    _ready = true;
  }

  /// The notice that opened the app from closed, if one did.
  static Future<PushMessage?> launchMessage() async {
    if (!_android) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true ? decode(details!.notificationResponse?.payload) : null;
  }

  static Future<void> show(PushMessage m) async {
    if (!_android || (m.title ?? '').isEmpty) return;
    await init();
    await _plugin.show(
      id: (m.data['notification_id'] ?? '${m.title}${m.body}').hashCode & 0x7fffffff,
      title: m.title,
      body: m.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'esperanza_updates',
          'Request updates',
          channelDescription: 'Updates on your requests, documents and account from the Municipality of Esperanza',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_esperanza',
          color: AppColors.gold500,
          largeIcon: const DrawableResourceAndroidBitmap('esperanza_seal_notice'),
          styleInformation: BigTextStyleInformation(m.body ?? ''),
        ),
      ),
      payload: jsonEncode({'title': m.title, 'body': m.body, 'data': m.data}),
    );
  }

  @visibleForTesting
  static PushMessage? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload);
      if (map is! Map) return null;
      final data = map['data'];
      return PushMessage(
        title: map['title'] as String?,
        body: map['body'] as String?,
        data: data is Map ? {for (final e in data.entries) '${e.key}': '${e.value}'} : const {},
      );
    } catch (_) {
      return null;
    }
  }
}

/// A push that arrives while the app is closed or in the background: drawn
/// as the Esperanza notice. Runs on its own, outside the app.
@pragma('vm:entry-point')
Future<void> esperanzaBackgroundPush(RemoteMessage message) async {
  // One with a notification of its own is shown by the system already.
  if (message.notification != null) return;
  await Firebase.initializeApp();
  await PushNotices.show(_FirebasePushPlatform._message(message));
}

/// Where push messages come from: Firebase on a phone, a fake in tests.
abstract class PushPlatform {
  /// Whether push can work on this build (Firebase is configured).
  Future<bool> init();
  Future<bool> requestPermission();
  Future<String?> token();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  Stream<PushMessage> get onForeground;
  Stream<PushMessage> get onOpened;
  Future<PushMessage?> initialMessage();
}

/// Push notifications on the resident's phone (owner, 2026-10-15: Android
/// now, iOS once the APNs key exists).
///
/// - [start] (from main) sets Firebase up; a build without its Firebase file
///   simply has no push, and everything else works as before.
/// - [register] runs whenever a signed-in session is (re)confirmed: it asks
///   for permission once, then sends the phone's token and language to
///   POST /citizen/devices. The server pushes every notification the bell
///   gets, in that language.
/// - [unregister] runs on sign-out, so a signed-out phone stops getting them;
///   [forget] drops the token when the server ended the session.
/// - A push that arrives while the app is open shows as a banner and
///   refreshes the bell; a tapped push opens what the notification links to,
///   the same as tapping it in the bell.
class PushService {
  PushService._();

  /// Replaced in tests. Null: push is off.
  @visibleForTesting
  static PushPlatform? platform = _FirebasePushPlatform();

  /// The app's navigator and banner host, for a push that opens a screen.
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static bool _enabled = false;
  static String? _registered;
  static final List<StreamSubscription<Object?>> _subscriptions = [];

  static bool get enabled => _enabled;

  static Future<void> start() async {
    final p = platform;
    if (p == null || kIsWeb) return;
    try {
      _enabled = await p.init();
    } catch (_) {
      _enabled = false;
    }
    if (!_enabled) return;
    _subscriptions
      ..add(p.onTokenRefresh.listen((token) => _send(token)))
      ..add(p.onForeground.listen(_showBanner))
      ..add(p.onOpened.listen(_open));
    final first = await p.initialMessage();
    if (first != null) {
      // The app was opened by tapping a push: open its screen once the app is up.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Future.delayed(const Duration(milliseconds: 800), () => _open(first)),
      );
    }
  }

  /// Registers this phone for the signed-in resident. Safe to call often:
  /// the server is told once per token.
  static Future<void> register() async {
    final p = platform;
    if (!_enabled || p == null) return;
    try {
      if (!await p.requestPermission()) return;
      final token = await p.token();
      if (token != null && token != _registered) await _send(token);
    } catch (_) {
      // No push this time; the next sign-in or start tries again.
    }
  }

  /// Sign-out: the server forgets this phone, then the token is dropped.
  static Future<void> unregister() async {
    final p = platform;
    if (!_enabled || p == null) return;
    try {
      final token = _registered ?? await p.token();
      if (token != null) await api.delete('/citizen/devices', body: {'token': token});
    } catch (_) {
      // Signed out anyway; the dropped token below stops the pushes.
    }
    await forget();
  }

  /// The session ended without a sign-out (the server refused the token):
  /// the push token is dropped, so the server's next push to it fails and
  /// the server forgets this phone.
  static Future<void> forget() async {
    final p = platform;
    _registered = null;
    if (!_enabled || p == null) return;
    try {
      await p.deleteToken();
    } catch (_) {}
  }

  static Future<void> _send(String token) async {
    await api.post(
      '/citizen/devices',
      body: {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'locale': MessageLanguage.filipino.value ? 'fil' : 'en',
      },
    );
    _registered = token;
  }

  static void _showBanner(PushMessage m) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      unawaited(context.read<NotificationsService>().loadServer().catchError((Object _) {}));
    }
    final title = m.title;
    if (title == null || title.isEmpty) return;
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        // The Esperanza seal beside the message: the notice is the LGU's.
        content: Row(
          children: [
            ClipOval(child: Image.asset(esperanzaSealAsset, width: 32, height: 32, excludeFromSemantics: true)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                m.body == null || m.body!.isEmpty ? title : '$title\n${m.body}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: _destination(m) == null ? null : SnackBarAction(label: 'Open', onPressed: () => _open(m)),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  static void _open(PushMessage m) {
    final screen = _destination(m);
    final navigator = navigatorKey.currentState;
    if (screen == null || navigator == null) return;
    navigator.push(MaterialPageRoute(builder: (_) => screen));
  }

  static Widget? _destination(PushMessage m) {
    final n = ServerNotification.fromApi({
      'id': int.tryParse(m.data['notification_id'] ?? '') ?? 0,
      'title': m.title ?? 'Esperanza',
      'link': m.data['link'],
      'ref': m.data['ref'],
      'category': m.data['category'],
    });
    return n == null ? null : serverNotificationDestination(n);
  }
}

class _FirebasePushPlatform implements PushPlatform {
  final _tapped = StreamController<PushMessage>.broadcast();

  @override
  Future<bool> init() async {
    // Throws without the build's Firebase file (google-services.json):
    // that build has no push.
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(esperanzaBackgroundPush);
    await PushNotices.init(onTap: _tapped.add);
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() => FirebaseMessaging.instance.getToken();

  @override
  Future<void> deleteToken() => FirebaseMessaging.instance.deleteToken();

  @override
  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PushMessage> get onForeground => FirebaseMessaging.onMessage.map(_message);

  /// A system notice tapped (iPhone), or the app's own Esperanza notice.
  @override
  Stream<PushMessage> get onOpened {
    final merged = StreamController<PushMessage>.broadcast();
    FirebaseMessaging.onMessageOpenedApp.map(_message).listen(merged.add);
    _tapped.stream.listen(merged.add);
    return merged.stream;
  }

  @override
  Future<PushMessage?> initialMessage() async {
    final m = await FirebaseMessaging.instance.getInitialMessage();
    return m == null ? await PushNotices.launchMessage() : _message(m);
  }

  /// Title and body from the system notification, or - for the data the
  /// server sends an Android phone - from the data itself.
  static PushMessage _message(RemoteMessage m) {
    final data = {for (final e in m.data.entries) e.key: '${e.value}'};
    return PushMessage(
      title: m.notification?.title ?? data.remove('title'),
      body: m.notification?.body ?? data.remove('body'),
      data: data,
    );
  }
}
