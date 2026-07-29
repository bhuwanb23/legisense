# Legisense — TripGlide Operate Design Spec

**Date:** 2026-07-29  
**World:** TripGlide DNA (studied from user reference) — Approach A  
**Brand:** Legisense (never TripGlide copy)

## Intent

Replace Ink & Trust paper/serif with a **clean light Operate** system: white field, near-black accents, one modern sans, oversized radii, floating black dock, hero media card + pill chips. Same routes and mock flows; new visual language end-to-end.

## Tokens

| Token | Hex | Role |
|-------|-----|------|
| `bg` | `#F7F7F7` | App canvas |
| `surface` | `#FFFFFF` | Cards, fields, search |
| `ink` | `#1A1A1A` | Headings, primary fills, dock |
| `mute` | `#8A8A8A` | Subtitles, placeholders |
| `chip` | `#EEEEEE` | Idle chips |
| `rule` | `#E8E8E8` | Hairlines |
| Risk | green/amber/red | Functional only |

**Type:** Plus Jakarta Sans (display + UI). No Spectral. No Inter/Roboto.

**Radii:** card 32, search/chip/dock pill, filter disc circle, field 20.

**Elevation:** soft single shadow (`ink` @ ~6%, blur 24, y 8).

## Macrostructure

- Onboarding/auth: Letter — large bold sans title, black pill CTA, white fields
- Home/operate: Workbench — greeting+avatar, search+filter disc, chips, hero card, lists
- Analysis/read: Long Document — white cards on `bg`, black tabs/CTAs, risk semantic

## Shared atoms

1. Floating black dock (4–5 icons; active = white circle)
2. Pill search + black circular filter
3. Black/white selection chips
4. Hero feature card (doc visual + overlay meta + “Open analysis” black pill + white arrow disc)
5. Primary CTA: black full-width pill, white label
6. Fields: white fill, soft shadow or light rule, large radius

## Surfaces (in place)

Splash, Onboarding, Auth×6, Profile setup, MainShell, Home, Documents, Upload, Scan, Processing, Analysis hub + 4, Chat, Notifications, Profile.

## Out of scope

Backend, dark mode, TripGlide branding, travel photography as product truth (use abstract doc/gradient hero instead).
