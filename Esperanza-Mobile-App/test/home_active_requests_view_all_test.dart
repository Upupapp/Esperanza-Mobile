import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Home's Active Requests holds Dokyu and Tulong requests together, so its
// "View all" opens Track Requests (both kinds), not the Dokyu launcher: it
// opened Dokyu even when the active request was Tulong (2026-11-13).
void main() {
  test('Active Requests "View all" opens Track Requests, which lists Dokyu and Tulong', () {
    final home = File('lib/screens/home/home_screen.dart').readAsStringSync();
    final start = home.indexOf("title: 'Active Requests',");
    expect(start, greaterThan(0));
    final header = home.substring(start, home.indexOf('if (activeRequests.isEmpty)', start));

    expect(header, contains("actionLabel: activeRequests.isNotEmpty ? 'View all' : null,"));
    expect(header, contains('builder: (_) => const MyRequestsScreen()'));
    expect(header, isNot(contains('ServiceLauncherTarget.dokyu')));
  });
}
