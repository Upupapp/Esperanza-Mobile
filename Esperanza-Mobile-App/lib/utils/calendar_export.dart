import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_dialogs.dart';

/// Something to put on the phone's calendar: an appointment or an event.
class CalendarEntry {
  const CalendarEntry({
    required this.uid,
    required this.title,
    required this.date,
    this.time,
    this.place,
    this.description,
  });

  /// Stable, so adding it twice updates the one calendar entry.
  final String uid;
  final String title;

  /// The day, in Esperanza.
  final DateTime date;

  /// Free text: '08:00', '8:00 AM - 5:00 PM', '09:00-09:30'. None: all day.
  final String? time;
  final String? place;
  final String? description;
}

/// Add to calendar, as the website does it (parity, 2026-10-15; the website's
/// scope-citizen.js buildIcs / googleCalendarUrl, ported line for line):
/// Esperanza time (UTC+8, no daylight saving), all day when there is no
/// time, one hour when only a start is given, and a reminder the day before.
class CalendarExport {
  CalendarExport._();

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _utcStamp(DateTime d) {
    final u = d.toUtc();
    return '${u.year}${_pad(u.month)}${_pad(u.day)}T${_pad(u.hour)}${_pad(u.minute)}${_pad(u.second)}Z';
  }

  /// Start and end, in minutes after midnight, of a free-text time.
  static ({int start, int end})? timeSpan(String? text) {
    final re = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*([ap])\.?\s*m\b\.?|(\d{1,2}):(\d{2})', caseSensitive: false);
    final found = <({int h, int min, String? mer})>[];
    for (final m in re.allMatches(text ?? '')) {
      if (found.length == 2) break;
      found.add(
        m.group(3) != null
            ? (h: int.parse(m.group(1)!), min: int.parse(m.group(2) ?? '0'), mer: m.group(3)!.toLowerCase())
            : (h: int.parse(m.group(4)!), min: int.parse(m.group(5)!), mer: null),
      );
    }
    if (found.isEmpty) return null;
    var a = found[0];
    final b = found.length > 1 ? found[1] : null;
    int minutes(({int h, int min, String? mer}) t) {
      var h = t.h % 24;
      if (t.mer == 'p' && h < 12) h += 12;
      if (t.mer == 'a' && h == 12) h = 0;
      return h * 60 + (t.min > 59 ? 59 : t.min);
    }

    // '8:00 - 11:00 AM': the first takes the second's AM/PM, unless that puts
    // it after the end ('11:00 - 1:00 PM').
    if (b != null && a.mer == null && b.mer != null) {
      a = (h: a.h, min: a.min, mer: b.mer);
      if (minutes(a) > minutes(b)) a = (h: a.h, min: a.min, mer: 'a');
    }
    final start = minutes(a);
    var end = b != null ? minutes(b) : start + 60;
    if (end <= start) end = b != null ? end + 1440 : start + 60;
    return (start: start, end: end);
  }

  /// iCalendar start and end: UTC times, or dates for an all-day entry.
  static ({bool allDay, String start, String end}) window(DateTime date, String? time) {
    final span = timeSpan(time);
    if (span == null) {
      final next = DateTime.utc(date.year, date.month, date.day + 1);
      return (
        allDay: true,
        start: '${date.year}${_pad(date.month)}${_pad(date.day)}',
        end: '${next.year}${_pad(next.month)}${_pad(next.day)}',
      );
    }
    // 8:00 in Esperanza is 00:00Z.
    String at(int mins) => _utcStamp(DateTime.utc(date.year, date.month, date.day, 0, mins - 480));
    return (allDay: false, start: at(span.start), end: at(span.end));
  }

  static String _text(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll(RegExp(r'\r?\n'), r'\n');

  /// RFC 5545: lines over 75 octets continue after one space.
  static String _fold(String line) {
    if (utf8.encode(line).length <= 75) return line;
    final out = <String>[];
    var cur = StringBuffer();
    var bytes = 0;
    for (final rune in line.runes) {
      final ch = String.fromCharCode(rune);
      final b = utf8.encode(ch).length;
      if (bytes + b > (out.isEmpty ? 75 : 74)) {
        out.add(cur.toString());
        cur = StringBuffer();
        bytes = 0;
      }
      cur.write(ch);
      bytes += b;
    }
    out.add(cur.toString());
    return out.join('\r\n ');
  }

  /// A one-entry calendar file with a reminder the day before.
  static String ics(CalendarEntry e, {DateTime? now}) {
    final w = window(e.date, e.time);
    final lines = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//LGU Esperanza//Citizen App//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:${e.uid}',
      'DTSTAMP:${_utcStamp(now ?? DateTime.now())}',
      '${w.allDay ? 'DTSTART;VALUE=DATE:' : 'DTSTART:'}${w.start}',
      '${w.allDay ? 'DTEND;VALUE=DATE:' : 'DTEND:'}${w.end}',
      'SUMMARY:${_text(e.title)}',
      if (e.place != null && e.place!.isNotEmpty) 'LOCATION:${_text(e.place!)}',
      if (e.description != null && e.description!.isNotEmpty) 'DESCRIPTION:${_text(e.description!)}',
      'BEGIN:VALARM',
      'ACTION:DISPLAY',
      'DESCRIPTION:${_text(e.title)}',
      'TRIGGER:-P1D',
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR',
    ];
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  static Uri googleCalendar(CalendarEntry e) {
    final w = window(e.date, e.time);
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': e.title,
      'dates': '${w.start}/${w.end}',
      'ctz': 'Asia/Manila',
      if (e.description != null && e.description!.isNotEmpty) 'details': e.description!,
      if (e.place != null && e.place!.isNotEmpty) 'location': e.place!,
    });
  }

  /// Offers Google Calendar or a calendar file for any other calendar app.
  static Future<void> offer(BuildContext context, CalendarEntry e) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add to calendar', style: AppTypography.cardHeading),
              const SizedBox(height: AppSpacing.xs),
              Text('A reminder comes the day before.', style: AppTypography.helper),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Google Calendar'),
                onTap: () => Navigator.of(context).pop('google'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Another calendar app'),
                subtitle: const Text('Shares a calendar file (.ics)'),
                onTap: () => Navigator.of(context).pop('ics'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    try {
      if (choice == 'google') {
        if (!await launchUrl(googleCalendar(e), mode: LaunchMode.externalApplication) && context.mounted) {
          AppDialogs.toast(context, 'Google Calendar could not be opened.', success: false);
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final slug = e.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
      final file = File('${dir.path}/${slug.isEmpty ? 'event' : slug}.ics');
      await file.writeAsString(ics(e));
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'text/calendar')], subject: e.title));
    } catch (_) {
      if (context.mounted) AppDialogs.toast(context, 'The calendar entry could not be made.', success: false);
    }
  }
}
