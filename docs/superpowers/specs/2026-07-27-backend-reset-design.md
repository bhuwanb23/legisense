# Legisense Backend Reset & Monorepo Cleanup

**Date:** 2026-07-27  
**Branch:** `new_backend`  
**Status:** Approved

## Goal

Remove the Django backend and all live API wiring. Leave a clean Flutter UI shell and a minimal Node/Express TypeScript scaffold so new backend work can start from scratch.

## Decisions

| Decision | Choice |
|----------|--------|
| Old backend | Delete from this branch (recoverable via `main` / git history) |
| Flutter API layer | Hard reset (option A) — no HTTP client |
| Screens that used APIs | Empty state or light mock data |
| Folder rename | `legisense/` → `app/` |
| New backend | `backend/` — Express + TypeScript, health route only |
| Infra | Remove Django Docker/nginx/Celery scripts |

## Remove

- `legisense_backend/`
- `nginx/`, `docker-compose.yml`, `docker-compose.dev.yml`, `docker.md`
- `init-db.sql`, root `env.example`
- `scripts/` (docker + celery helpers)
- `prototype_design/`, `sample/`, `.mimocode/`
- Flutter `lib/api/`
- Generated `lib/utils/*` junk (keep only real helpers if any, e.g. `responsive.dart`)
- Stub test bloat under `test/` (replace with one minimal widget test)
- Unused `http` (and other API-only) deps from `pubspec.yaml` when unused

## Keep / reshape

- Flutter app shell: intro, login (client-only), bottom nav, theme, language scope
- Page scaffolding for Home, Documents, Simulation, Profile, Notifications, Chat
- LICENSE, CONTRIBUTING (trimmed), rewritten README

## Target layout

```
legisense/                 # repo root
├── app/                   # Flutter (formerly legisense/)
├── backend/               # Node + Express + TypeScript scaffold
├── docs/superpowers/      # specs & plans
├── README.md
├── CONTRIBUTING.md
├── LICENSE
└── .gitignore
```

## Flutter UI rules after cleanup

- **Home:** upload UI may remain visually, but no network upload; empty/mock recent files
- **Documents:** empty list or few mock items; no analysis polling
- **Simulation:** empty / “coming soon” style empty state; no API
- **Chat overlay:** local empty conversation or disabled send; no Gemini call
- **Notifications / Profile:** local/static only
- App must build and open without a backend

## Backend scaffold

- Express + TypeScript
- `GET /health` → `{ status: "ok" }`
- `.env.example` with `PORT=3001`
- No DB, auth, or LLM yet

## Out of scope

- Porting Django features to Node
- Real auth
- Reconnecting Flutter to the new API
- Production Docker for the new stack
