# Esperanza Web Platform — Project Constitution

Municipality of Esperanza, Masbate (Region V — Bicol Region), 20 barangays.
The canonical barangay list lives in `config/esperanza.php` — always pull
barangay names from there rather than hardcoding a list in a view. This file
is the permanent development constitution for this project. Every task in
this repo follows these rules unless the user explicitly overrides them in
the conversation.

## What this project is

A premium, enterprise-grade LGU digital platform with exactly two applications:

- **Citizen Portal**
- **Administrative Portal**

There is **no public marketing website** in this project.

Goal: a modern, production-ready frontend that can later be wired to real
backend APIs without rework.

## Hard rule: frontend only (Citizen/Admin web portals) — API layer is the exception

The two web portals (Citizen Portal, Administrative Portal) stay frontend
only: never generate Controllers beyond a bare `Route::view`/closure, Models,
Migrations, Seeders, business logic, DB queries, auth logic, authorization
logic, or middleware *for those portals' Blade routes*.

Use realistic mock data and frontend-only interactions for the web portals.
Build everything so it is *backend-ready* in shape (predictable prop/data
structures, clear seams) but contains no real backend code — except:

**Exception, added 2026-08-11 by explicit user override:** a real Laravel
Sanctum token-auth API under `routes/api.php` exists to serve a companion
mobile app. This is real backend code and is in scope going forward —
`app/Http/Controllers/Api/*`, `app/Http/Requests/Api/*`,
`app/Http/Resources/*`, Sanctum config/migrations, and `config/cors.php` are
legitimate, expected files in this repo. Keep this layer strictly
API-focused (JSON in/out, token auth, no Blade views) and never let it grow
into a parallel implementation of the web portals' UI logic. Never expose
web-admin-only concerns (session-based admin actions, CSRF-protected forms)
through `routes/api.php`.

## Tech stack

- Laravel 12 (routes/views only, per the rule above)
- Blade templates + Blade components
- TailwindCSS
- Alpine.js
- Lucide icons
- Chart.js or ApexCharts for charts
- Vite
- Laravel Sanctum (token auth for the companion mobile app's API only —
  see the API layer exception above)

## Design philosophy — non-negotiable

Every screen must feel like a premium SaaS product adapted for government:
modern, minimal, elegant, professional, fast, citizen-centered,
enterprise-grade, accessible, clean, trustworthy. No static-looking pages,
no Bootstrap-like layouts, no clutter, no outdated gov-UI look.

Default to including (don't wait to be asked):
smooth page transitions, micro-interactions, hover/active states, skeleton
loaders, shimmer effects, animated charts, beautiful empty states, animated
notifications, smooth dropdowns/sidebars/modals, progress indicators,
floating action buttons where appropriate, soft shadows, generous/premium
spacing, sparing gradients, responsive transitions, smooth scrolling. Every
interaction gets immediate visual feedback.

## Brand reference

The Bacoor City LGUID screenshots shared earlier are a **pure style
reference only** — layout patterns, color language, typography, component
style. No Bacoor text, copy, or branding appears anywhere in this project.
All actual branding (seal, photography) comes from the assets folder:
`C:\Users\admin\Desktop\esperanza assets`.

## Application structure

```
Citizen Portal
├── Authentication
├── Dashboard
├── Profile
├── Document Requests
├── Assistance Requests
├── Notifications
├── Government Directory
├── Announcements
├── Events
├── FAQs
├── Tutorials
├── Support
└── Settings

Administrative Portal
├── Authentication
├── Dashboard
├── Constituents
├── Resident Profiling
├── Document Requests
├── Assistance Requests
├── Reports
├── Analytics
├── Announcements
├── Events
├── Directory
├── User Management
├── Roles
├── Audit Logs (UI)
├── Municipality Branding
└── Settings
```

## Authentication

One entry screen: user chooses **Citizen Login** or **LGU Personnel Login**.
Citizen registration exists. Admin registration does not — admin accounts
are provisioned internally (UI can imply this, no backend needed).

## Standard workflows

- **Citizen Registration**: Registration → Verification → Resident Profile → Dashboard
- **Document Requests**: Citizen (Select Document → Fill Form → Submit) → Admin (Verify → Approve → Prepare → Ready → Released → Completed)
- **Citizen Assistance**: Citizen (Submit Request) → Admin (Review → Assign → Approve → Release → Completed)
- **Announcements**: Draft → Review → Publish → Archive

## Universal status system

Reuse exactly these status names everywhere — never invent new ones:

Draft, Submitted, Pending Review, Under Verification, Assigned, Processing,
Waiting Requirements, Approved, Rejected, Ready for Release, Released,
Completed, Cancelled, Archived.

## Component architecture

Always build reusable Blade components — never duplicate UI. Expected
component library: buttons, cards, tables, forms, inputs, status badges,
modals, drawers, sidebars, topbars, breadcrumbs, charts, statistic cards,
notifications, empty states, skeleton loaders, pagination, search.

Before writing new markup: check whether an existing component covers it,
extend existing layouts, follow established naming conventions, keep
folders organized, refactor rather than duplicate.

## Mock data

Always realistic Philippine LGU content: Filipino names, real Esperanza,
Masbate barangays (see `config/esperanza.php`), realistic announcements/
document requests/citizen data. No Lorem Ipsum unless explicitly requested.

## Development process for every task

1. Understand the feature.
2. Reuse existing layouts/components before creating new ones.
3. Build modular, scalable code.
4. Add modern interactions by default (see design philosophy above).
5. Make it responsive.
6. Use realistic mock data.
7. Keep visual consistency with what's already built.
8. Keep it structured so backend integration later is straightforward.

Never redesign existing patterns unless the user explicitly instructs it.

## Output bar

Every deliverable: production-ready, enterprise-grade, responsive,
accessible, beautiful, modern, premium, interactive, modular, scalable,
backend-ready, frontend-only.
