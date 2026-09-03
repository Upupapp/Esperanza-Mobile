# Esperanza Mobile — pending register

> **Cross-lane:** `HANDOFF_FROM_WEB_LANE.md` answers the web lane's sweep — the
> device walk aborts for a **harness** reason (not the onboarding rebuild), and
> `rectangle_cityhall.jpg` was the LGU sign-in hero on the web side and is fixed
> there. Read it before the next mobile push.


Every unfinished item, with **why** it is unfinished. Updated 2026-09-03 (macOS lane).

This exists because a tracker held only in a chat session is lost when the session ends, and
this repository is worked by two lanes that cannot see each other's terminals. If you finish an
item, move it to **Done** with its commit — do not delete it, so the arc stays visible.

---

## Blocked on the owner — do not attempt

| # | Item | Why it is blocked |
|---|---|---|
| 1 | **Public-repo PII — git history** | `Reference_forms/` holds real residents' scanned documents, and every retired real identity is still in the history of a **public** repo and in every existing clone and fork. FE 02 fixed HEAD only. Removing it means a history rewrite, a force-push, and treating the data as already fetched. That is an owner decision with a notification obligation attached. |
| 2 | **Release signing** (FE 11) | Android `release` still signs with the **debug** keystore; iOS has no `DEVELOPMENT_TEAM`. Both need credentials only the owner holds. Neither platform can produce a distributable artifact until then. |

## Ready to start — nothing blocking

| # | Item | Notes |
|---|---|---|
| 14 | **Paid-service wizard flow** | **In progress, not shipped.** The branch is written and demonstrably enters the paid wizard (`Step 1 of 5` — one step more than the free service, i.e. the payment step), but the walk's tap-effect detector false-positives on it and aborts before submission, so the receipt is still unwalked. Work preserved at `/Users/user/esperanza-fe14-wip/app_walk_test.STASHED-60-25.dart` (macOS lane). See §11 of the FE 03 deliverable. |
| 18 | **"New Request" is inert on first arrival** | Reproducible across three runs: on first arrival at the Dokyu or Tulong request list, the FAB is on screen and two taps do nothing; the same finder taps it successfully later in the same run. Most plausibly the list is still loading, with nothing on screen saying so. A citizen tapping it immediately gets no response and no feedback. |
| 19 | **The walk's coverage figure is an upper bound** | `_tapIfPresent` counts a tap as a visit whenever `tester.tap` does not throw — which it does not when a tap lands on an inert widget. The `_confirm` markers are trustworthy; the raw 62 is not. A before/after effect check works but false-positives when a pushed route's text overlaps the route beneath. |
| 15 | **Tulong wizard end to end** | Only Dokyu is walked to submission. Tulong reaches its request list and catalogue only. |
| 16 | **Remaining wizard breadth** | 62 destinations are walked. Registration, the resident-profile sub-screens (family, household, review, submission confirmation), report-a-problem and the Sakuna incident flow are reached shallowly or not at all. |
| 17 | **Backend Master Command** | Offered, not started. Spec Section 5 already enumerates the missing Web-Admin APIs; the front-end contract from FE 13 would feed it. |

## Deferred by decision

| # | Item | Decision |
|---|---|---|
| 12 | **FE 05 — 200% text-scale walk** | **Cancelled by the owner, 2026-09-03.** Reverted; nothing shipped. The technical blocker *was* solved before cancelling: a second `runApp` in one process hangs, but pumping `EsperanzaMobileApp` directly avoids `runApp`, and `platformDispatcher.textScaleFactorTestValue` propagates. One run reached 44/48 destinations with **no layout overflows** — the 2 misses were drawer entries pushed below the fold by the larger text, unconfirmed. Restorable in one commit if revisited. |
| — | **`Waiting Requirements` status** | Mobile carries a status that appears in **zero** files on the current web platform. Inert (migrated to `Under Review` on load) and marked `PENDING OWNER DECISION` in `test/status_parity_test.dart`. Recommendation: retire it. Not this lane's call. |

## Known and accepted, worth not rediscovering

- **`ServiceRequest.fromJson` scalars.** `statusHistory` and `attachments` now default, but required
  non-null scalars (`expectedDays`, `fee`, `office`, …) still throw per record if absent. Entry-tolerant
  decoding contains the blast radius to one record; the asymmetry is not closed.
- **`PersistenceRecovery` narrow-clearing is unverified on device.** The guard demonstrably fires and
  logs, but whether the key removal lands in the container was confounded by `cfprefsd` caching.
- **`NotificationsService` clears three keys at once** because it restores all three under one `try`
  and cannot tell which failed. Noted at the call site by the Windows lane as a follow-up.
- **Two iOS Swift packages track branch `master`** (`DKCamera`, `DKPhotoGallery`, via `file_picker`), so
  `Package.resolved` is the only thing making an iOS build reproducible.

## Done this programme

FE 01 persistence hardening (both lanes merged) · FE 02 synthetic identities · FE 03 iOS build +
62-destination automated device walk · FE 04 status parity · FE 05 partial · FE 06 design tokens ·
FE 07 single project · FE 08 reachability · FE 09 product metadata · FE 10 data at rest ·
FE 12 gate ergonomics · FE 14 documentation truth · the fabricated-enum ruling (`a10a3fc`) ·
unguarded list casts (`9ea3a40`) · `AppCard` ink fix (`1426035`) · onboarding rebuild verified
closed on device (`904cc5d`).
