import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'persistence_guard.dart';

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
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawRead = await readJsonGuarded(prefs, _readKey);
      if (rawRead is List) {
        _readIds = rawRead.whereType<String>().toSet();
      }
      final rawDuplicate = await readJsonGuarded(prefs, _duplicateKey);
      if (rawDuplicate is Map) {
        _duplicateResolutions = <String, String>{
          for (final entry in rawDuplicate.entries)
            if (entry.key is String && entry.value is String) entry.key as String: entry.value as String,
        };
      }
      _unverifiedDuplicateKeptAccountId = prefs.getString(_unverifiedDuplicateKey);
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readKey, jsonEncode(_readIds.toList()));
    await prefs.setString(_duplicateKey, jsonEncode(_duplicateResolutions));
    if (_unverifiedDuplicateKeptAccountId != null) {
      await prefs.setString(_unverifiedDuplicateKey, _unverifiedDuplicateKeptAccountId!);
    }
  }

  bool isRead(String id) => _readIds.contains(id);

  /// Whether any of [ids] (the notification feed's current full ID set)
  /// is still unread — what the bell's red dot and the notification list
  /// both key off of.
  bool hasUnread(Iterable<String> ids) => ids.any((id) => !_readIds.contains(id));

  Future<void> markRead(String id) async {
    if (_readIds.contains(id)) return;
    _readIds = {..._readIds, id};
    notifyListeners();
    await _persist();
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
  /// (the Verified-Cristy scenario's own state) — see
  /// MockCatalog.unverifiedDuplicateAccountA's doc comment.
  String? get unverifiedDuplicateKeptAccountId => _unverifiedDuplicateKeptAccountId;

  Future<void> resolveUnverifiedDuplicate(String keptAccountId) async {
    _unverifiedDuplicateKeptAccountId = keptAccountId;
    notifyListeners();
    await _persist();
  }
}
