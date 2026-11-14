import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'json_read.dart';

/// Live updates (owner, 2026-11-15: "auto refreshing every second ... like
/// the data changes real time").
///
/// The server keeps one tiny public file beside the API (not under /api/v1),
/// `/live/changes.json`: a counter per topic and one for everything,
/// `{"v": 12, "t": {"requests": 5, "sakuna": 2, ...}, "at": "..."}`. Numbers
/// only, nothing personal, no sign-in (esperanza-backend
/// `App\Domain\Live\LiveChanges`; nginx sends it with `no-store`). While the
/// app is open this reads it every [interval], one read at a time, and tells
/// its listeners which topics moved ([lastMoved], [stamp]). Each screen then
/// reloads its own data through the usual signed-in API, quietly, while it
/// is on show (LiveRefresh, widgets/live_refresh.dart), and the bell does on
/// every tab (RootShell).
///
/// Topics, as the server counts them: `requests` (Dokyu, Tulong,
/// certificates), `sakuna` (alerts, centres, hotlines, incident reports),
/// `balita` (posts, comments, events, banners), `appointments`,
/// `notifications`, `residents` (accounts and resident records) and `other`.
///
/// A missing file (404), an error page, no connection, a timeout or a body
/// that is not the counters is "no news": ignored, and the next read goes
/// on. The first read only sets the baseline. RootShell starts this when the
/// app comes to the foreground and stops it when it goes to the background:
/// nothing is read meanwhile, and the first read back reports what moved.
class LiveUpdates extends ChangeNotifier {
  LiveUpdates({this.client, this.interval = const Duration(seconds: 1)});

  /// The one the app uses. Tests put in their own (test/flutter_test_config.dart).
  static LiveUpdates instance = LiveUpdates();

  /// Where the counters are, on the API's own origin ([ApiClient.origin]).
  static const path = '/live/changes.json';

  /// Where to read; null, the app's [api] as it is at each read (tests swap it).
  final ApiClient? client;

  /// How often the file is read while the app is open.
  final Duration interval;

  Timer? _timer;
  bool _reading = false;
  bool _disposed = false;

  /// Bumped by [stop]: a read still under way then is dropped, so a change
  /// it saw is reported after the app comes back instead of in the background.
  int _run = 0;

  _Counters? _last;
  final Map<String, int> _moves = {};
  Set<String> _lastMoved = const {};
  bool _answering = false;

  /// Reading every [interval]: the app is in the foreground.
  bool get running => _timer != null;

  /// The last read found the counters, so the server keeps the file. False
  /// before the first read, and while the file is missing or cannot be read
  /// (an older server): the bell then keeps its slow refresh (RootShell).
  bool get answering => _answering;

  /// The topics that moved at the latest change, when listeners were told.
  Set<String> get lastMoved => _lastMoved;

  /// How many times [topics] have moved since the app started: a number that
  /// only grows, so whoever keeps it can tell later whether anything it shows
  /// moved since (see LiveRefresh).
  int stamp(Iterable<String> topics) {
    var sum = 0;
    for (final topic in topics) {
      sum += _moves[topic] ?? 0;
    }
    return sum;
  }

  /// Reads now, then every [interval]. Nothing happens when already running.
  void start() {
    if (_disposed || _timer != null) return;
    _timer = Timer.periodic(interval, (_) => _read());
    unawaited(_read());
  }

  /// No more reads (the app went to the background). What was read last is
  /// kept, so the first read after [start] reports what moved meanwhile.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _run++;
  }

  /// Stops, and forgets what was read (the resident signed out): the next
  /// [start]'s first read is a new baseline, not a list of changes.
  void reset() {
    stop();
    _last = null;
    _answering = false;
  }

  Future<void> _read() async {
    // One read at a time: on a slow connection a second is skipped, not piled up.
    if (_reading || _timer == null) return;
    _reading = true;
    final run = _run;
    try {
      final body = await (client ?? api).getPublicJson(path);
      // Stopped while it was under way.
      if (run != _run || _disposed) return;
      final now = _Counters.parse(body);
      _answering = now != null;
      if (now == null) return;
      final last = _last;
      _last = now;
      // The first read is the baseline; the same v is no news.
      if (last == null || now.v == last.v) return;
      final moved = now.movedSince(last);
      if (moved.isEmpty) return;
      for (final topic in moved) {
        _moves[topic] = (_moves[topic] ?? 0) + 1;
      }
      _lastMoved = moved;
      notifyListeners();
    } finally {
      _reading = false;
      // Started again while a read from before the stop was under way: that
      // one was dropped, so read now rather than a second from now.
      if (run != _run && _timer != null) unawaited(_read());
    }
  }

  @override
  void dispose() {
    stop();
    _disposed = true;
    super.dispose();
  }
}

/// One reading of the file: `v`, the counter for everything, and `t`, one per
/// topic. Anything else in it is ignored.
class _Counters {
  const _Counters(this.v, this.topics);

  final int v;
  final Map<String, int> topics;

  /// Null for anything that is not the counters: no `v`, or a `t` that is
  /// not a map (PHP writes an empty one as `[]`, which is allowed).
  static _Counters? parse(Object? body) {
    if (body is! Map) return null;
    final v = JsonRead.integer(body['v']);
    if (v == null) return null;
    final raw = body['t'];
    final topics = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final count = JsonRead.integer(entry.value);
        if (count != null) topics[entry.key.toString()] = count;
      }
    } else if (!(raw == null || (raw is List && raw.isEmpty))) {
      return null;
    }
    return _Counters(v, topics);
  }

  /// The topics whose counter differs from [last]'s, a new one included.
  Set<String> movedSince(_Counters last) => {
    for (final topic in {...topics.keys, ...last.topics.keys})
      if (topics[topic] != last.topics[topic]) topic,
  };
}
