/// Guards every `_restore()` path against a stored value this build cannot read.
///
/// **Why this exists.** Each service restores itself from `shared_preferences`
/// in a future started from its constructor. Nothing awaits that future, so a
/// throw inside it is unhandled: the service's `loaded`/`loading` flag is never
/// flipped and `notifyListeners()` never fires. For [CitizenSessionService] the
/// consequence is exact — `AuthGate` renders a `CircularProgressIndicator`
/// forever and only clearing app data recovers it.
///
/// That is reachable by ordinary upgrade, not by tampering. This app already
/// ships five migrations for persisted data whose shape changed, and every one
/// of them runs *after* the `fromJson` that would already have thrown.
///
/// The contract here is: a restore may lose data, but it must never fail to
/// finish. Callers pair these helpers with a `finally` that sets the loaded
/// flag, so the flag flips on every path including an unexpected one.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';



/// Reads [key] and JSON-decodes it.
///
/// Returns `null` when the key is absent, and also when its value cannot be
/// decoded — in which case the key is **removed**, because a value this build
/// cannot read will not become readable on the next launch and would otherwise
/// fail identically forever.
///
/// Clearing a key is a data-loss event for that citizen, so it is reported in
/// debug and kept as narrow as possible: only the offending key is removed,
/// never the whole store.
Future<Object?> readJsonGuarded(SharedPreferences prefs, String key) async {
  final raw = prefs.getString(key);
  if (raw == null) return null;
  try {
    return jsonDecode(raw) as Object;
  } catch (error, stack) {
    debugPrint('persistence: dropping unreadable value at "$key" — $error');
    debugPrintStack(stackTrace: stack, maxFrames: 4);
    await prefs.remove(key);
    return null;
  }
}

/// Decodes [source] entry by entry, skipping any entry that cannot be read.
///
/// One unreadable record must not cost a citizen the rest of their history, so
/// this deliberately does **not** fail the whole collection. A skipped entry is
/// reported with a count rather than silently swallowed — a restore that
/// quietly loses half its records is its own kind of defect.
///
/// This is also why several enums here have no `orElse`. For
/// [ServiceCategory] an invented default would file a request under the wrong
/// service, and for [ReceiptType] it would make a false statement about money.
/// Skipping the record is honest; guessing it is not. Where a genuinely neutral
/// value exists — [AttachmentCategory.other] — that value is used instead.
List<T> decodeEachGuarded<T>(
  Iterable<dynamic> source,
  T Function(dynamic entry) decode, {
  required String what,
}) {
  final decoded = <T>[];
  var skipped = 0;
  for (final entry in source) {
    try {
      decoded.add(decode(entry));
    } catch (error) {
      skipped++;
      debugPrint('persistence: skipping unreadable $what entry — $error');
    }
  }
  if (skipped > 0) {
    debugPrint('persistence: skipped $skipped of ${skipped + decoded.length} $what entries');
  }
  return decoded;
}

/// [decodeEachGuarded] for a `Map` payload keyed by id.
Map<String, V> decodeEntriesGuarded<V>(
  Map<String, dynamic> source,
  V Function(dynamic value) decode, {
  required String what,
}) {
  final decoded = <String, V>{};
  var skipped = 0;
  source.forEach((key, value) {
    try {
      decoded[key] = decode(value);
    } catch (error) {
      skipped++;
      debugPrint('persistence: skipping unreadable $what entry "$key" — $error');
    }
  });
  if (skipped > 0) {
    debugPrint('persistence: skipped $skipped of ${skipped + decoded.length} $what entries');
  }
  return decoded;
}
