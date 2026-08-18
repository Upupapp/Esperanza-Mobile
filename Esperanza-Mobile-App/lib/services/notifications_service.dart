import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which notifications a citizen has already opened/viewed — the
/// notification feed itself is entirely *derived* live from other services
/// (request status history, profile completion, illustrative sample
/// content — see notification_feed.dart), so there's no stored "list of
/// notifications" anywhere; this service only remembers a set of stable
/// notification IDs the citizen has already seen, same SharedPreferences
/// persistence pattern as every other local "database" in this app
/// (RequestsService, BalitaService, etc).
class NotificationsService extends ChangeNotifier {
  static const _key = 'esperanza_read_notification_ids';

  Set<String> _readIds = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  NotificationsService() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _readIds = (jsonDecode(raw) as List).cast<String>().toSet();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_readIds.toList()));
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
}
