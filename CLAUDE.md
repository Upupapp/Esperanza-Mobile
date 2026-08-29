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

Expect `flutter analyze` to take ~8 minutes and `flutter test` ~33 minutes
(450 tests, 52 files). Budget for it; it is not hung.

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

Known drift, unresolved as of 2026-08-29 — do not "fix" one half without the other:
mobile has no `Resubmitted` (so `AppStatusX.fromLabel('Resubmitted')` silently
returns `AppStatus.draft`), and mobile carries `Waiting Requirements`, which appears
in **zero** files across the web platform.

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

## Deploying

The repository-agnostic deploy protocol in `/Users/user/CLAUDE.md` applies here in
full: sweep remote → test upstream-only items → merge preserving local-only →
sweep + test the merged result → push → verify refs. There is no CI in this repo, so
the local gate is the only gate.
