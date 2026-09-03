# Esperanza Mobile — agent rules

## Read this first: the app is NOT at the repo root

That broken leftover Flutter scaffold at the root — a `pubspec.yaml` declaring eight
assets with no `lib/` and no `assets/` — **was removed on 2026-08-29 (FE 07)**, along
with the byte-identical duplicate README, `.metadata`, both `package-lock.json` files,
the three screenshots and the duplicate alignment spec. The root now holds only
`.gitignore`, `README.md`, `CLAUDE.md`, `SWEEP_2026-08-29.md` and the app directory.

The app was deliberately **not** promoted to the root: two lanes work this repository
and the move rewrites every path in every open branch. Revisit only by agreement.

**The app is `Esperanza-Mobile-App/`.** Every `flutter` command runs from there:

```sh
cd Esperanza-Mobile-App
flutter pub get && flutter analyze && flutter test
```

Gate timings differ enormously by machine — do not read a slow run as a hang:

| Lane | `flutter analyze` | `flutter test` |
|---|---|---|
| macOS (Apple M4) | ~8 min | ~33 min |
| Windows | ~73 s | ~61 s |

Both lanes run Flutter 3.47.0 / Dart 3.13.0; keep them pinned together.

## What this project is

A **frontend-only** Flutter citizen app for the Municipality of Esperanza. There is
**no HTTP client dependency at all** — auth, requests, notifications and profile are
simulated and persisted to `shared_preferences`. This is deliberate, not an omission.

`Esperanza-Mobile-App/ESPERANZA_MOBILE_WEB_ALIGNMENT.md` is the spec and the intent
authority (there is now exactly one copy; the root duplicate is gone). It also
names the Web-Admin APIs that do not exist yet. The web counterpart is a separate,
**read-only** Laravel project (`Esperanza-Web-Platform-frontend`) — never modify it
from here.

## Universal status system

`lib/theme/app_status.dart` is the mobile port of the web platform's
`resources/views/components/ui/badge.blade.php`. **Never invent a status label.**
The canonical list lives in the web repo's own `CLAUDE.md`:

> Draft, Submitted, Pending Review, Under Verification, Assigned, Processing,
> Under Review, Resubmitted, Approved, Rejected, Mark to Release, Released,
> Completed, Cancelled, Archived.

**Check the list against `origin/main`, not a local checkout.** A web clone even a
few dozen commits stale still contains `Waiting Requirements` and `Ready for
Release` — labels since replaced — and will make mobile look correct when it is not.

**That prose list is 15; `badge.blade.php` actually styles 17.** It omits `Verified`
and `Unverified`. Where the two disagree the component wins — prose describes, a
component renders. `test/status_parity_test.dart` holds mobile to the component.

Resolved in FE 04 (2026-08-29): `Resubmitted`, `Verified` and `Unverified` were added,
and `fromLabel` now asserts in debug rather than degrading silently to `Draft`. The
`Verified` gap was not cosmetic — the Web Admin stores `Approved` and *displays*
`Verified`, so an account arriving as `Verified` used to resolve to `draft` and be
locked **out** of Dokyu.

Still open, and **not this lane's to decide**: mobile carries `Waiting Requirements`,
which appears in zero files on the current web platform. It is inert —
`requests_service.dart` migrates it to `Under Review` on load — and is marked
`PENDING OWNER DECISION` in the parity test. Recommendation: retire it.

## Design tokens

`lib/theme/app_colors.dart` is an exact 1:1 port of the web platform's
`resources/css/app.css` `@theme` block — all 23 navy/brand/gold hexes verified
matching on 2026-08-29. **Never introduce a color outside that set.**

## Privacy — this repository is PUBLIC

**Never add a real person's data, document scan, or identifying image.** Use synthetic
identities. `test/no_real_identities_test.dart` enforces this: it fails if any retired
real name or record id reappears under `lib/`, `test/` or `assets/`. Its denylist is
**hashed**, because listing the names in a public repo would republish the very index
it exists to remove.

Resolved at HEAD (FE 02, 2026-08-29): the three demo identities were real residents'
records — names, birthdates, addresses, household and family ids — and the bundled
profile photos and ID scans were their real images. All are now synthetic and
generated (`tool/demo_identity_art/generate.py`). See
`Esperanza-Mobile-App/docs/FE02_SYNTHETIC_IDENTITIES.md`.

**Still unresolved, and owner decisions — do not attempt:**

- `Esperanza-Mobile-App/Reference_forms/` — real residents' scanned documents, untouched.
- **Git history.** FE 02 changed HEAD only. Every retired name is still in the history of
  a public repository and in every existing clone and fork. Removing it means a history
  rewrite, a force-push, and treating the data as already fetched.

## Two machines, one repo

This repo is worked from **two lanes**, and neither owns it alone:

- **macOS** — iOS / App Store. Its operator rules are at `/Users/user/CLAUDE.md`.
- **Windows** — Android / Google Play. Its operator rules are at
  `C:\Users\paulg\.claude\projects\C--Users-paulg\memory\`.

Never write an instruction here that names only one of them. Anything
machine-specific needs both paths, or an env var with a candidate list.

## Building for a device

The spec's Section 9 claim that the app has *never* been built for a device is
**out of date as of 2026-08-29**: `flutter build apk --release` succeeds on the
Windows lane in ~4½ min and produces a 94.8 MB fat APK. Two things to know:

- Gradle warns that both **AGP 8.11.1** (wants ≥ 9.0.1) and **Kotlin 2.2.20**
  (wants ≥ 2.3.20) will soon be dropped by Flutter. Not yet fatal.
- ~95 MB is almost entirely `assets/images/` (39 MB of ~2 MB PNGs). Ship an **AAB**,
  not this APK. (The demo ID images that used to carry real residents' details, and
  therefore shipped inside every binary, were replaced with generated synthetic ones
  in FE 02.)

**iOS now builds** (macOS lane, 2026-09-03): `flutter build ios --simulator --debug` in 36.5s,
installs, launches and renders on an iPhone 17 simulator with Impeller/Metal, no runtime
exceptions. Two things to know:

- **The minimum iOS is 15.0, not the 13.0 the project file used to claim.** Flutter 3.47 raises
  it during the build; measured by reverting to 13.0 and watching it re-raise. iOS 13/14 devices
  were never actually supported. Excludes iPhone 6s/7/SE-1.
- `Package.resolved` is committed for both workspaces. Two of the six transitive Swift packages
  (`DKCamera`, `DKPhotoGallery`, via `file_picker`) track branch `master`, so those revisions are
  the only thing making an iOS build reproducible.

See `Esperanza-Mobile-App/docs/FE03_DEVICE_VERIFICATION.md`. The 46-screen walk is still owed:
synthetic taps are blocked on this Mac (no Accessibility grant), so only splash, onboarding and
sign-in have been seen.

## Deploying

The repository-agnostic deploy protocol from whichever lane you are on applies
here in full: sweep remote → test upstream-only items → merge preserving
local-only → sweep + test the merged result → push → verify refs. There is no CI
in this repo, so the local gate is the only gate.
