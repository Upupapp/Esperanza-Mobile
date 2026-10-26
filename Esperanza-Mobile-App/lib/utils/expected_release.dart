/// The date a request is expected to be ready, as the website works it out
/// (document-requests / assistance-requests `expectedRelease`): from the
/// service's processing time ("Same day", "3 working days", "5 days"), the
/// last number in it, counting working days without Saturdays and Sundays.
/// Five days when the time names no number. Null without a processing time.
DateTime? expectedRelease(DateTime submitted, String? processingDays) {
  final days = processingDays?.trim() ?? '';
  if (days.isEmpty) return null;
  final start = DateTime(submitted.year, submitted.month, submitted.day);
  if (RegExp('same day', caseSensitive: false).hasMatch(days)) return start;
  final numbers = RegExp(r'\d+').allMatches(days).toList();
  var left = numbers.isEmpty ? 5 : int.parse(numbers.last.group(0)!);
  var d = start;
  if (RegExp('working', caseSensitive: false).hasMatch(days)) {
    while (left > 0) {
      d = DateTime(d.year, d.month, d.day + 1);
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) left--;
    }
    return d;
  }
  return DateTime(d.year, d.month, d.day + left);
}
