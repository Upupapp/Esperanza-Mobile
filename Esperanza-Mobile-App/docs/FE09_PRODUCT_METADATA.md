# FE 09 — Product metadata

**Status:** complete for everything this lane can decide. **One launch blocker found and left
open**: the Android launcher icon is still Flutter's.
**Date:** 2026-08-29
**Lane:** Windows / Android. iOS items are flagged for the macOS lane, not guessed at.
**Verified on:** Pixel 8 emulator, Android 16 / API 36 — screenshots below

---

## Before / after

| Where | Was | Now |
|---|---|---|
| `AndroidManifest.xml` `android:label` | `esperanza_mobile` | `Esperanza Mobile` *(fixed in the preceding sweep, `7901100`)* |
| `ios/Runner/Info.plist` `CFBundleDisplayName` | `Esperanza Mobile` | unchanged — it was already correct |
| `ios/Runner/Info.plist` `CFBundleName` | `esperanza_mobile` | `Esperanza` |
| `web/manifest.json` `name` | `esperanza_mobile` | `Esperanza Mobile` |
| `web/manifest.json` `short_name` | `esperanza_mobile` | `Esperanza` |
| `web/manifest.json` `description` | "A new Flutter project." | real description |
| `web/manifest.json` theme + background | `#0175C2` (Flutter blue) | `#0B1730` (`AppColors.navy900`) |
| `web/index.html` `<title>` | `esperanza_mobile` | `Esperanza Mobile` |
| `web/index.html` description | "A new Flutter project." | real description |
| `web/index.html` `apple-mobile-web-app-title` | `esperanza_mobile` | `Esperanza Mobile` |
| `web/index.html` `theme-color` | absent | `#0B1730` |
| root + app `README.md` | Flutter template | rewritten *(FE 07)* |
| `drawable/launch_background.xml` | `@android:color/white` | `@color/esperanza_navy_900` |
| `drawable-v21/launch_background.xml` | `?android:colorBackground` | `@color/esperanza_navy_900` |

`CFBundleName` is capped at 15 characters by Apple's own guidance, so it takes `Esperanza`
rather than the 16-character `Esperanza Mobile`. **Bundle identifiers were not touched** —
`ph.gov.esperanza.esperanza_mobile` and `ph.gov.esperanza.esperanzaMobile` are correct, and
changing one breaks store identity and existing installs.

---

## Found on the device, not in the source

### 1. The cold start flashed white — fixed

`launch_background.xml` was the untouched Flutter template: plain **white**. `SplashScreen`
paints `AppColors.navy900`. The OS draws the launch window before Flutter's first frame, so
every cold start flashed white and then snapped to navy. The app is **light-mode only**, and
`values-night` used the same white drawable, so this was not a dark-mode nicety — it was simply
the wrong colour on every launch.

Both `drawable/` and `drawable-v21/` now reference a new `values/colors.xml` entry carrying
`#FF0B1730`, with a comment tying it back to `app_colors.dart` so the two cannot drift apart
silently.

**Verified on device**: the launch window is navy. Screenshot: `splash_check.png`.

### 2. LAUNCH BLOCKER — the launcher icon is still Flutter's

Measured, not inferred: `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` is **byte-identical**
(md5 `13e9c72ec37fac220397aa819fa1ef2d`) to
`flutter_tools/templates/app/android.tmpl/.../ic_launcher.png` in the pinned Flutter 3.47.0 SDK.

This is not cosmetic and not hidden. On Android 12+, the system splash centres the **launcher
icon**, so the very first thing a citizen sees on every cold start is the **Flutter logo** on
Esperanza navy. It is also the icon in the app drawer. Both screenshots show it.

Ironically, fixing the splash colour made this *more* visible: the Flutter logo now sits on a
correct navy field instead of blending into white.

**Not fixed here, deliberately.** The mandate for this item is to *audit* icons, and replacing
one is a branding decision, not a metadata edit. `assets/images/Logo/esperanza-seal.png` is in
the repo and is the obvious source, but an adaptive icon needs a foreground/background split
with correct safe zones, and a detailed municipal seal usually needs redrawing to read at 48dp
rather than being scaled down. That needs design input and the owner's sign-off.

**This should block any release to citizens.**

### 3. The app name truncates on the launcher — recommendation, not a unilateral change

FE 09 asks for truncation to be checked on a small launcher. It truncates: the app drawer shows
**"Esperanza M…"**. Neighbouring apps ("Play Store", "Messages", "Calendar") fit; sixteen
characters does not.

`CFBundleDisplayName` on iOS is the same sixteen characters, so iOS will truncate the same way.

**Recommended:** use `Esperanza` for both home-screen names and keep `Esperanza Mobile` as the
full product name in the stores and the web manifest — which is exactly what `short_name`
already does on web.

**Not changed here.** The guardrail says to confirm the exact user-facing wording with the owner
before setting it in three places. Correcting Android's snake_case identifier to match iOS was
fixing a defect; shortening the product name is a branding call that is not this lane's to make.

---

## Acceptance

| Criterion | Result |
|---|---|
| No default Flutter scaffold **string** is reachable by a user on any platform | ✅ all eleven replaced |
| The app name is identical on Android and iOS, verified on a device home screen | ✅ identical (`Esperanza Mobile`), verified on Android — ⚠️ **truncates**, and iOS home screen not verified from this lane |
| The root README gets a newcomer to a green test run with no other input | ✅ FE 07 |
| Launcher icon and splash verified on both platforms | ⚠️ **Android only.** Splash ✅ fixed and verified. Icon ❌ still Flutter's — see blocker above. iOS unverified from this lane |

Two criteria are partially met and are marked as such rather than rounded up. The iOS half needs
the macOS lane; an emulator is also not a phone.

---

## Screenshots

| File | Shows |
|---|---|
| `splash_check.png` | Cold start after the fix — navy launch window, and the Flutter logo on the Android 12+ system splash |
| `launcher.png` | App drawer — the Flutter icon, and the label truncated to "Esperanza M…" |

Kept outside the repository: the repo is public and already carries a real-data problem, so no
new binaries were added to it for this.

---

## Follow-ups

1. **Design and ship a real launcher icon** (Android adaptive + iOS) — the one item that should
   block a citizen-facing release.
2. **Owner decision on the home-screen name** — recommend `Esperanza`.
3. **macOS lane**: verify `CFBundleName`, the iOS home-screen name and truncation, the iOS app
   icon, and the iOS launch screen. `CFBundleName` was changed here and has **not** been built
   or seen on an iOS device.
4. Confirm the icon and name on a **physical** handset — FE 03. An emulator's launcher grid is
   not every launcher's grid, and truncation is launcher-dependent.
