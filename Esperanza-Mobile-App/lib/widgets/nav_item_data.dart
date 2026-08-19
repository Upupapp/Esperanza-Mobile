import 'package:flutter/material.dart';

/// Describes a single bottom navigation destination — the outline icon
/// shown at rest in the bar's base row, the filled icon shown inside the
/// floating active bubble, and the label shown only while that
/// destination is the active/transitioning one.
class NavItemData {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;

  const NavItemData({required this.outlineIcon, required this.filledIcon, required this.label});
}
