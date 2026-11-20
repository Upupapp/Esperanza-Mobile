import 'package:intl/intl.dart';

import '../services/message_language.dart';

/// The one way the app writes a date or a time for a citizen.
///
/// The request screens each had their own formatter printing `9/24/2026 00:30`
/// straight from the server's UTC timestamp, so a request filed at 8:30 AM in
/// Esperanza read as half past midnight, and one filed before 8 AM carried the
/// previous day's date. Everything here converts to the phone's local time
/// first (a no-op for a value that is already local) and uses the same
/// month-name style as the rest of the app ("Sep 24, 2026").

/// `Sep 24, 2026`
String shortDate(DateTime d) => DateFormat('MMM d, y').format(d.toLocal());

/// `Sep 24, 2026, 8:30 AM`
String dateAndTime(DateTime d) => DateFormat('MMM d, y, h:mm a').format(d.toLocal());

/// "Just now" / "12 mins ago" / "3 hrs ago", then [shortDate] beyond a day:
/// the same thresholds as the Web Admin's own `fmtTime`. In Filipino, the
/// website's wording ("10 oras ang nakalipas"; 20 Nov: it stayed English).
String timeAgo(DateTime d, {DateTime? now}) {
  final fil = MessageLanguage.filipino.value;
  final minutes = (now ?? DateTime.now()).difference(d).inMinutes;
  if (minutes < 1) return fil ? 'Ngayon lang' : 'Just now';
  if (minutes < 60) return fil ? '$minutes minuto ang nakalipas' : '$minutes min${minutes == 1 ? '' : 's'} ago';
  final hours = (minutes / 60).round();
  if (hours < 24) return fil ? '$hours oras ang nakalipas' : '$hours hr${hours == 1 ? '' : 's'} ago';
  return shortDate(d);
}
