---
workflow: product-launch-video
flow: automation
storyboard: yes
message: "Know what you sign"
destination: youtube
aspect: 1920x1080
language: en
length: 75s
angle: sign-with-eyes-open
audience: everyday people signing rental agreements, NDAs, employment contracts, loan terms
---

## Intent

A ~75-second launch promo for LegiSense, an AI-powered legal document intelligence
platform (Flutter app + Node backend). The story is a fear-to-relief arc: dense legalese
and hidden traps first, then LegiSense translating every clause into plain English so
anyone can sign with their eyes open. Confident, reassuring, product-true — the visuals
mirror the actual app's TripGlide Operate light design language (ink #1A1A1A on light
surfaces, Plus Jakarta Sans), not a generic dark-tech look.

## Assets

- videos/README.md — the structural template this video adapts (6-scene arc, timing,
  production-notes format); content re-targeted at LegiSense.
- app/lib/theme/app_theme.dart — brand tokens: ink #1A1A1A, surface #FFFFFF, bg #F7F7F7,
  mute #8A8A8A, chip #EEEEEE, rule #E8E8E8, error #B42318; radii 12/20/32/pill.
- docs/diagrams/*.svg — pipeline and feature reference material for scene 3–5 content.

## Customizations

- Scene 4: clause rows flip verbatim legalese to plain English (the signature interaction).
- Risk gauge count-up in scene 4.
- Stat count-ups allowed where they support the story (docs analyzed / deadlines caught).

## Notes

- No live website capture — text-only/no-capture mode; all visuals are invented motion
  graphics in the app's design language.
- VO: English TTS, ~110 words at ~140 WPM across the piece.
- Music bed ducked under VO; SFX minimal (whoosh/blip set).
- Deliver 16:9 master; a 9:16 social crop variant follows after the master renders.
