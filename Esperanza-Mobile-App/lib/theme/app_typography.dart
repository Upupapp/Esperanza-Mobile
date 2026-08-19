import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Font families and text styles mirroring the Web Admin's two `@theme`
/// font tokens: `--font-sans: Inter` (body/UI) and `--font-display: Lora`
/// (headings only, used sparingly — the Web Admin uses Inter for the vast
/// majority of headings too; Lora is reserved for a handful of ceremonial
/// / document-preview contexts).
class AppTypography {
  AppTypography._();

  static const sans = 'Inter';
  static const display = 'Lora';

  static const TextStyle h1 = TextStyle(
    fontFamily: sans,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: sans,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Card/list-tile title text — Balita post headers, request/notification
  /// tiles, evacuation-center rows, and similar "titled item" rows. Added
  /// after an audit found this exact (13, w600) pairing was already the
  /// plurality choice among several near-duplicate sizes (12.5/13/13.5)
  /// used for the same role — this names the value that already won,
  /// rather than introducing a new one.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// A quiet subsection label sitting above a group of related content
  /// (e.g. "Family Members", "Emergency Hotlines") — smaller and less
  /// prominent than [h3]'s full section titles, matching the dominant
  /// existing pattern for this specific role.
  static const TextStyle subsectionLabel = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.6,
  );

  static const TextStyle button = TextStyle(fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w500);

  /// Reserved for ceremonial contexts: document/certificate previews,
  /// official-looking headers — matches the Web Admin's narrow, deliberate
  /// use of Lora rather than a general heading font.
  static const TextStyle documentTitle = TextStyle(
    fontFamily: display,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
