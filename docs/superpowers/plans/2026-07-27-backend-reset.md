# Backend Reset Implementation Plan

> **For agentic workers:** Execute task-by-task on branch `new_backend`.

**Goal:** Delete Django stack, strip Flutter to UI shell, scaffold Express+TS backend, rename app folder.

**Architecture:** Monorepo with `app/` (Flutter UI-only) and `backend/` (Express health scaffold).

**Tech Stack:** Flutter 3.x, Node.js, Express, TypeScript

## Global Constraints

- No live HTTP from Flutter
- Empty/mock UI where APIs were
- TypeScript Express with GET /health only
- Rename `legisense/` → `app/`

---

### Task 1: Remove Django + related infra

- [ ] Delete `legisense_backend/`, `nginx/`, `scripts/`, `prototype_design/`, `sample/`, `.mimocode/`
- [ ] Delete `docker-compose.yml`, `docker-compose.dev.yml`, `docker.md`, `init-db.sql`, `env.example`
- [ ] Verify git status shows removals

### Task 2: Strip Flutter API + junk

- [ ] Delete `legisense/lib/api/`
- [ ] Delete generated utils (keep `responsive.dart` if real/used)
- [ ] Replace stub tests with one minimal `widget_test.dart`
- [ ] Empty/mock: home upload, documents, simulation, chat
- [ ] Remove unused deps from `pubspec.yaml` (`http` at minimum)
- [ ] `flutter analyze` — 0 errors

### Task 3: Rename + scaffold

- [ ] `git mv legisense app`
- [ ] Create `backend/` Express+TS with `/health`
- [ ] Rewrite README, CONTRIBUTING, `.gitignore`
- [ ] Verify `npm run build` / `node` health and Flutter analyze
