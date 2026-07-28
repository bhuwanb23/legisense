---
name: Legisense
description: Soft-blue legal AI companion — calm, precise, citizen-first
colors:
  sky-wash: "#EAF3FB"
  sky-mist: "#F7FBFE"
  cloud: "#FFFFFF"
  primary-navy: "#0B2C5E"
  ink-soft: "#3A5A80"
  accent-sky: "#7EB6E8"
  accent-soft: "#B7D6F2"
  progress-idle: "#C9DDF0"
  shadow: "#0B2C5E14"
typography:
  display:
    fontFamily: "Epilogue"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  tagline:
    fontFamily: "Epilogue"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.45
    letterSpacing: "0"
  body:
    fontFamily: "Epilogue"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0"
  button:
    fontFamily: "Spectral"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.01em"
rounded:
  sm: "12px"
  md: "24px"
  lg: "32px"
  pill: "999px"
  field: "18px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "40px"
  xxl: "56px"
components:
  button-continue:
    backgroundColor: "{colors.cloud}"
    textColor: "{colors.primary-navy}"
    typography: "{typography.button}"
    rounded: "{rounded.pill}"
    padding: "18px 32px"
    height: "56px"
  progress-active:
    backgroundColor: "{colors.primary-navy}"
    rounded: "{rounded.pill}"
    height: "8px"
    width: "36px"
  progress-idle:
    backgroundColor: "{colors.progress-idle}"
    rounded: "{rounded.sm}"
    height: "8px"
    width: "8px"
---

## Overview

Legisense is a citizen-first legal AI companion. The visual world is a **soft sky-blue studio**: airy wash backgrounds, deep navy type, white pill actions, and one calm motion moment per screen. Inspiration: Dribbble soft-blue splash compositions (centered hero, generous whitespace, pill CTA) — adapted for a legal product without cold corporate chrome.

**First surface (Splash):** brand mark (Lottie) centered in the upper field, wordmark + tagline below, then auto-route. No CTA on splash.

## Colors

| Token | Hex | Use |
|-------|-----|-----|
| `sky-wash` | `#EAF3FB` | Primary background / gradient start |
| `sky-mist` | `#F7FBFE` | Gradient end / quiet zones |
| `cloud` | `#FFFFFF` | Primary buttons, cards |
| `primary-navy` | `#0B2C5E` | Headings, active progress, brand ink |
| `ink-soft` | `#3A5A80` | Taglines, secondary copy |
| `accent-sky` | `#7EB6E8` | Soft decorative shapes, Lottie accents |
| `accent-soft` | `#B7D6F2` | Ambient blobs / progress idle neighbors |
| `progress-idle` | `#C9DDF0` | Inactive onboarding dots |

Always light ambient. Dark mode is out of scope for v1.

## Typography

- **Display / brand:** Epilogue Bold — geometric, confident, not a default “AI SaaS” face.
- **Body / tagline:** Epilogue Medium/Regular — same family for cohesion.
- **Action (Continue etc.):** Spectral SemiBold — a quiet legal serif on white pills, matching the inspiration’s serif CTA.

Never use Inter, Roboto, Arial, or system UI as display.

## Layout

- Mobile-first, one composition per viewport.
- Splash vertical rhythm: ~55% hero (logo), ~45% identity + breathing room.
- Horizontal padding: 28–32px.
- Brand name is the hero-level signal; tagline supports it, never outranks it.
- Soft ambient blobs may float behind the logo; they are atmosphere, not content cards.

## Elevation & Depth

- Continue button: soft offset shadow `0 10px 28px` at `{colors.shadow}` — never a zero-offset glow.
- Logo sits flat or with a whisper of lift; no multi-layer neon stacks.

## Shapes

- Large soft radii: screen chrome feel ~32px language; CTAs are full pills.
- Progress: one long navy pill + square-ish idle ticks (inspiration pattern).
- Decorative blobs: heavily rounded / organic ovals in `accent-soft`.

## Components

### Splash
- Centered Lottie logo mark (2–3s loop or entrance).
- Wordmark **Legisense**.
- Tagline: **Your AI Legal Advisor**.
- Auto-redirect after **2.5s** → Onboarding (first launch) or Home (returning).

### Continue button (onboarding onward)
- Full-width white pill, Spectral label, soft shadow.
- Navy label at high contrast on white.

### Progress indicator (onboarding)
- Active: navy capsule; idle: soft square ticks.

### Auth (Register / Login / OTP / Reset / Profile)
Layout DNA from soft consumer auth references (icon fields, pill CTA + arrow disc, circular socials, airy stack) — **Legisense navy/sky tokens only**, never coral/pink dating palettes.

**Minimalist rules:** ≤3 fields on Register/Login · short titles · no terms toggles / remember-me chrome · Epilogue everywhere on auth (no mixed “perfect” display faces).

| Token / component | Spec |
|-------------------|------|
| Field | Soft fill `#F3F7FC`, radius **18**, leading icon, focus navy 1.4px |
| Primary CTA | Navy pill, Epilogue Bold white, trailing **white arrow disc**, height 58 |
| Social | Circular discs (Google / Apple / GitHub), not full-width slabs |
| Divider | Hairline + “or sign up/in with” |
| OTP | Soft-fill boxes, radius 16, Epilogue Bold digits |
| Screen padding | 28px horizontal; title 28 / subtitle 14 |

Demo OTP: `123456`. Social is UI-only until backend.

### Home dashboard (Page 10)
Layout DNA from soft smart-home dashboards (greeting header, navy hero, circular filters, soft cards, elevated center nav) — **Legisense navy/sky only**.

| Element | Spec |
|---------|------|
| Background | Sky mist → wash vertical gradient |
| Header | Avatar initial · time greeting · bold name · bell → Notifications tab |
| Welcome banner | Navy card, radius 24, white Epilogue 20: “Hello [Name], ready to review a document?” |
| Primary CTA | Same auth navy pill + arrow disc: “Upload / Scan Document” |
| Type filters | Horizontal circular discs; active = navy fill |
| Stat cards | White, radius 24, soft offset shadow; Total / High Risk / Deadlines |
| Recent docs | Soft tiles; risk chip; tap → Analysis stub |
| Bottom nav | 5 items; center Upload elevated navy `+` disc |

Fonts: Epilogue throughout app chrome (no Inter/system). Mock stats/docs until backend.

### Upload (Page 11) & Processing (Page 12)
| Element | Spec |
|---------|------|
| Upload options | 2×2 soft white tiles: File · Scan · Paste · URL |
| Meta | Max 20 MB · PDF/DOC/DOCX/TXT · privacy encryption note |
| Proceed | Navy pill; enabled only after a selection |
| Scan preview | Crop guide frame · Retake / Use Photo · mock OCR spinner |
| Processing | Lottie mark · 6 step checklist · ETA · legal tip · Cancel |
| Completion | Auto-push Analysis stub |

Mock only — no real OCR/backend yet.

## Do's and Don'ts

**Do**
- Keep the monochromatic blue world consistent across splash → onboarding → home.
- Prefer one authored motion moment (logo entrance) over scattered micro-animations.
- Route splash by first-run preference; never strand the user on splash.
- Use navy filled primary buttons on auth screens (Dribbble black → brand navy).
- Keep dashboard cards soft-white with navy accents; center Upload is the only elevated disc.

**Don't**
- Don’t put a Continue button on the splash (it auto-advances).
- Don’t use purple gradients, cream+terracotta editorial tropes, or dark neon tech looks.
- Don’t copy the iridescent glass cube / black-white SaaS chrome from auth moodboards.
- Don’t use cards in the splash hero.
- Don’t overlay badges/chips on the logo.
- Don’t borrow orange/purple accents from smart-home moodboards onto the dashboard.
