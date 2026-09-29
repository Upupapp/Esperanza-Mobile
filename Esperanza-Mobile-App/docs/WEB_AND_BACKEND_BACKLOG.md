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

## A. Ready now — waiting only on the owner to merge and deploy

| # | What | Where | Order and notes |
|---|---|---|---|
| A1 | **SMS preference showed off but was sent on** (B-050). Settings on web and mobile told almost every citizen texts were off while the server texted them. One default now, shown and sent. | esperanza-backend branch `claude/youthful-ritchie-qvxwry`, `f2704f4` | Deploy with A2. Full backend gate green, PostgreSQL included. |
| A2 | **Event descriptions**: `events.description` (text, 2,000 max), accepted by POST/PUT `/admin/events`, returned by admin and public `GET /events`. | same backend branch, `05ccc12` | **Backend first**: migration `2026_09_28_000100_add_description_to_events`. |
| A3 | **Description box in the Web Admin** (Communications > Events > New Event), shown in Review Event and on the citizen Events page. | Esperanza-Web-Platform-frontend- branch `claude/youthful-ritchie-qvxwry`, `ef4bb60` | **After A2.** Merging to web `main` deploys on Netlify: do it once. Web gate green. |

Mobile already reads everything above; nothing more is needed on mobile for A1–A3.

---

## B. Backend work (esperanza-backend)

| # | What goes wrong | Where | Proposed fix |
|---|---|---|---|
| B1 | **Registration collects an ID that nothing can receive.** Mobile asks for a valid ID at sign-up, but no endpoint takes it and no reviewer would see it; the web's own "Verify Valid ID" is a `setTimeout` simulation. Mobile now tells the citizen the ID stays on the phone. | `POST /auth/citizen/register` (no file), `CitizenVerificationController::show` (no documents) | An upload on the verification path that the admin verification queue shows. Then mobile sends it. (PENDING 21) |
| B2 | **Liked announcements show un-liked after a refresh**, and the next tap un-likes them. | `GET /announcements` is public; `announcementRow()` has no `liked_by_me` | An authenticated variant or a `liked_by_me` field for a signed-in caller (community posts already have it). (PENDING 23) |
| B3 | **The in-app notification switch is stored but ignored.** The sender always delivers in-app (`NotificationService::queueDeliveries`), so a stored `in_app: false` does nothing. Mobile offers no in-app switch for this reason; the web's toggle sets all three channels together. | `NotificationPreference`, `NotificationService` | Either honour `in_app` or stop accepting it; document which. |
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
| C3 | **Citizen Balita calls the wrong path**: `/community-posts` instead of `/citizen/community-posts`, so the whole feed errors; likes, comments and reports too. | `citizen/announcements.blade.php:19`, lines 62–104 | Add the `/citizen` prefix. (PENDING 25, handoff §3) |
| C4 | **Admin Sakuna calls lack `/admin`** (all 45); the unprefixed `/sakuna/centers` silently hits the public endpoint. | `admin/sakuna.blade.php` | Add the `/admin` prefix. (PENDING 25) |
| C5 | **Internal Forms lack `/admin`.** | `admin/internal-forms.blade.php:26,27,116` | Add the prefix. (PENDING 25) |
| C6 | **User archive always 404s**: sends `u.id` where the route keys on `employee_id`. | `admin/users.blade.php:149` | Send `employee_id`. (PENDING 25) |
| C7 | **Citizen Dokyu and Tulong are still simulations** (`setTimeout`/localStorage), on both citizen and admin sides, though the routes exist. | citizen and admin request views | Wire them to the backend, as mobile is. (PENDING 25) |
| C8 | **Residents never see a published emergency alert on the website.** The backend serves them publicly; no citizen view asks. | `GET /alerts` (`SakunaController::publicAlerts`); nothing under `resources/views/citizen` | Show them on the citizen dashboard/Sakuna page, Filipino first, as mobile's Emergency tab does. (handoff §5) |
| C9 | **Web Settings' notification toggle sets all three channels at once** off `in_app`, so a citizen cannot choose texts without email, and the switch reads the ignored `in_app` flag (B3). | `citizen/settings.blade.php` (`togglePref`) | Separate SMS and email switches per category, as mobile has. |
| C10 | **Two-factor setup is a simulation**: "a frontend preview — no data is saved". | `citizen/settings.blade.php` (`enable2fa`) | Wire it to a backend feature, or remove the control until one exists. |
| C11 | **Data requests offer only "portability"**, with fixed text. The backend takes access, correction, erasure and portability with the citizen's own details. | `citizen/settings.blade.php` (`requestData`) | A small form like mobile's My Data Requests (kind + details + history). |

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

*(nothing yet — move items here with the commit that closed them)*
