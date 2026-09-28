# Handoff — Mobile lane → Web lane (2026-09-28)

**From:** the mobile lane (`Upupapp/Esperanza-Mobile`)
**To:** the web lane (`Upupapp/Esperanza-Web-Platform-frontend-`)
**Measured against:** web `950eb0f` (origin/main), backend `9f4555c`

Mobile does not commit to the web repository (both repos' lane rules), and a
push to web `main` triggers a Netlify build on Netlify's servers, which the
owner's hard rule forbids for this lane. So these are handed over as failure
modes with exact proposed changes, for the web lane to land and deploy on its own
terms. Labels: **MEASURED** = computed or read from the repo, **INFERENCE** = mine.

---

## 1. Two status badges fail WCAG AA — change them together

**Failure mode (MEASURED):** `resources/views/components/ui/badge.blade.php`:

| Status | Current classes | Contrast | AA (4.5) |
|---|---|---|---|
| Cancelled | `bg-slate-100 text-slate-500` | 4.34:1 | fails |
| Archived | `bg-slate-100 text-slate-400` | **2.34:1** | fails badly |

Mobile holds these to the web component exactly (`lib/theme/app_status.dart`,
`test/status_parity_test.dart`), so neither side can fix them alone without the
other drifting. That's why mobile hasn't changed yet.

**Proposed**, which keeps Draft, Cancelled and Archived distinguishable by
background shade:

```php
'Draft'     => ['bg-slate-100 text-slate-600 ring-slate-200', 'bg-slate-400'], // unchanged, 6.92:1
'Cancelled' => ['bg-slate-50 text-slate-500 ring-slate-200', 'bg-slate-400'],  // 4.55:1
'Archived'  => ['bg-slate-200 text-slate-600 ring-slate-300', 'bg-slate-400'], // 6.15:1
```

Mobile will land the identical change in `app_status.dart` the moment web
`main` carries it, and update the pinned exception in
`test/design_standard_test.dart`, which currently expects exactly these two
to fail.

## 2. Secondary text is `text-slate-400`, and that is 2.56:1

**Failure mode (MEASURED):** slate-400 (`#94A3B8`) on white is **2.56:1**, and
on slate-50 it is 2.45:1. That's below AA's 4.5:1. The web uses bare
`text-slate-400` **1,054 times** across `resources/views` and `resources/js`,
mostly for captions, timestamps and helper lines residents need to read.
Mobile fixed its own equivalent on 2026-09-28 (`AppColors.textMuted`
slate-400 → slate-500, 4.76:1 on white, 4.55:1 on slate-50).

**Proposed:** replace bare `text-slate-400` with `text-slate-500`. Leave the
variant-prefixed uses (`placeholder:text-slate-400` ×16,
`disabled:text-slate-400` ×3), because low contrast is the intended signal there.
One regex covers it: `(?<![:\w-])text-slate-400\b` → `text-slate-500`.
*INFERENCE:* a few uses are decorative icons, where darker is harmless.

## 3. API path drift (from the earlier sync audit; still open)

- **Balita:** `citizen/announcements.blade.php:19` calls `/community-posts`.
  The route is `/citizen/community-posts`, so the whole feed errors. Likes,
  comments and reports on lines 62–104 also need `/citizen`.
- **Admin Sakuna:** all 45 calls in `admin/sakuna.blade.php` need `/admin`.
  The unprefixed `/sakuna/centers` silently hits the public endpoint.
- **Internal Forms:** `admin/internal-forms.blade.php:26,27,116` need `/admin`.
- **User archive:** `admin/users.blade.php:149` sends `u.id`, but the route keys
  on `employee_id`, so it always 404s.

Full table: `PENDING.md` item 25 in this repo.

## 4. One office, three names in the service catalogue

**Failure mode (MEASURED, esperanza-backend `9f4555c`, which vendors the web config):** the
catalogue's `office` field names the Civil Registrar as "Office of the Municipal Civil
Registrar" (19 services), "Civil Registrar" (4) and "Civil Registrar / appropriate local
office" (1). Any screen that groups by office shows two Civil Registrars and splits their
services. Mobile now groups the three for display only (`lib/utils/office_name.dart`); the fix
belongs in the source config, after which mobile's alias map becomes a no-op.

