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

  // =====================================================================
  // THE STANDARD SCALE — use these for all new and touched code.
  //
  // Eight roles, the web platform's own (resources/css/app.css `.type-*`),
  // sized for a phone: the two desktop-only steps (display 36, page 28) come
  // down one notch, everything from card title to label matches the web
  // exactly. Every style carries its line height, so a block of text has the
  // same rhythm on both platforms. Sizes are whole points only: 11 is the
  // floor for anything a citizen must read. See docs/DESIGN_GUIDELINES.md §3.
  //
  // The older names below (h1–h3, body, caption, the half-point sizes) stay
  // so existing screens do not shift; the guideline maps each to its role.
  // =====================================================================

  /// Hero numbers and splash headlines. Web `type-display`/`type-kpi` (32/40).
  static const TextStyle displayTitle = TextStyle(
    fontFamily: sans,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// One per screen, when the AppBar title is not enough. Web page title.
  static const TextStyle pageTitle = TextStyle(
    fontFamily: sans,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// Section headings within a screen. Web `type-section-title` (20/28, 700).
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: sans,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Card and sheet titles. Web `type-card-title` (16/24, 600).
  static const TextStyle cardHeading = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Running text. Web `type-body` (14/22, 400).
  static const TextStyle bodyText = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
  );

  /// Secondary lines, list subtitles, form help. Web `type-helper` (13/20).
  static const TextStyle helper = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Field labels, badges, tab labels, metadata. Web `type-label` (12/16,
  /// 600, +0.02em).
  static const TextStyle labelText = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.24,
    color: AppColors.textBody,
  );

  /// Small caps-style section markers ("RECENT REQUESTS"). Web
  /// `type-eyebrow` (+0.08em, uppercase — apply `.toUpperCase()` to the
  /// string; Flutter has no text-transform).
  static const TextStyle eyebrow = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.88,
    color: AppColors.textMuted,
  );

  /// The floor: timestamps, legal footnotes, nav labels. Nothing smaller.
  static const TextStyle fine = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// The one serif: official-document titles and the wordmark (Lora).
  static const TextStyle documentHeading = TextStyle(
    fontFamily: display,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // =====================================================================
  // Existing styles (pre-standard). Keep for current screens; do not use in
  // new code — see the migration map in docs/DESIGN_GUIDELINES.md §3.
  // =====================================================================

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

  // ---------------------------------------------------------------------
  // The half-point scale.
  //
  // Measured 2026-08-29 (FE 06): of 412 hardcoded `fontSize:` literals in
  // lib/, **177 are half-point sizes this class had no value for at all** —
  // 12.5 alone appears 90 times, making it the most-used size in the app.
  // The bypass rate was not carelessness; the token set genuinely could not
  // express the size people needed, so they wrote the number.
  //
  // These name the sizes that already won, in the weights they already use,
  // rather than introducing new values. 2026-09-28: snapped to whole points
  // (12.5→13, 13.5→14, 11.5→12, 10.5→11) with the design standard; the names
  // stay so call sites keep compiling, but new code uses the role styles. Each carries no `color` so a call
  // site can `.copyWith(color:)` from AppColors without fighting a default.
  // ---------------------------------------------------------------------

  /// 13 (was 12.5) / w400 — running text at the compact size. Note this is the DEFAULT
  /// weight: a bare `TextStyle(fontSize: 12.5)` is w400, so migrating one to
  /// [bodySmall] (w600) would silently embolden it. Both exist for that reason.
  static const TextStyle bodySmallRegular = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// 13 (was 12.5) / w600 — the app's most common size, by a wide margin. Dense row
  /// labels, chip text, compact metadata.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// 13 (was 12.5) / w500 — the same size at normal emphasis.
  static const TextStyle bodySmallMedium = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// 14 (was 13.5) / w600 — section and field labels a step above [bodySmall].
  static const TextStyle label = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// 14 (was 13.5) / w700 — the emphatic form of [label]; equally common in practice.
  static const TextStyle labelStrong = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  /// 12 (was 11.5) / w400 — the default-weight form; see [bodySmallRegular] on why the
  /// regular variants exist separately.
  static const TextStyle captionSmallRegular = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// 12 (was 11.5) / w600 — the smallest size used for real content: badge text,
  /// timestamps, helper lines.
  static const TextStyle captionSmall = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  /// 11 (was 10.5) / w600 — navigation labels and the tightest chrome. Below this,
  /// reconsider the layout rather than the type.
  static const TextStyle micro = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w600,
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

  /// 28 / w700 — one step above [h1], for a full-screen moment that owns the
  /// whole viewport rather than a section of one: the first-run onboarding
  /// headlines. [h1] at 24 is tuned for a screen title sitting above content;
  /// at hero scale it reads as a heading that forgot it was the only thing
  /// there.
  ///
  /// Added rather than written inline as `fontSize: 28` because
  /// `design_token_discipline_test.dart` says exactly that: "Add the style, do
  /// not add the number." Inter, not Lora — see [wordmark] for where Lora
  /// belongs.
  static const TextStyle hero = TextStyle(
    fontFamily: sans,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
    height: 1.16,
  );

  /// 13 / w600 / Lora — the municipal wordmark beside the seal.
  ///
  /// The one ceremonial role that recurs across entry screens (splash,
  /// onboarding, sign-in) rather than a one-off: "Municipalidad ng Esperanza"
  /// set in the display face while every other word on the same screen stays
  /// in Inter. Named so those screens stop each writing their own size.
  static const TextStyle wordmark = TextStyle(
    fontFamily: display,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.6,
  );

  static const TextStyle button = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

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

/// The standard scale as bare sizes, for the inline `TextStyle(fontSize: …)`
/// and `.copyWith(fontSize: …)` that a role style cannot replace outright
/// (a coloured count, a one-off weight). Same roles as [AppTypography]; see
/// docs/DESIGN_GUIDELINES.md §3. Never write a number instead.
class AppTextSize {
  AppTextSize._();

  static const double display = 32;
  static const double page = 24;
  static const double section = 20;
  static const double card = 16;
  static const double body = 14;
  static const double helper = 13;
  static const double label = 12;
  static const double fine = 11;
}
