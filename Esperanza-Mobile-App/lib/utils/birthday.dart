import 'package:shared_preferences/shared_preferences.dart';
import '../models/citizen_account.dart';

/// The citizen's birthday, worked out on the phone from the signed-in
/// account's own birthdate, for the private greeting card that leads Balita
/// on that day. Nothing about it is sent to the server. (The birthday pop-up
/// over Home is the server's since 2026-10-21: it knows the birthdate and
/// sends that pop-up itself.)
class Birthday {
  Birthday._();

  /// Today, swappable so tests can choose the day.
  static DateTime Function() today = DateTime.now;

  /// The birthdate as the server sends it (`1990-06-08`, or an ISO
  /// timestamp) or as an older demo account stored it (`June 8, 1990`).
  static DateTime? of(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final parts = text.replaceAll(',', '').split(' ');
    if (parts.length != 3) return null;
    final month = months.indexOf(parts[0]) + 1;
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month == 0 || day == null || year == null) return null;
    return DateTime(year, month, day);
  }

  /// Whether [day] is the birthday. A 29 February birthday is kept on
  /// 28 February in a year that has no 29th.
  static bool falls(DateTime birth, DateTime day) {
    if (birth.month == day.month && birth.day == day.day) return true;
    final leap = DateTime(day.year, 2, 29).month == 2;
    return birth.month == 2 && birth.day == 29 && !leap && day.month == 2 && day.day == 28;
  }

  /// Whether today is [account]'s birthday.
  static bool isToday(CitizenAccount? account) {
    if (account == null) return false;
    final birth = of(account.birthdate);
    return birth != null && falls(birth, today());
  }

  /// Whether [what] (the greeting card) was already put away on
  /// this birthday, for this account, on this phone.
  static Future<bool> doneThisYear(String what, CitizenAccount account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key(what, account)) == '${today().year}';
    } catch (_) {
      return false;
    }
  }

  /// Remembers that [what] was put away on this birthday.
  static Future<void> markDone(String what, CitizenAccount account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(what, account), '${today().year}');
    } catch (_) {
      // Not remembered: it may show again today.
    }
  }

  static String _key(String what, CitizenAccount account) => 'birthday_$what.${account.id}';
}
