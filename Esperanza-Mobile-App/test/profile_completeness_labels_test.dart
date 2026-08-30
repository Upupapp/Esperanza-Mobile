// The app tracks TWO completeness figures. They must never both be "Profile".
//
// `account.profileCompleteness` counts four contact fields on the Edit Profile
// form — mobile, occupation, purok, barangay — from a 40% baseline.
//
// `ResidentProfile.overallCompletionPercent` weighs the Resident Profile's
// Personal / Family / Household sections.
//
// Both are correct, and they legitimately disagree: on the emulator the Home
// screen showed "Resident Profile 81%" and "Profile Complete 90%" one above the
// other, with nothing telling a citizen they measure different forms. Someone
// reading that reasonably concludes one of them is broken.
//
// Found by running the app, not by a test — which is the point. Nothing was
// numerically wrong, so no assertion about values would have caught it. This
// test guards the fix that did land: the labels now name the form each figure
// measures.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('the two completeness figures are labelled by the form they measure', () {
    final home = _read('lib/screens/home/home_screen.dart');

    // The account figure names the account form.
    expect(
      home,
      contains("label: 'Account Details'"),
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

  test('the two figures still come from different sources — this is not a merge', () {
    // If someone "fixes" the disagreement by pointing both at one value, the
    // app silently stops reporting one of the two things it tracks. The
    // disagreement is correct; only the labelling was wrong.
    expect(
      _read('lib/screens/home/home_screen.dart'),
      contains('account.profileCompleteness'),
      reason: 'the Home tile should still read the ACCOUNT figure',
    );
    expect(
      _read('lib/widgets/resident_profile_status_card.dart'),
      contains('overallCompletionPercent'),
      reason: 'the Resident Profile card should still read the RESIDENT figure',
    );
  });
}
