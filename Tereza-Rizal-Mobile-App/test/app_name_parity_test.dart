// The name under the icon must be the same on Android and iOS, and must fit.
//
// A sixteen-character launcher name was measured truncating in the Pixel 8
// drawer, while neighbouring apps ("Play Store", "Messages", "Calendar") fit.
// The home-screen name is therefore capped at 13 characters. `Tereza, Rizal`
// is that name on Android (`android:label`) and iOS (`CFBundleDisplayName`).
// The same string is the product name where length is not constrained: the
// web manifest `name` and the browser tab title.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The name shown under the launcher icon. One string, both platforms.
const _homeScreenName = 'Tereza, Rizal';

/// The full product name, used where length is not constrained.
const _productName = 'Tereza, Rizal';

/// Measured budget: a 16-character launcher name truncated in the Pixel 8
/// drawer. If a longer name is ever wanted, re-measure on a launcher and move
/// this with the evidence, rather than deleting it.
const _maxHomeScreenNameLength = 13;

String _androidLabel() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final match = RegExp(r'android:label="([^"]*)"').firstMatch(manifest);
  expect(match, isNotNull, reason: 'no android:label found in AndroidManifest.xml');
  return match!.group(1)!;
}

String _iosDisplayName() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  // <key>CFBundleDisplayName</key> followed by its <string> value.
  final match = RegExp(
    r'<key>CFBundleDisplayName</key>\s*<string>([^<]*)</string>',
    multiLine: true,
  ).firstMatch(plist);
  expect(match, isNotNull, reason: 'no CFBundleDisplayName found in Info.plist');
  return match!.group(1)!.trim();
}

void main() {
  test('Android and iOS show the same name under the icon', () {
    expect(
      _androidLabel(),
      _iosDisplayName(),
      reason: 'the home-screen name differs between platforms — it is one product, one name',
    );
  });

  test('that name is the one the owner chose', () {
    expect(_androidLabel(), _homeScreenName);
    expect(_iosDisplayName(), _homeScreenName);
  });

  test('the name is not a scaffold identifier', () {
    for (final name in [_androidLabel(), _iosDisplayName()]) {
      expect(name, isNot(contains('_')), reason: '"$name" looks like a package id, not a product name');
      expect(name.toLowerCase(), isNot('tereza_rizal'));
      expect(name.trim(), isNotEmpty);
    }
  });

  test('the name fits a launcher grid', () {
    expect(
      _homeScreenName.length,
      lessThanOrEqualTo(_maxHomeScreenNameLength),
      reason: 'a 16-character launcher name truncated in the Pixel 8 drawer',
    );
  });

  test('the full product name survives where there is room', () {
    // Shortening the home-screen name must not quietly shorten the product
    // everywhere — the store listing and the PWA install prompt use these.
    final manifest = File('web/manifest.json').readAsStringSync();
    expect(manifest, contains('"name": "$_productName"'));
    expect(manifest, contains('"short_name": "$_homeScreenName"'));

    final index = File('web/index.html').readAsStringSync();
    expect(index, contains('<title>$_productName</title>'));
    // "Add to Home Screen" on iOS Safari is a home screen, so it takes the short one.
    expect(index, contains('content="$_homeScreenName"'));
  });

  test('CFBundleName stays within Apple\'s 15-character guidance', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final match = RegExp(r'<key>CFBundleName</key>\s*<string>([^<]*)</string>').firstMatch(plist);
    expect(match, isNotNull);
    expect(match!.group(1)!.length, lessThanOrEqualTo(15));
  });
}
