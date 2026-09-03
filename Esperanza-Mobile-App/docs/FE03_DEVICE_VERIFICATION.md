# FE 03 — Device verification (iOS, macOS lane)

**Date:** 2026-09-03 · **Commit gated:** `9ea3a40` · **Toolchain:** Flutter 3.47.0 / Dart 3.13.0,
Xcode 26.6, Apple M4 · **Device:** iPhone 17 simulator (1206×2622, aspect 0.460), iOS 26.

**Status: PARTIAL.** The command asks for all 46 screens on two platforms with the platform
channels exercised. What was achievable from this lane is below, and what blocks the rest is
stated precisely rather than left as "not done".

---

## 1. iOS builds — for the first time in this project's life

Spec Section 9 said the app had never been built for a device from either lane, and
`CLAUDE.md` recorded "iOS has never been built from either lane". That is now false:

```
Building ph.gov.esperanza.esperanzaMobile for simulator (ios)...
Xcode build done.    36.5s
✓ Built build/ios/iphonesimulator/Runner.app
```

It installs, launches and renders. Renderer is **Impeller (Metal)**. No Flutter exception, no
assertion and no missing-asset error appears in the runtime log across four launches.

## 2. Measured: the iOS deployment target is 15.0, and 13.0 was never real

`project.pbxproj` claimed `IPHONEOS_DEPLOYMENT_TARGET = 13.0` in all three configurations. The
build **raises it itself**:

```
Updating minimum iOS deployment target to 15.0.
Upgrading project.pbxproj
Upgrading AppFrameworkInfo.plist
```

Measured rather than assumed: the value was reverted to 13.0 and the build re-raised it. So
Flutter 3.47 enforces 15.0, and the repo's 13.0 was a stale claim — **iOS 13 and 14 devices were
never supported**, whatever the project file said. This matters for a municipal app whose
audience skews to older hardware: it excludes the iPhone 6s, 7 and 1st-gen SE. It is a fact to
plan around, not a choice this lane made, and FE 11's "confirm the minimum OS against the
audience" mandate should be read against 15.0.

The raised value is committed, because otherwise every iOS build dirties the tree.

## 3. Finding — the onboarding screen letterboxes over 30% of a modern iPhone

The onboarding pages are full-bleed artwork with `BoxFit.contain` and two readability scrims.
Measured on the screenshot rather than reasoned about:

| | |
|---|---|
| Artwork | 1023×1537, aspect **0.666** |
| iPhone 17 | 1206×2622, aspect **0.460** |
| Drawn height with `contain` | 1812 px |
| **Letterbox** | **810 px — 30.9% of the screen**, ~405 px top and bottom |

Sampled pixel values down the centre line: `rgb(165,165,165)` at the top edge,
`rgb(225,225,225)` just above the artwork, `rgb(144,144,144)` at the bottom edge.

Two things follow. The letterbox is **grey, not white** — the code comment at
`onboarding_screen.dart` says the artwork is "letterboxed onto this screen's own white
background", but the top and bottom scrims (`black38` and `black45`) are drawn over the full
`Stack`, so on a tall phone they darken the *empty margin* rather than the artwork they exist to
sit over. The result reads as unfinished.

`BoxFit.contain` is itself a deliberate, well-argued choice — the comment records that `cover`
cropped baked-in messaging off the sides on an Android device. The defect is not the fit; it is
that nothing handles the margin the fit necessarily creates.

**Why no test caught it:** `flutter_test`'s default surface is 800×600, aspect **1.33**. At that
aspect `contain` fits by *height* and letterboxes at the sides instead — a different picture
entirely. The four `*_overflow_test.dart` files cannot see this, and neither could a desktop-web
preview.

## 4. Verified on device — the FE 01 persistence guard

An unreadable session payload was written into the app's own preferences via `cfprefsd` and the
app relaunched:

```
flutter: [esperanza.persistence] CitizenSessionService discarded esperanza_citizen_session:
         FormatException: Unexpected character (at character 2)
```

The app booted to the sign-in screen. Before FE 01 this exact state left `AuthGate` spinning
forever. This is the first time that guard has been exercised outside a widget test.

**Not verified:** whether the narrow key-clearing actually lands in the container. The read-back
is confounded by `cfprefsd` caching and by this lane's own writes to the same key. Worth
confirming properly; do not treat the clearing half as proven.

**A trap for whoever repeats this.** Seeding preferences by editing
`Library/Preferences/<bundle>.plist` directly does **not** work reliably — `cfprefsd` caches, and
`plutil -replace` silently fails on these keys because it reads the `.` in
`flutter.esperanza_citizen_session` as a key path. `PlistBuddy` writes a value that reads back as
absent. The one that works is
`xcrun simctl spawn <UDID> defaults write <bundle> flutter.<key> -string '<value>'`. An earlier
run of this test appeared to pass and did not: the app was treating the key as absent rather than
undecodable, which produces the identical screen for an entirely different reason.

## 5. Verified on device — FE 02's synthetic identities

The sign-in screen renders the demo accounts as **Nicanor Sarmiento** and **Perlita Quiambao**,
with correct verification chips. The real residents' records are gone from the running app, not
just from the source.

## 6. Finding — two iOS dependencies are pinned to a branch, not a version

`Package.resolved` (now committed, both copies) pins six transitive Swift packages pulled in by
`file_picker`. Four are pinned to versions; **two track a branch**:

| Package | Pin |
|---|---|
| `DKCamera` | branch `master` |
| `DKPhotoGallery` | branch `master` |
| `DKImagePickerController` | branch `4.3.9` (a branch, not a tag) |
| SDWebImage / SwiftyGif / TOCropViewController | versions |

An iOS build is therefore not reproducible from `pubspec.lock` alone. Committing
`Package.resolved` pins the revisions and is the only thing making it reproducible today.

---

## What is blocked, and on what

**The 46-screen walk cannot be done from this lane.** Synthetic taps fail with `-25204`
(`errAEEventNotPermitted`) — the process has no Accessibility permission, which only the machine's
owner can grant in System Settings › Privacy & Security › Accessibility. The app registers no URL
scheme and sets no `FlutterDeepLinkingEnabled`, so `simctl openurl` is not a way round it.

Seeding preferences reaches the *first* screen of a state (onboarding-complete → sign-in), but
navigation between tabs and into any flow needs real taps. Screens reached: **splash, onboarding
page 1, sign-in** — 3 of 46.

Consequently these remain entirely unverified, and all of them need taps:

- Camera capture, gallery pick, document pick (PDF/DOCX)
- All three permission outcomes — grant, deny, permanently-denied — including
  `protected_action.dart`'s two distinct dialogs, which no permission system has ever triggered
- `tel:` links, the Google Maps launcher, and all five share targets
- Keyboard behaviour on the wizard and registration forms
- Every screen's rendering at 200% text scale (FE 05 depends on this)

**Android was not attempted from this lane.** The Windows lane owns Play and has already built a
release APK; duplicating it here would prove nothing new.

**To unblock:** grant Accessibility to the terminal, or have someone walk the app with the
screenshot commands in `mac-simulator-run-procedure` to hand.
