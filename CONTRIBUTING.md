# Contributing to Legisense

Thanks for helping rebuild Legisense.

## Branch

Feature work for the new stack lives on `new_backend` (and short-lived branches cut from it). Do not push secrets (`.env`, API keys).

## Setup

1. Backend: `cd backend && cp .env.example .env && npm install && npm run dev`
2. App: `cd app && flutter pub get && flutter run`

## Before opening a PR

- Backend: `npm run typecheck`
- App: `flutter analyze` (no errors) and `flutter test`
- Keep the Flutter app offline-safe until API routes are intentionally wired

## Scope notes

- `app/` — Flutter UI shell; reconnect to the API deliberately, feature by feature
- `backend/` — Express + TypeScript; add routes under `src/` as features land
- Design notes: `docs/superpowers/`
