import 'package:flutter/widgets.dart';

/// Endless decorative motion: a photograph's slow zoom, a button's shine, an
/// icon that bobs. Never information, so it is the first thing to go:
///
///  * under the platform's reduce-motion setting, for the person who asked;
///  * in widget tests, where `test/flutter_test_config.dart` turns it off,
///    because `pumpAndSettle` waits for every animation to end and these
///    never do.
///
/// Every finite transition (a page change, a card rising in) stays on either
/// way, tied to its own controller.
class AmbientMotion {
  AmbientMotion._();

  /// Switched off for the widget-test suite only.
  static bool enabled = true;

  static bool of(BuildContext context) => enabled && !MediaQuery.disableAnimationsOf(context);
}
