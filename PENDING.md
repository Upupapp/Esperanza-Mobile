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
| 18 | ~~"New Request" is inert on first arrival~~ — **RETRACTED, not an app defect** | Disproved by `test/new_request_fab_reachability_test.dart`: the FAB opens the catalogue after a single frame, for both Dokyu and Tulong. The IndexedStack "two FABs" theory was also wrong — finders skip offstage widgets, so only one is found. What remains is an **unexplained harness artifact** in the device walk, folded into item 19. Do not go looking for a bug in the button. |
| 19 | **The walk's coverage figure is an upper bound, and something absorbs its taps** | `_tapIfPresent` counts a tap as a visit whenever `tester.tap` does not throw — which it does not when a tap lands on an inert widget. The `_confirm` markers are trustworthy; the raw 62 is not. **The web lane independently hit-tested the failing taps** (`HANDOFF_FROM_WEB_LANE.md` §2) and found the cause is pointer interception, not dead controls: the nav taps land on `AbsorbPointer`/`IgnorePointer`/`_RenderTheater`, and the "New Request" tap lands on a **`RenderImage`** at a completely different offset. An overlay or a full-bleed image is sitting over the controls. They also diagnosed the run's abort: `warnIfMissed` reports through `FlutterError`, which the walk redirects to collect layout errors, so the framework kills the run before it prints. **Fix the redirect first** — everything else is unmeasurable until the report survives. |
| 15 | **Tulong wizard end to end** | Only Dokyu is walked to submission. Tulong reaches its request list and catalogue only. |
| 16 | **Remaining wizard breadth** | 62 destinations are walked. Registration, the resident-profile sub-screens (family, household, review, submission confirmation), report-a-problem and the Sakuna incident flow are reached shallowly or not at all. |
| 17 | **Backend Master Command** | Offered, not started. Spec Section 5 already enumerates the missing Web-Admin APIs; the front-end contract from FE 13 would feed it. |

| 21 | **Registration collects an ID that nothing can receive** — backend/owner decision | Checked against esperanza-backend `9f4555c` (2026-09-28). `POST /auth/citizen/register` takes no file, the admin verification queue (`CitizenVerificationController::show`) shows no documents, and the web app's own "Verify Valid ID" (`citizen/profile.blade.php:23`) is a `setTimeout` simulation. `POST /citizen/papeles` stores a file, but no reviewer reads papeles when verifying, so sending the ID there would be a false promise. Needs a backend endpoint on the verification path first; until then mobile's ID step (and simulated face scan) are UI only. |
| 23 | **Backend: announcement likes carry no per-citizen state** | `GET /announcements` is public and `announcementRow()` has no `liked_by_me`, so a liked announcement shows un-liked after refresh and the next tap un-likes it. Community posts do carry it. Fix is backend-side (an authenticated variant or field). |
| 26 | **Two web-owned fixes, handed to the web lane** — *deferred by the owner (2026-09-28): do after the next 10 tasks* | Cancelled/Archived badge contrast and the web's 1,054 `text-slate-400` uses. Exact changes in `Esperanza-Mobile-App/docs/HANDOFF_TO_WEB_LANE_2026-09-28.md`. Mobile lands its matching badge change only once web `main` carries it (parity rule). Not pushed from here: mobile doesn't commit to the web repo, and a web `main` push runs a Netlify build. |
| 25 | **Web frontend ↔ backend drift (web repo, read-only from this lane)** | Audited 2026-09-28 (web `950eb0f`, backend `9f4555c`): the web's citizen Balita calls omit `/citizen` (whole feed errors, `announcements.blade.php:19`); all 45 admin Sakuna calls omit `/admin` (`admin/sakuna.blade.php`); Internal Forms omits `/admin`; user archive sends `u.id` where the route keys on `employee_id` (`admin/users.blade.php:149`); Dokyu/Tulong on both citizen and admin sides are still `setTimeout`/localStorage simulations though the routes exist. For the web lane to fix. |

| 27 | **Catalogue names the Civil Registrar three ways** (upstream data) | "Office of the Municipal Civil Registrar" (19 services), "Civil Registrar" (4), "Civil Registrar / appropriate local office" (1), in esperanza-backend's catalogue, vendored from the web config. Mobile groups them in the Dokyu office step (`lib/utils/office_name.dart`, 2026-09-28), so residents see one office; the data itself should be normalised at the source. In the web handoff §4. |

## Deferred by decision

| # | Item | Decision |
|---|---|---|
| 12 | **FE 05 — 200% text-scale walk** | **Cancelled by the owner, 2026-09-03.** Reverted; nothing shipped. The technical blocker *was* solved before cancelling: a second `runApp` in one process hangs, but pumping `EsperanzaMobileApp` directly avoids `runApp`, and `platformDispatcher.textScaleFactorTestValue` propagates. One run reached 44/48 destinations with **no layout overflows** — the 2 misses were drawer entries pushed below the fold by the larger text, unconfirmed. Restorable in one commit if revisited. |
| — | **`Waiting Requirements` status** | Mobile carries a status that appears in **zero** files on the current web platform. Inert (migrated to `Under Review` on load) and marked `PENDING OWNER DECISION` in `test/status_parity_test.dart`. Recommendation: retire it. Not this lane's call. |

## Known and accepted, worth not rediscovering

- **The pre-push gate must be installed by hand** (`sh scripts/install-hooks.sh`). Git does not
  version `.git/hooks`, so a fresh clone has no gate and nothing says so — the push just
  succeeds. Mitigated by putting the command in `CLAUDE.md`, which agents load automatically;
  not eliminated. Raised by the backend lane (bus #0004) after losing exactly this way.


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

**Simulated features wired to the backend (2026-09-28):** notifications (`GET
/citizen/notifications` + read; the fabricated sample alerts such as "Typhoon Advisory" were
removed), profile edits (`PUT /citizen/profile`, identity lock, verify-by-code mobile change),
resident profile (`PUT/GET /citizen/resident-profile`; the self-verify demo panel removed), Digital
ID (`GET /citizen/digital-id`, live card + signed QR), Report a Problem (`POST
/citizen/support/tickets`, backend categories), Master File (`/citizen/papeles` sync, upload,
download, archive). Pinned by `test/portal_wiring_test.dart`, `test/notifications_test.dart`,
`test/resident_profile_service_test.dart`.

**Backend contract pass (2026-09-28, against esperanza-backend `9f4555c`):** every endpoint mobile
calls checked against `routes/api.php` and its controller. Fixed: all Balita engagement calls
(likes, comments, community feed, posting, reporting) lacked the `/citizen` prefix and 404'd;
paging reads the backend's `meta.page`; announcement titles are no longer dropped; incident
reports now go to `POST/GET /citizen/incidents` (they posted a non-existent `service_key` to
`/citizen/requests`), with a stable `client_uuid` so a retry cannot file twice. Everything else
(auth, catalogue, requests, events, directory, hotlines, centres) matched field for field.
Pinned by `test/incident_reports_test.dart` and the route assertions in
`test/api_integration_hardening_test.dart`.

**API integration hardening (2026-09-28):** revalidates the session on warm start (an LGU
verification now reaches Dokyu without re-login); a 401 signs out locally; login refuses a
tokenless reply; every collection pages to the end; one malformed row no longer blanks a list;
Balita shows announcements even when community posts fail, keeps announcement likes, resolves
relative image URLs, and shows a citizen's new post immediately; events in calendar order;
hotline/directory dialling reduced to one clean number; transition remarks reach the timeline;
multipart uploads go through the injected client. Pinned by `test/api_integration_hardening_test.dart`
and `test/balita_live_feed_test.dart`.


FE 01 persistence hardening (both lanes merged) · FE 02 synthetic identities · FE 03 iOS build +
62-destination automated device walk · FE 04 status parity · FE 05 partial · FE 06 design tokens ·
FE 07 single project · FE 08 reachability · FE 09 product metadata · FE 10 data at rest ·
FE 12 gate ergonomics · FE 14 documentation truth · the fabricated-enum ruling (`a10a3fc`) ·
unguarded list casts (`9ea3a40`) · `AppCard` ink fix (`1426035`) · onboarding rebuild verified
closed on device (`904cc5d`).
