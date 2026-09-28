import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'json_read.dart';
import 'persistence_recovery.dart';

/// Tracks which notifications a citizen has already opened/viewed — the
/// notification feed itself is entirely *derived* live from other services
/// (request status history, profile completion, illustrative sample
/// content — see notification_feed.dart), so there's no stored "list of
/// notifications" anywhere; this service only remembers a set of stable
/// notification IDs the citizen has already seen, same SharedPreferences
/// persistence pattern as every other local "database" in this app
/// (RequestsService, BalitaService, etc).
///
/// Also carries the Phase 6 duplicate-account demo's resolution state
/// ('confirmed' / 'reported', keyed by scenario id 'a'/'b') — folded into
/// this existing service rather than a new provider, since
/// [NotificationsService] is already threaded through every screen via
/// `AlertsAction`'s bell icon, so nothing else needs a new provider
/// registered just to read/react to it.
class NotificationsService extends ChangeNotifier {
  static const _readKey = 'esperanza_read_notification_ids';
  static const _duplicateKey = 'esperanza_duplicate_alert_resolutions';
  static const _unverifiedDuplicateKey = 'esperanza_unverified_duplicate_kept_account';

  Set<String> _readIds = {};
  Map<String, String> _duplicateResolutions = {};
  String? _unverifiedDuplicateKeptAccountId;
  bool _loaded = false;

  bool get loaded => _loaded;

  NotificationsService() {
    ApiClient.addSessionExpiredListener(_clearServer);
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawRead = prefs.getString(_readKey);
      if (rawRead != null) {
        _readIds = (jsonDecode(rawRead) as List).cast<String>().toSet();
      }
      final rawDuplicate = prefs.getString(_duplicateKey);
      if (rawDuplicate != null) {
        _duplicateResolutions = Map<String, String>.from(jsonDecode(rawDuplicate) as Map);
      }
      _unverifiedDuplicateKeptAccountId = prefs.getString(_unverifiedDuplicateKey);
    } catch (error) {
      // A payload persisted by an earlier build can fail to decode after a
      // model or enum changes shape. Before this guard that throw escaped an
      // un-awaited future started in the constructor, so notifyListeners()
      // never fired and AuthGate spun on the splash forever - recoverable
      // only by clearing app data. Discard the unreadable state instead; the
      // migrations here already exist for exactly this class of change.
      _readIds = {};
      _duplicateResolutions = {};
      _unverifiedDuplicateKeptAccountId = null;
      // This service owns three keys and cannot tell which one failed, so all
      // three go. Splitting the restore per key would narrow it further; that is
      // a deliberate follow-up, not an oversight.
      await PersistenceRecovery.discardUnreadable(
        service: 'NotificationsService',
        keys: const [_readKey, _duplicateKey, _unverifiedDuplicateKey],
        error: error,
      );
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Clears read-state and duplicate-resolution bookkeeping on sign-out.
  ///
  /// Unlike the other services this is not keyed by account: read ids point at
  /// notifications derived from the requests being erased alongside them, so
  /// keeping them would leave orphaned references to a citizen who has signed
  /// out. Clearing all of it is both the private and the correct choice.
  Future<void> forgetAccount(String accountId) async {
    _server = [];
    _readIds = {};
    _duplicateResolutions = {};
    _unverifiedDuplicateKeptAccountId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readKey);
    await prefs.remove(_duplicateKey);
    await prefs.remove(_unverifiedDuplicateKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readKey, jsonEncode(_readIds.toList()));
    await prefs.setString(_duplicateKey, jsonEncode(_duplicateResolutions));
    if (_unverifiedDuplicateKeptAccountId != null) {
      await prefs.setString(_unverifiedDuplicateKey, _unverifiedDuplicateKeptAccountId!);
    }
  }

  // ---- Server notifications (GET /citizen/notifications) ----------------
  //
  // The backend writes one for every request status change, flagged document
  // and account review (esperanza-backend NotificationService). They are the
  // source of truth for "what happened"; read state lives on the server too.

  List<ServerNotification> _server = [];
  List<ServerNotification> get serverNotifications => List.unmodifiable(_server);

  /// Newest first, pinned first (the server's order). Failures leave the
  /// previous list in place: a flaky connection must not blank the bell.
  Future<void> loadServer() async {
    final rows = await api.getAllPages('/citizen/notifications', query: {'per_page': 100}, maxPages: 3);
    _server = JsonRead.rows(rows, ServerNotification.fromApi);
    notifyListeners();
  }

  void _clearServer() {
    if (_server.isEmpty) return;
    _server = [];
    notifyListeners();
  }

  @override
  void dispose() {
    ApiClient.removeSessionExpiredListener(_clearServer);
    super.dispose();
  }

  ServerNotification? _serverById(String id) {
    for (final n in _server) {
      if (n.feedId == id) return n;
    }
    return null;
  }

  bool isRead(String id) => _readIds.contains(id) || (_serverById(id)?.unread == false);

  /// Whether any of [ids] (the notification feed's current full ID set)
  /// is still unread — what the bell's red dot and the notification list
  /// both key off of.
  bool hasUnread(Iterable<String> ids) => ids.any((id) => !isRead(id));

  Future<void> markRead(String id) async {
    if (isRead(id)) return;
    _readIds = {..._readIds, id};
    final server = _serverById(id);
    if (server != null) server.unread = false;
    notifyListeners();
    await _persist();
    if (server != null) {
      try {
        await api.post('/citizen/notifications/${server.id}/read');
      } on ApiException {
        // Kept read locally; the next load re-syncs from the server.
      }
    }
  }

  /// 'confirmed' (Yes, this is me), 'reported' (No, this is not me), or
  /// null if [scenarioId] hasn't been resolved yet — see
  /// screens/notifications/duplicate_account_details_screen.dart.
  String? duplicateResolutionFor(String scenarioId) => _duplicateResolutions[scenarioId];

  Future<void> resolveDuplicateAlert(String scenarioId, String resolution) async {
    _duplicateResolutions = {..._duplicateResolutions, scenarioId: resolution};
    notifyListeners();
    await _persist();
  }

  /// The Unverified+Unverified duplicate demo's own resolution — 'A', 'B',
  /// or null if the citizen hasn't chosen which registration to keep yet.
  /// Independent of [duplicateResolutionFor]/[resolveDuplicateAlert] above
  /// (the Verified-Perlita scenario's own state) — see
  /// MockCatalog.unverifiedDuplicateAccountA's doc comment.
  String? get unverifiedDuplicateKeptAccountId => _unverifiedDuplicateKeptAccountId;

  Future<void> resolveUnverifiedDuplicate(String keptAccountId) async {
    _unverifiedDuplicateKeptAccountId = keptAccountId;
    notifyListeners();
    await _persist();
  }
}

/// One row of GET /citizen/notifications (ModuleController::notifications()).
class ServerNotification {
  ServerNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.pill,
    required this.ref,
    this.link,
    required this.unread,
    required this.pinned,
    required this.at,
  });

  final int id;
  final String? category;
  final String title;
  final String body;

  /// The status the notification is about (`Approved`, `Under Review`, ...),
  /// when it is about one.
  final String? pill;

  /// The reference it concerns: a request, but also an account number, a
  /// support ticket or a payment. Never assume it is a request: [link] says
  /// what it is.
  final String? ref;

  /// Where the backend says it leads (`/citizen/document-requests/DR-...`,
  /// `/citizen/profile`, `/citizen/help/support`, ...).
  final String? link;
  bool unread;
  final bool pinned;
  final DateTime at;

  String get feedId => 'srv-$id';

  /// Bilingual on the wire (`{fil, en}`); Filipino first, like every other
  /// server message the app shows (ApiException.message()).
  static String _text(Object? v) {
    final m = JsonRead.map(v);
    if (m != null) return JsonRead.nonEmpty(m['fil']) ?? JsonRead.nonEmpty(m['en']) ?? '';
    return JsonRead.string(v) ?? '';
  }

  static ServerNotification? fromApi(Map<String, dynamic> json) {
    final id = JsonRead.integer(json['id']);
    final title = _text(json['title']);
    if (id == null || title.isEmpty) return null;
    return ServerNotification(
      id: id,
      category: JsonRead.nonEmpty(json['category']),
      title: title,
      body: _text(json['body']),
      pill: JsonRead.nonEmpty(json['pill']),
      ref: JsonRead.nonEmpty(json['ref']),
      link: JsonRead.nonEmpty(json['link']),
      unread: JsonRead.boolean(json['unread']) ?? true,
      pinned: JsonRead.boolean(json['pinned']) ?? false,
      at: JsonRead.date(json['time'])?.toLocal() ?? DateTime.now(),
    );
  }
}
