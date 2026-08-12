import 'package:flutter/material.dart';

/// Reusable "New Request" floating action button, used by both Dokyu and
/// Tulong. Always sets an explicit white foreground: a FloatingActionButton
/// with a custom [backgroundColor] but no [foregroundColor] falls back to a
/// theme-derived dark color, which is unreadable against Esperanza's
/// saturated brand-blue / purple accents.
class NewRequestFab extends StatelessWidget {
  final Color accent;
  final VoidCallback onPressed;
  final String label;
  final Object heroTag;

  const NewRequestFab({
    super.key,
    required this.accent,
    required this.onPressed,
    required this.heroTag,
    this.label = 'New Request',
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      splashColor: Colors.white.withValues(alpha: 0.24),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
    );
  }
}
