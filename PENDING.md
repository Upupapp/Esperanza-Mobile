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

> **Web and backend work, in one place:** `Esperanza-Mobile-App/docs/WEB_AND_BACKEND_BACKLOG.md`
> lists every item that needs the web or backend lane (merge/deploy order, backend gaps, web
> defects, owner decisions). Items below that belong there are indexed from it.

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
| 26 | **Two web-owned fixes, handed to the web lane** — *deferred by the owner (2026-09-28): do after the next 10 tasks* | Cancelled/Archived badge contrast and the web's 1,054 `text-slate-400` uses. Exact changes in `Esperanza-Mobile-App/docs/HANDOFF_TO_WEB_LANE_2026-09-28.md`. Mobile lands its matching badge change only once web `main` carries it (parity rule). Not pushed from here: mobile doesn't commit to the web repo, and a web `main` push runs a Netlify build. |

| 27 | **Catalogue names the Civil Registrar three ways** (upstream data) | "Office of the Municipal Civil Registrar" (19 services), "Civil Registrar" (4), "Civil Registrar / appropriate local office" (1), in esperanza-backend's catalogue, vendored from the web config. Mobile groups them in the Dokyu office step (`lib/utils/office_name.dart`, 2026-09-28), so residents see one office; the data itself should be normalised at the source. In the web handoff §4. |
| 30 | **Profile photo is an identification record** (owner, 2026-09-29) — backend first | The photo is kept on the phone only; no endpoint takes it. Owner ruled it an identification record, so it must reach the LGU: backend upload + Digital ID/verification queue, then Web Admin, then mobile. Full plan: `docs/WEB_AND_BACKEND_BACKLOG.md` B9. |
| 28 | **Backend and web committed; server deploy and the web event-description merge left** (updated 2026-10-04) | esperanza-backend `main` is at `9d94cac` (everything through `05ccc12`, plus likes, in-app, requirement attach, issuance permission, request summary), certified on SQLite and PostgreSQL. The staging server still runs `67a5c5b-linkresident2`. Left: (1) deploy backend `main` to the Linode staging host and run `php artisan migrate`, which needs server access; until then the web wizard's attachments are refused (it says so, and the request still files) and mobile shows no attach section, since the old server sends no `attachable`; (2) web `main` is at `d1283b5`, pushing it is the Netlify deploy; the event-description branch `ef4bb60` is still unmerged. Details: backlog section A and Done. |

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

**Requirement documents and the real catalogue (2026-10-04):** a request's detail screen lists the
requirements the office has not decided yet and attaches each document (`POST
/citizen/requests/{ref}/requirements/{key}/attach`, backend `d20d8a0`), from a new file or the
Master File, and shows the file the server holds for each requirement. The screen now shows the
server's answer after a replace, attach or resubmit: it kept the first-loaded copy, so after a
flagged document was replaced Resubmit stayed disabled until the screen was reopened. A
document the server keeps offers Replace, no longer an inert Remove. The audited forms reach the
real catalogue's services by key: `brgy_clearance`, `osca_senior_citizen`, `mcro_marriage` and
thirteen others had fallen back to the generic wizard because their forms sit under the app's
older keys. Closed PENDING 23 (backend `bb3a5b9`) and 25 (web, see the backlog's Done). Pinned by
`test/requirement_attach_test.dart` and `test/service_form_specs_server_keys_test.dart`.

**Account and privacy (2026-09-28):** the Privacy Policy is now the one the Municipality publishes
for web and mobile (`GET /site-content/privacy`, Web Admin > Settings > Site Content), with its
effective date and contact section; it falls back to the copy saved on the last load, then to the
published version 1 bundled in `lib/content/privacy_policy_v1.dart`, so no `[TO BE PROVIDED]`
placeholder remains. Settings gained Change Password (`PUT /citizen/password`, same standard as
sign-up) and My Data Requests (`GET/POST /citizen/data-requests`: see, correct, delete, copy),
also reachable from the Privacy Policy. Pinned by `test/account_privacy_test.dart`.

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
