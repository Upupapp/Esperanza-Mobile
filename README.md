# Esperanza Mobile

A Flutter citizen app for the **Municipality of Esperanza** — document requests (Dokyu),
assistance applications (Tulong), incident reports (Sakuna), announcements (Balita), a digital
ID wallet, and the resident profile behind them.

> ⚠️ **This repository is public and currently contains real residents' personal data.**
> See [CLAUDE.md](CLAUDE.md) before adding anything. Never commit another person's data,
> document scan, or identifying image — use synthetic identities.

## The app is not at the repository root

```
Esperanza-Mobile-App/     ← the Flutter project. Everything runs from here.
CLAUDE.md                 ← agent/contributor rules. Read first.
SWEEP_2026-08-29.md       ← the current repo audit and its open findings.
```

The root used to hold a second, broken Flutter scaffold — a `pubspec.yaml` with no `lib/` and no
`assets/` that could not build, plus byte-identical copies of the README, screenshots and the
alignment spec. It was removed on 2026-08-29 (FE 07). The app was **not** promoted to the root:
two machines work this repository, and moving it rewrites every path in every open branch. That
decision is recorded in [`Esperanza-Mobile-App/docs/FE07_SINGLE_PROJECT.md`](Esperanza-Mobile-App/docs/FE07_SINGLE_PROJECT.md)
and can be revisited once both lanes agree.

## Getting started

Requires **Flutter 3.47.0 / Dart 3.13.0**. Both lanes are pinned to it; the committed
`pubspec.lock` is that resolution, so `flutter pub get` should not change it.

```sh
cd Esperanza-Mobile-App
flutter pub get
flutter analyze
flutter test
```

### How long the gates take

Wildly machine-dependent — a fast run is not a skipped one, and a slow one is not a hang.

| Lane | `flutter analyze` | `flutter test` |
|---|---|---|
| macOS (Apple M4) | ~8 min | ~33 min |
| Windows | ~1 min | ~1 min |

`flutter test` must report **461 or more** passing. That total is a floor: never reduce it to go
green, and note that `Executed 0 of 0` also reads as a pass.

### Running it

```sh
flutter build apk --release          # ~4.5 min, produces a ~95 MB fat APK
flutter run -d <device>
```

The release build currently signs with the **debug** keystore and cannot go to Play; iOS has no
`DEVELOPMENT_TEAM`. Both need owner-held credentials — see FE 11.

Cloning on Windows: the longest tracked path is 210 characters, so clone into a **short**
directory or enable `core.longpaths`, otherwise the checkout silently produces an empty tree.

## What this app is

**Frontend-only, by design.** There is no HTTP client dependency at all — authentication,
requests, notifications and the resident profile are simulated and persisted to
`shared_preferences`. The login screen says so to the user. This is deliberate, not an omission.

`Esperanza-Mobile-App/ESPERANZA_MOBILE_WEB_ALIGNMENT.md` is the spec and the intent authority,
and it names the Web-Admin APIs that do not exist yet. The web counterpart is a separate,
**read-only** Laravel project — never modify it from here.

## Contributing

Read [CLAUDE.md](CLAUDE.md) first — it covers the status vocabulary, the design tokens, the
privacy rules and the two-machine setup. Deliverables for the front-end programme live in
[`Esperanza-Mobile-App/docs/`](Esperanza-Mobile-App/docs/).
