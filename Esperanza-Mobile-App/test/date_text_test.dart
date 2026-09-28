// One date style for citizens, always in the phone's local time
// (lib/utils/date_text.dart).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/utils/date_text.dart';

void main() {
  test('month-name style, date and time', () {
    final local = DateTime(2026, 9, 24, 8, 30);
    expect(shortDate(local), 'Sep 24, 2026');
    expect(dateAndTime(local), 'Sep 24, 2026, 8:30 AM');
  });

  test('a server UTC timestamp is shown in local time', () {
    final utc = DateTime.utc(2026, 9, 24, 0, 30);
    expect(dateAndTime(utc), dateAndTime(utc.toLocal()));
    expect(shortDate(utc), shortDate(utc.toLocal()));
  });

  test('no screen prints its own numeric M/D/Y date any more', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      if (f.readAsStringSync().contains(r'${d.month}/${d.day}/${d.year}')) offenders.add(f.path);
    }
    expect(offenders, isEmpty);
  });
}
