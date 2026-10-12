import 'package:flutter/material.dart';
import '../widgets/esperanza_art.dart';

/// A simple, lightweight cross-fade page transition — built entirely on
/// Flutter's own `PageRouteBuilder` (no animation package) — used for the
/// splash -> onboarding -> AuthGate handoffs so the Esperanza branding
/// feels like one continuous transition rather than an abrupt cut between
/// screens. [duration] is longer where something flies between the two
/// (the seal, opening screen to welcome pages).
PageRouteBuilder<T> fadePageRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 400)}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    // The soft page backdrop under the page, as every themed route has
    // (BackdropPageTransitionsBuilder): scaffolds are clear, and without it
    // a tab reached through this route showed black.
    pageBuilder: (context, animation, secondaryAnimation) => GlassBackdrop(child: page),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
