# FE 01 — Persistence hardening

**Status:** done, 2026-08-29. **Gate:** `flutter analyze` clean · `flutter test` **460 passed**
(450 baseline + 10 new), 0 failed.

## The defect

Every service restores itself from `shared_preferences` in a future started from its
constructor. Nothing awaits that future, so a throw inside it was unhandled: the service's
`loaded`/`loading` flag was never flipped and `notifyListeners()` never fired.

For `CitizenSessionService` the consequence was exact — `_loading` stayed `true`, and
`AuthGate` ([main.dart:78](../lib/main.dart)) rendered a `CircularProgressIndicator`
**forever**. Only clearing app data recovered it, which is not something a citizen can be
talked through on a phone call.

This was reachable by ordinary upgrade, not by tampering. The app already ships **five**
migrations for persisted data whose shape changed, and **every one of them runs after** the
`fromJson` that would already have thrown.

## The six persisted keys

| Key | Owner | Payload shape |
|---|---|---|
| `esperanza_citizen_session` | `CitizenSessionService` | object — one `CitizenAccount` |
| `esperanza_guest_mode` | `CitizenSessionService` | bool (not JSON; cannot fail to decode) |
| `esperanza_service_requests` | `RequestsService` | array of `ServiceRequest` |
| `esperanza_balita_posts` | `BalitaService` | array of `Announcement` |
| `esperanza_master_file_documents` | `MasterFileService` | object, accountId → array of `MasterFileDocument` |
| `esperanza_resident_profiles` | `ResidentProfileService` | object, accountId → `ResidentProfile` |
| `esperanza_read_notification_ids` | `NotificationsService` | array of string |
| `esperanza_duplicate_alert_resolutions` | `NotificationsService` | object, string → string |
| `esperanza_unverified_duplicate_kept_account` | `NotificationsService` | plain string (cannot fail to decode) |

## The guard

`lib/services/persistence_guard.dart`, used by all six services.

- **`readJsonGuarded`** — reads and decodes a key. On failure the key is **removed**, because
  a value this build cannot read will not become readable next launch and would otherwise fail
  identically forever. Only the offending key is cleared, never the whole store.
- **`decodeEachGuarded` / `decodeEntriesGuarded`** — decode a collection **entry by entry**,
  skipping unreadable records with a logged count. One bad record costs that record, not the
  citizen's whole history.
- **Every `_restore()` sets its loaded flag in a `finally`.** This is the change that actually
  prevents the hang: the flag flips on every path, including one nobody predicted.

`CitizenSessionService` additionally falls back to signed-out on a session whose shape it
cannot read — half-restoring a session is worse than signing out.

## Enum fallbacks, and why three of them have none

The brief asked for an `orElse` on every enum `firstWhere`. On reading each one, a blanket
default turned out to be the wrong answer for three of the four:

| Enum | Fallback | Why |
|---|---|---|
| `AttachmentCategory` | **`other`** | A genuinely neutral member that already exists for exactly this purpose. An unknown format degrades to a generic file and the attachment survives. |
| `ServiceCategory` | **none — skip the record** | `{dokyu, tulong, sakunaIncident}` has no neutral member. Any default files the citizen's request under the wrong service. |
| `ReceiptType` | **none — skip the record** | `{gcash, maya, onsite, free}`. Defaulting to `free` would be a false statement about money; defaulting to a payment method invents one. |
| `PostMediaType` | **none — skip the record** | `{image, video}`. Rendering a video as an image produces a broken tile rather than a degraded one. |

A silent wrong default is a quieter version of the same bug. Where no honest default exists,
the record is skipped and the skip is logged.

## Test matrix

`test/persistence_corruption_test.dart` — 10 tests, hostile in three distinct ways because the
three fail differently.

| # | Scenario | Asserts |
|---|---|---|
| 1 | Session = `'this is not json'` | `loading` clears; signed out |
| 2 | Session = valid JSON, wrong shape | `loading` clears; signed out, not half-restored |
| 3 | Requests = malformed JSON | `loaded` becomes true |
| 4 | Balita = malformed JSON | `loaded` becomes true |
| 5 | Master file = malformed JSON | `loaded` becomes true |
| 6 | Resident profiles = malformed JSON | `loaded` becomes true |
| 7 | Read notification ids = malformed JSON | `loaded` becomes true |
| 8 | Request with an unknown `category` | restore completes; that record is skipped, not guessed |
| 9 | One bad record beside one good one | the good record survives |
| 10 | Attachment with an unknown `category` | degrades to `AttachmentCategory.other` |

Fixtures for 8 and 9 are built from a real `ServiceRequest(...).toJson()` rather than a
hand-written map, so a new required field on the model breaks the test at compile time instead
of silently turning it into a no-op. That is not hypothetical: the first draft of these tests
used hand-written maps and passed test 8 for the wrong reason — the record was being rejected
for a missing `expectedDays`, not for the unknown enum.

## Break-check

Run against the original code with `git stash push -- lib/`:

```
00:00 +0 -10: Some tests failed.
```

**10 of 10 failed without the fix; 10 of 10 pass with it.** The guard is load-bearing.

## Follow-on findings (not fixed here)

- `ServiceRequest.fromJson` casts `json['statusHistory']` and `json['attachments']` with a bare
  `as List` and no `?? const []`, unlike `flaggedRequirements` and `formFields` which both
  default. A record persisted before either field existed would throw. Entry-tolerant decoding
  now contains the blast radius to one record, but the asymmetry is worth closing.
- The guard clears a key on total corruption. That is a data-loss event for that citizen; it is
  logged, but there is no user-visible signal. Worth revisiting alongside FE 13's error states.
