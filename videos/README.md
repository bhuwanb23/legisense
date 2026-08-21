# HyperFrames Product Launch Video

**Project:** HyperFrames — "Render Video from HTML"  
**Runtime:** 75 seconds (target 73–77s)  
**Format:** H.264 1080p60, plus 9:16 social crop variant  
**Location:** `hyperframes-product-launch/`

## Directory Structure

```
videos/
├── .gitignore
├── README.md
└── hyperframes-product-launch/
    ├── composition.html        ← Master HyperFrames composition (entry point)
    ├── scenes/
    │   ├── 01-problem.html
    │   ├── 02-reveal.html
    │   ├── 03-contract.html
    │   ├── 04-runtimes.html
    │   ├── 05-workflows.html
    │   └── 06-close.html
    ├── assets/
    │   ├── sfx/
    │   │   ├── blip_01.wav
    │   │   ├── blip_02.wav
    │   │   ├── blip_03.wav
    │   │   ├── whoosh_01.wav
    │   │   └── whoosh_02.wav
    │   ├── voiceover.wav       ← 48kHz/24-bit mono, ~47s
    │   └── music_bed.mp3       ← 128 BPM electronic, royalty-free
    └── render/
        ├── hyperframes-launch.mp4      ← 16:9 master
        └── hyperframes-launch-social.mp4 ← 9:16 crop (0:40–1:05)
```

## Scene Map

| Scene | File | Time | Content |
|-------|------|------|---------|
| 1 — The Problem | `scenes/01-problem.html` | 0:00–0:10 | Macro cursor → timeline chaos → screen fracture |
| 2 — The Reveal | `scenes/02-reveal.html` | 0:10–0:20 | Code bloom → title lock HYPERFRAMES |
| 3 — The Contract | `scenes/03-contract.html` | 0:20–0:35 | Side-by-side → attribute diagram → file scroll → logo resolve |
| 4 — The Runtimes | `scenes/04-runtimes.html` | 0:35–0:50 | 7 badges ring → timeline scrub → runtime montage → waveform |
| 5 — The Workflows | `scenes/05-workflows.html` | 0:50–1:05 | CLI window → registry panel → use-case thumbnails |
| 6 — The Close | `scenes/06-close.html` | 1:05–1:15 | Logo pulse → CTA → URL lockup → fade |

## Production Notes

- All composition HTML uses `data-start` / `data-duration` timing attributes
- Animations are GSAP-based, seek-safe, deterministic
- Audio: VO track 1, music bed track 2 (ducked), SFX track 3
- Art direction: void black (#000000), electric cyan (#00E5FF), Inter / JetBrains Mono typography
- Music: 128 BPM electronic, low sub-bass, bright high-end sparkle
- VO: 140 WPM, ~110 words, ~47s delivery, slight compression, no reverb