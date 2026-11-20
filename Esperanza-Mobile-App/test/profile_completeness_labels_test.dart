// One completeness figure (20 Nov 2026): the website showed 75% and the app's
// Resident Profile card 79% for the same account, because the card weighed its
// own Personal / Family / Household sections. Every percentage a resident sees
// is now the server's profile_completeness (ProfileCompleteness on the backend),
// which the website shows too. The labels still name the form each place sits on.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('the two completeness figures are labelled by the form they measure', () {
    final home = _read('lib/screens/home/home_screen.dart');

    // The account figure names the account form.
    expect(
      home,
      contains("label: tr('Account Details')"),
      reason: 'the account.profileCompleteness tile must say which form it measures',
    );

    // And must not reclaim the generic name that caused the collision.
    expect(
      home,
      isNot(contains("label: 'Profile Complete'")),
      reason: '"Profile Complete" sat next to "Resident Profile" showing a different number',
    );
  });

  test('the profile screen names it too', () {
    final profile = _read('lib/screens/profile/profile_screen.dart');
    expect(profile, contains('Account details '));
    expect(
      profile,
      isNot(contains("'Profile \${account.profileCompleteness}% complete'")),
      reason: 'same ambiguity, same fix',
    );
  });

  test('every completeness percentage reads the server figure', () {
    expect(_read('lib/screens/home/home_screen.dart'), contains('percent: account.profileCompleteness'));
    expect(_read('lib/screens/profile/profile_screen.dart'), contains('percent: account.profileCompleteness'));
    expect(
      _read('lib/screens/profile/resident_profile/resident_profile_overview_screen.dart'),
      contains('_ProgressCard(profile: profile, percent: account.profileCompleteness)'),
    );
    expect(_read('lib/widgets/resident_profile_status_card.dart'), contains('percent ?? profile.overallCompletionPercent'));
  });
}
