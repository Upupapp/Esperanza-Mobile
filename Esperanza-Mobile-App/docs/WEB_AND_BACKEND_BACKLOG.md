# Web and backend backlog — everything the mobile lane found that needs work elsewhere

**Kept by:** the mobile lane (`Upupapp/Esperanza-Mobile`). **Started:** 2026-09-28, at the owner's
request ("save all items need work on web or backend in one file for later").
**Measured against:** web `950eb0f` (origin/main), backend `9f4555c` (origin/main), unless an item says
otherwise.

One list, so nothing depends on remembering which review turned it up. Each item says what goes
wrong, where, and the proposed fix. Longer write-ups live where they are linked; this file is the
index. Labels: **MEASURED** (read from code or computed), **INFERENCE** (reasoned, not observed).

When an item is done, move it to "Done" at the bottom with the commit, rather than deleting it.

---

## A. Merged 2026-09-29 — two deploy steps left for the owner

| # | What | Where | State |
|---|---|---|---|
| A1 | **SMS preference showed off but was sent on** (B-050). Settings on web and mobile told almost every citizen texts were off while the server texted them. One default now, shown and sent. | esperanza-backend `main` at `05ccc12` (`f2704f4`) | **Merged** (full gate green, PostgreSQL included). **Not yet on the server**: deploy `main` to the Linode staging host with A2. |
| A2 | **Event descriptions**: `events.description` (text, 2,000 max), accepted by POST/PUT `/admin/events`, returned by admin and public `GET /events`. | esperanza-backend `main`, `05ccc12` | **Merged.** On the server: deploy, then `php artisan migrate` (`2026_09_28_000100_add_description_to_events`). Needs server access, which the cloud session does not have. |
| A3 | **Description box in the Web Admin** (Communications > Events > New Event), shown in Review Event and on the citizen Events page. | Esperanza-Web-Platform-frontend- branch `claude/youthful-ritchie-qvxwry`, `ef4bb60` (fast-forwards onto `main` `950eb0f`) | **Not merged**: the push to web `main` is the Netlify deploy and was held for the owner's explicit go-ahead. Safe to ship before A2 reaches the server (the old API ignores the field, the page hides an empty one), but descriptions typed before then are dropped, so ideally after A2. |

Mobile already reads everything above; nothing more is needed on mobile for A1–A3.

---

## B. Backend work (esperanza-backend)

| # | What goes wrong | Where | Proposed fix |
|---|---|---|---|
| B4 | **Evacuation centres have no coordinates.** "Nearest centre" and real directions are impossible; mobile searches maps by name and address instead. | `sakuna_centers` has no lat/lng | Add `lat`/`lng` (Web Admin sets them); mobile can then sort by distance and link exact directions. |
| B5 | **Incidents have no detail endpoint.** A citizen's report shows only what the list row carries; there is no timeline of what the MDRRMO did with it. | `GET /citizen/incidents` only; `SakunaIncidentEvent` exists but is staff-only | `GET /citizen/incidents/{ref}` with the citizen-safe part of its events. |
| B6 | **Event registration does not exist** (tickets, QR, capacity, check-in, as in the PAAIPE app). Mobile's event page stops at the details for this reason. | `events` | Owner decision first: it is a large feature (backend, Web Admin, mobile). |
| B7 | **Events have no image.** Every card shows a placeholder panel. | `events` has no image column; Web Admin says "Posters aren't part of this pass" | An image upload (signed, scanned, like other uploads), then web and mobile show it. |

---

## C. Web work (Esperanza-Web-Platform-frontend-)

Nothing open (C1 and C2 closed 2026-10-04, see Done).

---

## D. Owner or Municipality decisions (neither lane can close these alone)

| # | What | Notes |
|---|---|---|
| D1 | **Privacy Policy content**: the published policy (Web Admin > Settings > Site Content) has no section on device permissions (camera, photos, files) that the old mobile-only text had. | Add it through Site Content if wanted; mobile shows whatever is published. |
| D2 | **Privacy contact and date**: now come from the published policy; confirm the ICT Office contact and effective date there are correct. | Site Content, `privacy`. |
| D3 | **`Waiting Requirements` status** is on mobile only; recommended: retire it. | Mobile `test/status_parity_test.dart` marks it `PENDING OWNER DECISION`. |
| D4 | **Deploy order and timing** for section A. | Backend, then one web deploy; per the credit rule. |
| D5 | **Netlify branch builds**: confirm branch deploys and deploy previews are off, so branch pushes (like A3's) spend nothing. | Owner's credit rule; mobile `CLAUDE.md`. |

---

## Done

Closed 2026-10-04, second pass, on the owner's rulings. Committed on backend `e67f24c`, web
`749955f` and mobile `c8247d5`. **Web is pushed** (14:08, so live on Netlify); backend and mobile are
not. The owner pushes; the backend needs deploying to the staging host with `php artisan migrate` for
two new migrations (`2026_10_04_000100_create_citizen_identity_records`,
`2026_10_04_000200_tulong_case_lifecycle`). Until then the old server sends none of it, and web and
mobile fall back as before.

| # | What | Closed by |
|---|---|---|
| B1 | Registration's ID now reaches the LGU. | backend `b37ab74`: `GET/POST /citizen/verification/id` (ID type from the public `GET /id-types`, front, back and selfie), shown in the admin verification queue. IDs are kept with access audited and deleted when the account is archived (owner ruling). Web `a246300`; mobile `a5acd30`: sign-up sends the ID and a real camera selfie once signed in, with a "Send my ID again" retry. |
| B9 | The profile photo is an identification record. | backend `b37ab74`: `POST /citizen/profile/photo`, approved or rejected by staff (`/admin/citizens/{accountNo}/photo/approve`, `/reject`). Owner ruling: the account stays verified and the Digital ID keeps the old photo until the new one is approved. The 6-month cooldown is enforced on the server. Web `a246300`; mobile `a5acd30`. |
| B8 | One office, three names. | web `03bec80`: one name and one short name (MCRO) at the source; backend `e67f24c` vendors it (web `749955f`), so the catalogue's services carry the one name and mobile's alias map does nothing. |
| C1, C2 | Badge and secondary-text contrast (WCAG AA). | web `55617a9` (Cancelled and Archived badges; `text-slate-400` to `500` in 1,015 uses); mobile `68d4440`, `c7687aa`. |
| B-044 | Tulong ran Dokyu's document lifecycle. | Owner ruling: build the case flow. backend `3be7104`, `e42edf0`, `61ecf22`: Tulong's own eleven statuses (Submitted, Initial Screening, Assessment, For Approval, Assistance Processing, Ready for Release, Completed; Needs Requirements and Returned for Reassessment beside the line; Rejected and Cancelled), the case actions, the recommended and approved amounts, and proof of release. Web `749955f`: the staff case screen and the resident tracker. Mobile `c8247d5`: `lib/theme/tulong_status.dart`, the seven-step timeline and the approved amount. |

Closed 2026-10-04 (backend `main` `9d94cac`, web `main` `d1283b5`). The backend half is **not on the
staging server yet**: it still runs `67a5c5b-linkresident2`, and the web and mobile changes below that
call new endpoints degrade until it is deployed (`php artisan migrate` too, for A2).

| # | What | Closed by |
|---|---|---|
| B2 | Liked announcements show un-liked after a refresh. | backend `bb3a5b9`: a citizen token fills `liked_by_me` on `GET /announcements`; anonymous reads stay public (`null`). Mobile and web read it. |
| B3 | The in-app switch was stored but ignored. | backend `6dce6d7`: in-app is always on; `in_app` is optional on PUT, ignored when false, reported `true`. |
| C3 | Citizen Balita called the wrong paths. | web `44d1439` |
| C4, C5 | Admin Sakuna and Internal Forms lacked `/admin`. | web `ea958e6`. The Sakuna page had also never started at all: a stray double quote ended its Alpine component, fixed in `e6467aa` with a test and a gate step so it cannot recur. |
| C6 | "User archive sends `u.id`". | **Not a bug**: the page maps `id: u.employee_id`, so `u.id` is the employee ID (checked 2026-10-04). |
| C7 | Citizen and admin Dokyu and Tulong were simulations. | web `22a7cc9` (Dokyu), `7c9fa55` (Tulong), `a863ff4`, `ff7ba44`, `a6148ae`; backend `d20d8a0` adds the requirement attach endpoint the wizards need, and `27be104` the full request summary. Clicked through end to end against a local backend. |
| C8 | Residents never saw a published emergency alert. | web `44d1439`: the citizen dashboard shows them. |
| C9, C10, C11 | One notification switch for three channels; simulated 2FA; data requests offered "portability" only. | web `44d1439`: SMS and email switches per category; the 2FA control removed until a backend feature exists; the four request kinds with details and history. |
