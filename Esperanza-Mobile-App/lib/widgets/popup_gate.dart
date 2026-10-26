import 'package:flutter/foundation.dart';

/// One pop-up at a time, in the website's order: a Sakuna alert, then "You
/// are verified!", then an occasion or birthday greeting. True while one of
/// them is open; the others wait and look again once it closes. The alert or
/// the welcome could open on top of a greeting (parity check, 2026-10-26).
class PopupGate {
  PopupGate._();

  static final ValueNotifier<bool> open = ValueNotifier<bool>(false);
}
