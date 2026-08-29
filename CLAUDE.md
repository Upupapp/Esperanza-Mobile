# Esperanza Mobile — agent rules

## Read this first: the app is NOT at the repo root

The repository root holds a **broken leftover Flutter scaffold** — a `pubspec.yaml`
that declares eight assets, with **no `lib/` and no `assets/` directory**. It cannot
build. `README.md`, `.metadata`, `package-lock.json` and all three screenshots at the
root are byte-identical duplicates of the real ones.

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

`ESPERANZA_MOBILE_WEB_ALIGNMENT.md` is the spec and the intent authority. It also
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

Known drift, unresolved as of 2026-08-29 — do not "fix" one half without the other:

- Mobile has no `Resubmitted`, so `AppStatusX.fromLabel('Resubmitted')` silently
  returns `AppStatus.draft` — a resubmitted request would render as grey "Draft".
- Mobile carries `Waiting Requirements`, which appears in **zero** files across the
  current web platform. `requests_service.dart` already migrates it to `Under
  Review` on load, so no live request can carry it.
- The web's `badge.blade.php` actually styles **17** labels — the 15 above plus
  `Verified` and `Unverified`, which are in neither that prose list nor mobile.
  `fromLabel` returns `draft` for both. That matters beyond a badge colour:
  `CitizenSessionService.accessLevel` decides Guest/unverified/verified by
  `fromLabel(acc.status) == AppStatus.approved`, so an account whose status ever
  arrives as `Verified` would be treated as **unverified** and locked out of Dokyu.
  Latent, not live — mobile only ever writes `Pending Review` and `Approved` today,
  and there is no backend — but it is the first thing that breaks when one lands.

## Design tokens

`lib/theme/app_colors.dart` is an exact 1:1 port of the web platform's
`resources/css/app.css` `@theme` block — all 23 navy/brand/gold hexes verified
matching on 2026-08-29. **Never introduce a color outside that set.**

## Privacy — this repository is PUBLIC

It currently contains real constituents' personal data, unresolved:

- `Esperanza-Mobile-App/Reference_forms/` — real residents' scanned documents.
- The "demo" account is a **real** person's constituent record (see the comment at
  `lib/services/mock_catalog.dart:2572`), and the bundled ID images print real details.

**Never add another real person's data, document scan, or identifying image.** Use
synthetic identities. Removing such a file at HEAD does not remove it from history —
raise it with the owner rather than attempting a fix.

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
- 94.8 MB is almost entirely `assets/images/` (39 MB of ~2 MB PNGs, 37 declared
  assets). Ship an **AAB**, not this APK — and see the privacy note above: the
  bundled demo ID images are real residents' details, so they are compiled into
  every binary this produces, not merely committed to the repo.

iOS has never been built from either lane.

## Deploying

The repository-agnostic deploy protocol from whichever lane you are on applies
here in full: sweep remote → test upstream-only items → merge preserving
local-only → sweep + test the merged result → push → verify refs. There is no CI
in this repo, so the local gate is the only gate.
