# FE 01 — Persistence hardening

**Status:** complete
**Date:** 2026-08-29
**Base:** `7901100` (Windows/Android lane)
**Gate:** `flutter analyze` clean · `flutter test` **461 passed** (baseline floor was 450 at the
time the master command was issued; it had already moved to 458 before this command started)

---

## What the defect was

Every service starts `_restore()` from its own constructor and **nothing awaits that future**.
The restore did an unguarded `jsonDecode` + `fromJson`, so an undecodable payload threw *inside*
an unhandled future: the load flag was never flipped, `notifyListeners()` never fired, and
`AuthGate` (`main.dart:78`) rendered its `CircularProgressIndicator` **forever**. The only
recovery was clearing app data — not something a citizen can be talked through on a phone call.

The realistic trigger is **version skew**, not corruption. This app already ships five migrations
for persisted data that changed shape, and every one of them runs *after* the decode that would
throw.

---

## Correction to the measured baseline: there are 10 keys, not 6

The master command's baseline and the sweep that preceded it both state **6 preference keys**.
Measured directly (`grep -rhoE "'esperanza_[a-z_]+'" lib/`), there are **10**. FE 10's mandate
also says "covering all six keys" — that inventory would have shipped four keys short.

| # | Key | Written by | Payload shape | Read is guarded |
|---|---|---|---|---|
| 1 | `esperanza_citizen_session` | `CitizenSessionService` | JSON object — `CitizenAccount.toJson()` | yes |
| 2 | `esperanza_guest_mode` | `CitizenSessionService` | **bool** (typed, not JSON) | yes |
| 3 | `esperanza_service_requests` | `RequestsService` | JSON array of `ServiceRequest` | yes |
| 4 | `esperanza_balita_posts` | `BalitaService` | JSON array of `Announcement` | yes |
| 5 | `esperanza_master_file_documents` | `MasterFileService` | JSON object, `accountId → List<MasterFileDocument>` | yes |
| 6 | `esperanza_resident_profiles` | `ResidentProfileService` | JSON object, `accountId → ResidentProfile` | yes |
| 7 | `esperanza_read_notification_ids` | `NotificationsService` | JSON array of `String` | yes |
| 8 | `esperanza_duplicate_alert_resolutions` | `NotificationsService` | JSON object, `String → String` | yes |
| 9 | `esperanza_unverified_duplicate_kept_account` | `NotificationsService` | **plain String** (not JSON) | yes |
| 10 | `esperanza_onboarding_complete` | `OnboardingService` | **bool** (typed, not JSON) | yes — see below |

Three of the ten are **not JSON at all**. That matters: a guard written only around `jsonDecode`
does not cover them.

---

## Correction to the mandate: there was a seventh unguarded path

FE 01's mandate is framed entirely as "the six `_restore()` bodies" and "every enum
`firstWhere`". One path has **neither**, and fixing only what the mandate literally says would
have left the app still hangable:

`SplashScreen._run()` is started from `initState()` and never awaited. It calls
`OnboardingService.isComplete()`, which does `prefs.getBool(_key)`. Inside
`shared_preferences` that is a **checked cast**, so a value of the wrong type raises a
`TypeError`. Verified empirically rather than assumed:

```
PROBE RESULT: THREW _TypeError: type 'String' is not a subtype of type 'bool?' in type cast
```

When it throws, `Navigator.pushReplacement` never runs and the citizen sits on the **splash
screen** forever — one screen earlier than the `AuthGate` hang, and reached by a different
mechanism (a typed preference read, not a `jsonDecode`).

Guarded in two layers: `OnboardingService.isComplete()` now falls back to `false`, and
`SplashScreen._run()` wraps the call so anything added to that method later cannot re-open the
same hole. Falling back to `false` re-shows the three-screen welcome flow — a small annoyance
against an app that cannot be opened.

---

## The guard

`lib/services/persistence_recovery.dart` (new) centralises the recovery so every service does
the same thing:

1. **Record and log** the discard — `dart:developer log` for the IDE and `flutter logs`, plus
   `debugPrint` for a plain `adb logcat`, which is what is actually available when a citizen's
   handset is the only reproduction. Clearing a key destroys whatever that citizen had saved;
   it must never be silent.
2. **Clear only the narrowest keys** that can restore the boot.
3. **Never throw** — it is called from a `catch`, and a failure here would resurrect the hang it
   exists to prevent. The inner removal has its own `try`.

Each service's `_restore()` now sets its load flag and calls `notifyListeners()` from a
**`finally`**, not on the success path. That single change is what converts a hang into a
recoverable empty state.

| Service | Keys cleared on failure | Fallback state |
|---|---|---|
| `CitizenSessionService` | `esperanza_citizen_session` only | signed out |
| `RequestsService` | `esperanza_service_requests` | empty list |
| `BalitaService` | `esperanza_balita_posts` | empty list |
| `MasterFileService` | `esperanza_master_file_documents` | empty map |
| `ResidentProfileService` | `esperanza_resident_profiles` | empty map |
| `NotificationsService` | all three of its keys | empty |
| `OnboardingService` | `esperanza_onboarding_complete` | not complete |

`CitizenSessionService` deliberately clears **only** the session key — `esperanza_guest_mode` is
a separate, still-readable key, and destroying it would be a wider loss than the failure
requires. There is a test asserting exactly that.

`NotificationsService` is the one that clears more than one key: it restores three keys in a
single `try` and cannot tell which failed. Narrowing that means splitting the restore per key.
Recorded as a deliberate follow-up, not an oversight, and noted at the call site.

---

## Enum fallbacks, and why each

Zero `values.firstWhere` without `orElse` remain anywhere in `lib/`.

| Enum | Fallback | Why |
|---|---|---|
| `AttachmentCategory` | `other` | The enum already has an explicit unknown bucket. Correct by construction — no judgement needed. |
| `PostMediaType` | `image` | The two values are `image` and `video`. An unknown item renders as a still; choosing `video` would offer playback controls for something that may not play. |
| `ReceiptType` | `onsite` | Values are `gcash`, `maya`, `onsite`, `free`. `onsite` is the only one that asserts neither a specific digital payment channel the citizen may not have used, nor — as `free` would — that they paid nothing. Least-wrong claim about money. |
| `ServiceCategory` | `dokyu` | **The weakest of the four**, recorded as such. Values are `dokyu`, `tulong`, `sakunaIncident`; a wrong guess files the request under the wrong tab. It is still strictly better than throwing, which lost the *entire* request list. Revisit if a category is ever renamed in practice. |

The guardrail "a silent wrong default is a quieter version of the same bug" is why
`ServiceCategory` is flagged here rather than presented as settled.

---

## Test matrix

`test/corrupt_persisted_state_recovery_test.dart` — 11 cases.

| Case | Payload | Asserts |
|---|---|---|
| `CitizenSessionService` | not JSON | boots signed-out |
| `CitizenSessionService` | not JSON, guest flag set | session key cleared, **guest flag survives** |
| `CitizenSessionService` | not JSON | the discard is recorded, not silent |
| `RequestsService` | JSON object where a list belongs | boots, list empty |
| `BalitaService` | not JSON | boots |
| `MasterFileService` | JSON array where a map belongs | boots |
| `NotificationsService` | not JSON, two keys | boots |
| `ResidentProfileService` | JSON object of wrong type | boots |
| `OnboardingService` | `String` under a bool key | returns false, discard recorded |
| `OnboardingService` | `String` under a bool key | bad flag cleared |
| `RequestsService` | valid JSON, **unknown enum name** | the request survives — the whole list used to be lost |

The last one is the realistic trigger the mandate asks for specifically: a rename, not random
corruption.

### Watched failing before being trusted

Per the standing rules, every case was observed red before the fix landed.

- With `lib/` stashed, **all 8 original cases fail**, each reporting
  `<Service> never finished loading — the splash would spin forever`.
- With `onboarding_service.dart` alone stashed, **both new splash cases fail**.
- With the fix applied, **11/11 pass**.

The helper `_settle` is what encodes "must not hang": it gives up after 100 pumps, which is
precisely what the unguarded code did.

---

## Guardrails observed

- No timeout was wrapped around `AuthGate` — that would hide the throw and ship a slower
  version of the same bug.
- Nothing is caught and rethrown into the same unawaited future.
- All five existing migrations are untouched; they are the record of what shapes have already
  shipped to devices.
- Every discard is logged, and the narrowest key that fixes the boot is the one cleared.
- Suite total went **up** (450 → 461 across this and the preceding sweep), never down.

---

## Follow-ups this opened

1. `NotificationsService` restores three keys under one `try` — split per key to narrow the
   blast radius.
2. `ServiceCategory`'s `dokyu` fallback is a judgement call; revisit if categories are ever
   renamed.
3. FE 10's storage inventory must cover **10** keys, not the 6 its mandate names.
4. Three keys are not JSON. Any future audit of "decode safety" that greps for `jsonDecode`
   will miss them — as this one originally did.

---

## Addendum — entry-tolerant collection decoding (macOS lane, 2026-09-03)

Added while merging the macOS lane's concurrent FE 01 into this one. The rest of that
lane's work was superseded by this document's implementation and was dropped rather than
carried; this is the one part that was genuinely additive.

**What it changes.** `discardUnreadable` is all-or-nothing: it clears an entire key. That
is right for a payload that is not a collection at all, and much too blunt for one that
is — a single bad record cost a citizen *every request they had ever filed*, silently and
permanently. Their filed history is the part of this app they cannot reconstruct.

`PersistenceRecovery.decodeEach` / `.decodeEntries` decode a collection entry by entry.
The four collection restores — requests, balita, master file, resident profiles — now use
them. Each service keeps its own `catch`: entry-tolerance handles a bad *entry*, while a
payload of the wrong root type has no entries to be tolerant of and still falls through to
the whole-key discard. A skip is logged but is deliberately **not** recorded as a discard;
conflating the two would hide whole-key data loss behind routine noise.

**Why this is still reachable now that every enum has an `orElse`.**
`ServiceRequest.fromJson` casts `statusHistory` and `attachments` with a bare `as List` and
no default, unlike `flaggedRequirements` and `formFields` which both default. A record
written before either field existed still throws. That asymmetry is the live trigger and is
worth closing separately.

Tests: `test/collection_entry_tolerance_test.dart`, 4 cases. Break-checked — 3 of the 4 fail
without the change. The fourth asserts the whole-key discard still happens for a
wrong-root-type payload, and passes both ways by design: it guards the existing behaviour
against this addition, rather than testing the addition.

## Open disagreement between the lanes — two `orElse` defaults that assert something false

Raised, not unilaterally reverted: these are this document's own tested decisions, and the
macOS lane has no standing to overturn them mid-merge. **Both need an owner ruling.**

| Enum | Current default | The concern |
|---|---|---|
| `ReceiptType` | `onsite` | A receipt whose payment type this build cannot read now renders as an **on-site cash payment**. A receipt is the citizen's proof of how they paid; a GCash or Maya payment displaying as cash — or a `free` service displaying as paid on site — is a fabricated statement about money. Both `CLAUDE.md` files and the master command's own guardrail forbid exactly this. |
| `ServiceCategory` | `dokyu` | A Tulong (assistance) or Sakuna (incident) request whose category was renamed silently becomes a **Dokyu document request** — wrong tab, wrong service, wrong flow. `corrupt_persisted_state_recovery_test.dart` currently asserts this as correct. |

Both were introduced to stop a record being lost, which is a real and good intent — the
alternative the macOS lane shipped, skipping the record, loses it instead. **Neither option
is right.** The honest fix preserves the record *without* naming a value: an explicit
`unknown` member on each enum, rendered as "—" rather than guessed. That is a larger change
than a merge should carry, which is why it is filed here rather than done.

`PostMediaType` → `image` and `AttachmentCategory` → `other` are not in dispute:
`other` is a genuinely neutral member, and a broken media tile is a display bug rather than
a false statement.
