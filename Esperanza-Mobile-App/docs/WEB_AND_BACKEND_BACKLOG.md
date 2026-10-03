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
| B1 | **Registration collects an ID that nothing can receive.** Mobile asks for a valid ID at sign-up, but no endpoint takes it and no reviewer would see it; the web's own "Verify Valid ID" is a `setTimeout` simulation. Mobile now tells the citizen the ID stays on the phone. | `POST /auth/citizen/register` (no file), `CitizenVerificationController::show` (no documents) | An upload on the verification path that the admin verification queue shows. Then mobile sends it. (PENDING 21) |
| B4 | **Evacuation centres have no coordinates.** "Nearest centre" and real directions are impossible; mobile searches maps by name and address instead. | `sakuna_centers` has no lat/lng | Add `lat`/`lng` (Web Admin sets them); mobile can then sort by distance and link exact directions. |
| B5 | **Incidents have no detail endpoint.** A citizen's report shows only what the list row carries; there is no timeline of what the MDRRMO did with it. | `GET /citizen/incidents` only; `SakunaIncidentEvent` exists but is staff-only | `GET /citizen/incidents/{ref}` with the citizen-safe part of its events. |
| B6 | **Event registration does not exist** (tickets, QR, capacity, check-in, as in the PAAIPE app). Mobile's event page stops at the details for this reason. | `events` | Owner decision first: it is a large feature (backend, Web Admin, mobile). |
| B7 | **Events have no image.** Every card shows a placeholder panel. | `events` has no image column; Web Admin says "Posters aren't part of this pass" | An image upload (signed, scanned, like other uploads), then web and mobile show it. |
| B8 | **One office, three names** in the service catalogue: "Office of the Municipal Civil Registrar" (19), "Civil Registrar" (4), "Civil Registrar / appropriate local office" (1). Mobile groups them for display only. | catalogue data (vendored from the web config) | Normalise at the source; mobile's alias map (`lib/utils/office_name.dart`) then becomes a no-op. (PENDING 27, web handoff §4) |
| B9 | **The profile photo never leaves the phone.** A citizen's chosen photo (and its once-in-6-months rule) is stored on the device only; the LGU, the Digital ID and the web never see it. Mobile's preview says so for now. **Owner decision (2026-09-29): the profile photo IS an identification record.** | no profile-photo route in `routes/api.php`; `/citizen/digital-id` has no photo | 1) Backend: a signed, scanned upload on the citizen profile (`PUT /citizen/profile/photo`, image only, size-capped), stored like other uploads, returned by `GET /citizen/profile` and `GET /citizen/digital-id`; the 6-month cooldown enforced on the server; changes audited. 2) Web Admin: the photo in the verification queue and the resident record; the web Digital ID shows it. 3) Mobile: upload from the preview's Save, read it back on sign-in, show it on the live Digital ID, drop the "kept on this phone" note. Being an ID record, a photo change should probably send the account back through verification: confirm with the owner when the backend lands. |

---

## C. Web work (Esperanza-Web-Platform-frontend-)

| # | What goes wrong | Where | Proposed fix |
|---|---|---|---|
| C1 | **Two status badges fail WCAG AA**: Cancelled 4.34:1, Archived 2.34:1. Mobile mirrors the web component, so both change together. | `resources/views/components/ui/badge.blade.php` | Exact classes in [the web handoff §1](HANDOFF_TO_WEB_LANE_2026-09-28.md). Mobile lands the matching change once web `main` has it. **Owner deferred: after the next 10 tasks.** (PENDING 26) |
| C2 | **Secondary text is `text-slate-400` (2.56:1)**, used 1,054 times, mostly for text residents need to read. | `resources/views`, `resources/js` | Replace bare `text-slate-400` with `text-slate-500` (regex in handoff §2). **Owner deferred, as C1.** |

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
