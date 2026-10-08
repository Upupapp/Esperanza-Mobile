import 'package:flutter/material.dart';

/// Shadow tokens. Originally the Web Admin's `--shadow-card`,
/// `--shadow-card-hover` and `--shadow-float`; the 2026-10 refresh softens
/// them into wide, navy-tinted glows (navy900 #0B1730 at low alpha, never a
/// new colour) so cards float on the page instead of sitting on a hairline.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A0B1730), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x140B1730), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -8),
  ];

  static const List<BoxShadow> cardHover = [
    BoxShadow(color: Color(0x1F0B1730), blurRadius: 28, offset: Offset(0, 12), spreadRadius: -8),
    BoxShadow(color: Color(0x0F0B1730), blurRadius: 6, offset: Offset(0, 2), spreadRadius: -2),
  ];

  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x2E0B1730), blurRadius: 32, offset: Offset(0, 12), spreadRadius: -8),
  ];

  /// The warm glow under a gold primary button (gold400 #ECC02A).
  static const List<BoxShadow> gold = [
    BoxShadow(color: Color(0x59ECC02A), blurRadius: 16, offset: Offset(0, 6), spreadRadius: -4),
  ];
}
