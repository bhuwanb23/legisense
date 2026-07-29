---
name: Legisense
description: Ink & Trust — editorial legal AI companion
colors:
  paper: "#F7F4EE"
  paper-2: "#EFE9DF"
  cloud: "#FFFFFF"
  ink: "#0A1F3D"
  ink-2: "#3D4F66"
  accent-gold: "#B8954A"
  rule: "#D9D2C5"
  shadow: "#0A1F3D14"
typography:
  display:
    fontFamily: "Spectral"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  body:
    fontFamily: "Epilogue"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.5
  button:
    fontFamily: "Spectral"
    fontSize: "17px"
    fontWeight: 600
rounded:
  sm: "8px"
  md: "16px"
  lg: "20px"
  pill: "999px"
  field: "12px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "40px"
---

# Design — Legisense (Ink & Trust)

A locked design system. Every surface reads this before emitting UI. Do not regenerate per page — amend this file when the system grows.

## Genre

**editorial** — legal counsel voice: calm, precise, citizen-first. Operate mode for app chrome.

## Macrostructure family

- Marketing / onboarding: Letter (typographic hero, generous leading)
- App Operate: Workbench (header + primary action + dense content)
- Content / analysis: Long Document (sectioned reading, hairline rules)

## Theme

| Token | Hex | Use |
|-------|-----|-----|
| `paper` | `#F7F4EE` | App background |
| `paper-2` | `#EFE9DF` | Field fills, muted strips |
| `cloud` | `#FFFFFF` | Cards, sheets |
| `ink` | `#0A1F3D` | Headings, primary fills |
| `ink-2` | `#3D4F66` | Secondary copy |
| `accent-gold` | `#B8954A` | Sparse: active tab, focus whisper, score accents — never large fills |
| `rule` | `#D9D2C5` | Hairline borders |
| Risk greens/ambers/reds | semantic only | Risk scores, not decoration |

Always light. Dark mode out of scope for v1.

## Typography

- **Display:** Spectral Bold/SemiBold — roman only (no italic headers).
- **Body / UI:** Epilogue Regular–Bold.
- **Mono (OTP / scores):** JetBrains Mono optional.
- Never Inter, Roboto, Arial, or system UI as display.

## Layout & shape

- Horizontal padding 24–28px.
- Card radius 16; field 12; CTAs full pills.
- Single soft offset shadow; hairline rules; no multi-layer glow, no ambient blobs.

## Components (summary)

- **Primary CTA:** Ink fill, Spectral label, height 56, pill.
- **Fields:** paper-2 fill, rule border, ink focus 1.4px.
- **Bottom nav:** Ink active + gold underline/dot; center Upload elevated ink disc.
- **Analysis:** Masthead + risk gauge; tabs; denser cards on paper.
- **Chat:** Thread on paper; ink bubbles for user, cloud for AI.

Demo OTP: `123456`. Social/upload/OCR remain mock until backend.

## Do's and Don'ts

**Do**
- Keep Ink & Trust consistent splash → home → analysis.
- Prefer Spectral for screen titles; Epilogue for UI chrome.
- Use gold sparsely.

**Don't**
- Soft sky radial washes, dating-app coral, smart-home orange/purple.
- Cream+terracotta editorial tropes or purple-on-white SaaS defaults.
- Italic display headers; invented metrics; fake browser chrome.
