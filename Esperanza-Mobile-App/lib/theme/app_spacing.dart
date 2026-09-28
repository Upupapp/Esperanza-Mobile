/// Spacing scale — the web platform's rhythm (resources/css/app.css
/// `@theme`: 4/8/12/16/20/24/32/48), which is Tailwind's default numeric
/// scale. **Only these stops.** A 10, 14 or 6 is not a finer design, it is
/// drift; round to the nearest stop. See docs/DESIGN_GUIDELINES.md §4.
class AppSpacing {
  AppSpacing._();

  // ---- The scale -------------------------------------------------------
  static const double xs = 4; // micro   — icon↔label, badge insets
  static const double sm = 8; // compact — related items, chip gaps
  static const double md = 12; // sm      — list items, field↔helper
  static const double lg = 16; // base    — screen gutter, card padding
  static const double xl = 20; // card    — roomy card / sheet padding
  static const double xxl = 24; // section — between sections
  static const double xxxl = 32; // major   — before a primary action block
  static const double huge = 40; // legacy stop, kept for existing call sites
  static const double page = 48; // page    — top/bottom of empty states

  // ---- Roles: reach for these first; they say *why* ---------------------

  /// Left/right padding of every screen body.
  static const double screenGutter = lg;

  /// Inner padding of an [AppCard] and of list tiles.
  static const double cardPadding = lg;

  /// Inner padding of bottom sheets, dialogs and hero cards.
  static const double sheetPadding = xl;

  /// Vertical gap between two stacked cards or list rows.
  static const double itemGap = md;

  /// Vertical gap between form fields.
  static const double fieldGap = lg;

  /// Gap between sections (a heading and the previous block).
  static const double sectionGap = xxl;

  /// Gap between a section heading and its content.
  static const double headingGap = md;

  /// Gap between an icon and its label, or inline elements.
  static const double inlineGap = sm;

  /// Bottom padding below the last item of a scrolling screen, on top of the
  /// navbar inset from `MediaQuery.paddingOf(context).bottom`.
  static const double scrollEnd = xxl;
}

/// Corner radius — Tailwind's rounded-* steps as the web uses them.
class AppRadius {
  AppRadius._();

  static const double sm = 8; // rounded-lg  — chips, small tiles, thumbnails
  static const double md = 12; // rounded-xl  — buttons, inputs, list tiles
  static const double lg = 16; // rounded-2xl — cards, dialogs
  static const double xl = 20; // rounded-[20px] — bottom sheets, hero cards
  static const double full = 999; // rounded-full — pills, badges, avatars
}

/// Component sizing anchors, from the web's `--size-*` tokens. All
/// interactive sizes respect the 44 × 44 minimum touch target (WCAG 2.5.5,
/// Apple HIG); Android's 48 dp is met by [buttonHeightLg].
class AppSizes {
  AppSizes._();

  static const double minTouchTarget = 44;

  static const double buttonHeight = 44;
  static const double buttonHeightCompact = 36; // never the only way to act
  static const double buttonHeightLg = 48;
  static const double inputHeight = 44;
  static const double badgeHeight = 26;

  static const double iconSm = 16; // inline with 12–13 text
  static const double iconBase = 20; // buttons, list leading icons
  static const double iconLg = 36; // tile/feature icons
  static const double iconHero = 56; // empty states, confirmations

  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 56;
}
