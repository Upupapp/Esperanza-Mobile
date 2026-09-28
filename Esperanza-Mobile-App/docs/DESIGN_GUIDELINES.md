# Esperanza Mobile — Design Guidelines

**Status:** the standard, from 2026-09-28. **Applies to:** all new code and any screen you touch.
**Sources of truth, in order:** the tokens in `lib/theme/` → this document → the web platform's
`resources/css/app.css` `@theme` block, which the tokens port.

Mobile and the web portal are one product seen through two windows. A citizen who files a
request on the phone and checks it on a laptop should see the same colours, the same status
badge, the same hierarchy. So the rule behind every section below is: **use a token, and pick
it by role.** If no token fits, add one to `lib/theme/` (and say why), never write the number.

Enforced by `test/design_standard_test.dart` (contrast, scales, touch targets) and
`test/design_token_discipline_test.dart` (ratchets on raw `fontSize:` and `Colors.*`).

---

## 1. Principles

1. **Clarity over decoration.** Citizens use this under stress: at a municipal counter, in a
   flood. Every screen answers "what is this, what's its status, what do I do next" before
   anything else.
2. **One primary action per screen.** The most important thing to do is the one filled
   brand-blue button. Everything else is secondary, ghost, or a text link.
3. **Status is sacred.** Status labels and colours come only from `AppStatus`. They are the
   web's 17 badge states and are never invented, renamed or recoloured locally.
4. **Readable by everyone.** WCAG AA contrast, 44 pt touch targets, text that survives 200%
   scaling and Filipino strings 20–30% longer than English.
5. **Honest UI.** A default must never state something false: no "Free" for an unknown fee, no
   "Admin" for an unknown actor, no success toast for a simulated submit.

---

## 2. Colour

`lib/theme/app_colors.dart` is a 1:1 port of the web palette. **Never introduce a colour outside
it.** `Colors.white` and `Colors.transparent` are fine; they're primitives, not brand.

### 2.1 Palette: what each family is for

| Family | Tokens | Use for | Never for |
|---|---|---|---|
| **Navy** | `navy950`–`navy600` | Headings, dark heroes, the navbar, the drawer | Body text on dark (use white/`brand200`) |
| **Brand blue** | `brand50`–`brand900` | Primary actions, links, focus rings, selection | Decoration; large filled areas |
| **Gold** | `gold50`–`gold700` | The seal accent, highlights, the `gold` button, "new" markers | **Text on white** (`gold500` is 2.18:1). Use `gold700` for gold text |
| **Slate** | `slate50`–`slate800` | Text, borders, backgrounds, disabled states | — |
| **Status hues** | `blue/amber/indigo/purple/sky/orange/emerald/rose/teal/cyan/green` `50/500/700` | Status badges (via `AppStatus` only), feedback | Anything that isn't a status or feedback |

### 2.2 Semantic roles: use these names in code

| Role | Token | Value | Notes |
|---|---|---|---|
| Page background | `AppColors.background` | slate-50 | Scaffold |
| Surface | `AppColors.surface` | white | Cards, sheets, inputs |
| Hairline border | `AppColors.border` | slate-100 | Card edges |
| Input border | `slate200` | | 1 px; focus: `brand400` at 1.5 px |
| Heading text | `AppColors.textPrimary` | navy-900 | 17.8:1 |
| Body text | `AppColors.textBody` | slate-800 | 14.6:1 |
| Secondary text | `AppColors.textMuted` | **slate-500** | 4.76:1. Captions, helper text, timestamps |
| Disabled / placeholder | `AppColors.textDisabled` | slate-400 | 2.56:1. **Never** for content a citizen must read |
| Primary action | `brand500` fill, white text | | 5.02:1 |
| Destructive / emergency | `AppColors.danger` (rose-600) | | 4.70:1 as fill or text |
| Success / warning / info | `success`, `warning`, `info` | | As **icons or fills**; for text use the `*700` shade |

**Changed 2026-09-28:** `textMuted` was slate-400, 2.56:1 on white. That's below AA, on
~100 lines of real content. It's now slate-500, and slate-400 is renamed `textDisabled` for the
cases where low contrast is intended.

### 2.3 Contrast rules

- Text needs **4.5:1** (AA). Text 18 pt+ regular or 14 pt+ bold needs 3:1. Icons and input
  borders that identify a control need 3:1.
- Coloured text uses the **700** shade (`emerald700`, `amber700`, `rose700`…); the 500 shades are
  for dots, icons and fills only (`emerald500` text is 2.54:1).
- **Never rely on colour alone.** Every status has its label, every error has text, and every
  selected chip changes weight or shows a check as well as its colour.
- On navy: white, `brand200` (11.5:1) and `slate400` (6.9:1) are all safe.

**Known exception, owned by both lanes:** the web's own badge colours for **Cancelled**
(slate-500 on slate-100, 4.34:1) and **Archived** (slate-400 on slate-100, 2.34:1) fail AA.
Mobile keeps them identical to the web, so fix them together (web `badge.blade.php` first, then
`app_status.dart`). The test pins these two so no third joins them.

---

## 3. Typography

**Fonts:** **Inter** for everything (`AppTypography.sans`). **Lora** (`AppTypography.display`)
only for official-document titles and the wordmark: it's the "this is a government document"
voice, so keep it rare. Both are bundled; never fetch fonts at runtime.

### 3.1 The scale

Eight roles, the web's own `.type-*` classes. Card title and everything smaller match the web
exactly. The two desktop sizes come down one step for a phone. Every style carries its line
height, so paragraphs have the same rhythm on both platforms.

| Role | Token | Size / line | Weight | Use | Web |
|---|---|---|---|---|---|
| Display | `displayTitle` | 32 / 40 | 700 | Hero numbers, splash headline | display 36, kpi 32 |
| Page title | `pageTitle` | 24 / 32 | 700 | One per screen, when the AppBar isn't enough | page 28 |
| Section title | `sectionTitle` | 20 / 28 | 700 | Major sections within a screen | section 20 |
| Card heading | `cardHeading` | 16 / 24 | 600 | Card, sheet and dialog titles | card 16 |
| Body | `bodyText` | 14 / 22 | 400 | Running text, descriptions | body 14 |
| Helper | `helper` | 13 / 20 | 400 | List subtitles, field help, secondary lines | helper 13 |
| Label | `labelText` | 12 / 16 | 600, +0.02em | Field labels, badges, tabs, metadata | label 12 |
| Eyebrow | `eyebrow` | 11 / 16 | 600, +0.08em, UPPERCASE | "RECENT REQUESTS" markers | eyebrow 12 |
| Fine print | `fine` | 11 / 14 | 400 | Timestamps, legal footnotes, nav labels | — |
| Document title | `documentHeading` | 20 / 28 Lora | 600 | Certificates, official document names | — |

### 3.2 Rules

- **11 pt is the floor** for anything a citizen reads. **Whole points only**; no 12.5.
- **Colour with `copyWith(color: AppColors.…)`**, never by writing a new `TextStyle`.
- **One-off inline styles** (a coloured count, a single weight change) take their size from
  `AppTextSize` (`display 32 · page 24 · section 20 · card 16 · body 14 · helper 13 · label 12 ·
  fine 11`). Never write the number.
- **Weights:** 400 for reading, 600 for labels and headings, 700 for page and section titles
  only. Avoid 500 in new code; it reads as neither.
- **Let text wrap.** Filipino strings run 20–30% longer. Use `maxLines` + ellipsis only on
  single-line list titles, and never on error messages or instructions.
- **Sentence case** everywhere ("Submit report", not "Submit Report"). The exceptions are status
  labels, which are the web's canonical Title Case strings, and eyebrows.
- **Numbers that change** (counts, amounts, KPIs) use
  `fontFeatures: [FontFeature.tabularFigures()]`.

### 3.3 Migrating older styles

The pre-standard styles stay so current screens don't shift. When you touch a screen, move it
to the role:

| Old | → Role | Old | → Role |
|---|---|---|---|
| `hero` (32) | `displayTitle` | `bodySmall*` (12.5) | `helper` (13) |
| `h1` (24) | `pageTitle` | `label`, `labelStrong` (13.5) | `bodyText` w600 / `cardHeading` |
| `h2` (20, w600) | `sectionTitle` | `caption` (12) | `labelText` / `helper` |
| `h3` (16) | `cardHeading` | `captionSmall*` (11.5) | `labelText` (12) |
| `body`, `bodyMedium` (14) | `bodyText` | `overline` (11) | `eyebrow` |
| `cardTitle`, `subsectionLabel` (13) | `helper` w600 | `micro` (10.5), any 9–10.5 | `fine` (11) |
| `documentTitle` (Lora 18) | `documentHeading` | raw `fontSize: n` | nearest role |

After migrating, lower `_fontSizeCeiling` in `test/design_token_discipline_test.dart` to the
new count (381 on 2026-09-28).

---

## 4. Spacing and layout

### 4.1 The scale: only these stops

`4 · 8 · 12 · 16 · 20 · 24 · 32 · 48` (`xs sm md lg xl xxl xxxl page`), the web's rhythm.
A 6, 10 or 14 isn't a finer design; it's drift. **Round to the nearest stop, and on a tie
round down** (6→4, 10→8, 14→12), so migrating never makes a layout grow into an overflow. `huge` (40) is
kept only for existing call sites.

### 4.2 Roles: reach for these first

| Role | Token | Value |
|---|---|---|
| Screen left/right padding | `AppSpacing.screenGutter` | 16 |
| Card / list-tile inner padding | `AppSpacing.cardPadding` | 16 |
| Sheet, dialog, hero-card padding | `AppSpacing.sheetPadding` | 20 |
| Between stacked cards / rows | `AppSpacing.itemGap` | 12 |
| Between form fields | `AppSpacing.fieldGap` | 16 |
| Heading → its content | `AppSpacing.headingGap` | 12 |
| Between sections | `AppSpacing.sectionGap` | 24 |
| Icon ↔ label, inline items | `AppSpacing.inlineGap` | 8 |
| After the last scroll item | `AppSpacing.scrollEnd` + `MediaQuery.paddingOf(context).bottom` | 24 + inset |

### 4.3 Recipes

- **Screen:** `ListView(padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset))`. The
  bottom inset is mandatory on any screen under the floating navbar, or the last item hides
  behind it.
- **Card:** `AppCard` (16 padding, radius 16, hairline border, `AppShadows.card`). Title
  (`cardHeading`) → 4 → helper line → 12 → content.
- **Form:** label above the field (`labelText`), 4 to the field, helper or error 4 below, 16
  to the next field. Primary button 32 below the last field, full width.
- **List row:** leading icon 20 in a 40 × 40 tinted square (radius 12) → 12 → title/subtitle →
  trailing chevron or chip. Minimum row height 56.
- **Narrow screens:** everything must lay out at **280 × 568** without overflow (the existing
  overflow tests use this size).

---

## 5. Shape, elevation, sizing

**Radius** (`AppRadius`): `sm 8` chips, thumbnails · `md 12` buttons, inputs, tiles ·
`lg 16` cards, dialogs · `xl 20` bottom sheets, hero cards · `full` pills, badges, avatars.
Off-scale radii (10, 14) round to the nearest step.

**Elevation** (`AppShadows`): `card` for resting cards (barely there, with the border doing the
work) · `cardHover` for pressed or dragged items · `float` for the navbar, FAB and popovers
only. No other shadows; never stack a shadow on a coloured fill.

**Sizing** (`AppSizes`, web `--size-*`):
- **Touch targets:** every tappable thing is at least **44 × 44**. Pad a small icon's hit area
  rather than shrinking the target.
- **Heights:** button 44 (compact 36, only when a 44 alternative exists; large 48 for the
  screen's main call to action) · input 44 · badge 26.
- **Icons:** 16 inline with small text · 20 in buttons and list rows · 36 feature tiles ·
  56 empty states and confirmations.
- **Avatars:** 32 / 40 / 56.

**Icon style:** Material **outlined** (`Icons.*_outlined`) for navigation, list leading icons
and anything at rest. **Rounded filled** (`Icons.*_rounded`) for the selected or active state
and inside filled buttons. Don't mix styles within one row.

---

## 6. Components

Use the shared widget; never restyle a raw Material widget on a screen.

| Need | Widget | Rules |
|---|---|---|
| Buttons | `AppButton` | **primary** (brand) once per screen · **secondary** (outlined) for alternatives · **ghost** for low-emphasis/cancel · **danger** for destructive and emergency · **gold** for rare celebratory CTAs. Labels are verbs ("Submit request"). Use `loading:` instead of disabling during a call |
| Cards | `AppCard` | Pass `onTap` for tappable cards (ink + semantics). Don't nest cards |
| Text input | `AppTextField`, `AppDateField` | Always a visible label; hint text is an example, not the label. Errors in `danger` below the field, in words that say how to fix it |
| Status | `StatusChip` | Only via `AppStatus`. Never a coloured `Text` |
| Tabs | `SegmentedTabs` | 2–4 options, short labels |
| Section heading | `SectionHeader` | `eyebrow` or `sectionTitle`, optional trailing action |
| Loading / error / retry | `AsyncStateView` | Every network-backed screen. Error text comes from the server's bilingual message |
| Empty | `EmptyState` | Icon 56, title, one sentence on what to do next |
| Confirm / info | `AppDialogs.confirm` / `.info` | Destructive confirms name the thing ("Delete this draft?") |
| Toast | `AppDialogs.toast` | Short outcomes only; never the only record of an error that needs action |
| Upload | `RequirementUploader` | Shows file name, type and a remove action |

---

## 7. Motion

`AppMotion`: `fast 150ms` taps and chips · `standard 260ms` sheets and page transitions ·
`emphasis 380ms` reveals · `celebration 600ms` success moments only. Enter with `enterEase`,
exit with `exitEase`. **Always** wrap durations in `AppMotion.resolve(context, …)` so
reduce-motion users get the short version. Motion explains a change; it never decorates a wait.

---

## 8. Accessibility checklist

- [ ] Contrast per §2.3. `textDisabled` is never used for content.
- [ ] Every tappable element is at least 44 × 44 and exposes `Semantics(button: true)` with its
  label (`AppButton` and `AppCard(onTap:)` do this for you).
- [ ] Icon-only buttons have a `tooltip` / semantic label.
- [ ] The screen works at 200% text scale and 280 pt width without overflow.
- [ ] Status and errors are conveyed in text, not colour alone.
- [ ] Focus order follows reading order; no traps in sheets or dialogs.
- [ ] Haptics (`AppHaptics`) accompany, never replace, visual feedback.

---

## 9. Content and language

- **Filipino-first, bilingual.** Server errors arrive as `{fil, en}`; show Filipino by default
  (`ApiException.message()`). Write new copy in plain, respectful Filipino/English. Avoid
  legal or bureaucratic jargon when an everyday word exists.
- **Say what happens next.** "Your request is Under Review. You'll be notified when…", not just
  "Success".
- **Canonical terms:** status labels, service names and office names are the backend's strings,
  unchanged.
- **Never fabricate.** No placeholder amounts, actors or dates presented as real.

---

## 10. Imagery and identity

- **No real person's face, name, ID or document.** This repository is public. Use the
  generated synthetic identities (`tool/demo_identity_art/`).
- **Place identity must be true:** Esperanza, **Masbate**. Don't use an image with another
  municipality's seal or signage (see `HANDOFF_FROM_WEB_LANE.md` §3). When unsure, use neutral
  scenery.
- The municipal seal appears on official surfaces (sign-in, documents, the drawer header). It is
  not decoration.

---

## 11. Review checklist (paste into a PR)

- [ ] No new `fontSize:` number, `Color(0x…)`, off-scale padding or radius; tokens by role.
- [ ] One primary button; buttons use `AppButton`.
- [ ] Status via `AppStatus` / `StatusChip`.
- [ ] Contrast, touch targets, 200% text and 280 pt width checked.
- [ ] Bottom inset on scroll views under the navbar.
- [ ] Loading, empty and error states covered (`AsyncStateView`, `EmptyState`).
- [ ] Copy is honest, bilingual where it comes from the server, sentence case.
- [ ] `flutter analyze` and `flutter test` pass, and the ratchet ceilings are lowered if you
  reduced a count.

---

## 12. Open items

| Item | Owner |
|---|---|
| Cancelled/Archived badge contrast (§2.3) | Both lanes, web first |
| The web uses `text-slate-400` for secondary text 1,073 times, the same AA failure this standard fixes on mobile | Web lane |
| Raw `fontSize:` literals: **73 left** (381 → 73 on 2026-09-28). Migrated: all four bottom tabs (Home and everything under it, Balita, Events, Emergency), notifications and pop-ups. Left: the drawer's destination screens (profile, settings, support, directory, legal) and onboarding | This lane |
| Off-scale spacing (6/10/14) and radius (10/14) literals | This lane, when touched |
