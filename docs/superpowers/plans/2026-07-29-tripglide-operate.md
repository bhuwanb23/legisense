# TripGlide Operate — Implementation Plan

> **For agentic workers:** Spec: `docs/superpowers/specs/2026-07-29-tripglide-operate-design.md`. Status: **executed**.

## Goal

Replace Ink & Trust with TripGlide DNA across Legisense (Approach A).

## Tasks (done)

1. Lock `DESIGN.md` + `app_theme.dart` (bg/ink/mute, Plus Jakarta Sans, large radii)
2. Rebuild atoms: floating dock, search+filter, chips, hero card, CTAs, fields
3. Rebuild Splash / Onboarding / Home / Shell; cascade fonts app-wide
4. Padding for floating dock on Docs/Upload/Notifications/Profile
5. `flutter analyze` clean + widget tests green + hallmark log entry

## Verify

```bash
cd app && flutter analyze && flutter test
```

Hot **restart** the running app (`R`) to see the new Home + floating dock.
