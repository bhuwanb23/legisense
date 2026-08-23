---
format: 1920x1080
duration: 75s
message: "Know what you sign"
arc: PAS - hook, pain, agitation, solution tease, product intro, proof/demo, benefits, CTA
audience: everyday people signing rental agreements, NDAs, employment contracts, loan terms
mode: collaborative
music: confident minimal tech underscore
---

## Video direction

- **Palette system (from frame.md, normative):** canvas #FFFFFF with #F7F7F7 secondary grounds; all type ink #1A1A1A (muted ladder #9A9A9A); primary #B42318 is the ONLY accent - reserved for risk, traps, and the single emphasized word per act; positive #059669 reserved for checkmarks and plain-English cards; cards are 4% tint fill / 20% border / 14px radius, NO drop shadows anywhere (flat paper depth); pill chrome for chips/buttons; JetBrains Mono only for verbatim legalese excerpts; Plus Jakarta Sans for everything else.
- **Motion grammar:** long-tail decel everywhere (`power3` default, `expo.out` on fast arrivals) - smooth beats bouncy, zero overshoot. Reveal model: VO-paced sequential reveals - at t=0 only what the voiceover says enters; every further piece lands on its spoken cue spread across the back ~50% of the scene; never dump the canvas early (anti-slideshow). Aliveness during holds = subtle low-amplitude jitter or live-SVG internals ONLY; no lazy breathing, no back-half pan/push.
- **Rhythm / held frames:** Frame 3's second half is a deliberate breather after the pain act; Frame 5 ends on a long settled read; Frame 8 ends in perfect stillness (final card). Everything else reveals to the VO.
- **Negative list:** no bouncy/back.out/bounce.out/elastic.out entrances; no infinite repeat/yoyo; no Math.random or Date.now; no CSS transition/@keyframes animation (paused GSAP timeline only); no nav bars, footers, scrollbars, browser chrome, or real cursors outside the sanctioned cursor rules; no purple-blue "AI" gradients or floating bokeh; no slideshow front-load; no screensaver drift.
- **Caption band keep-out:** plan all content into the top ~83%; bottom band stays clear in every frame.

## Frame 1 - The signature test

- scene: Kinetic type on clean light canvas. Three escalating beats land solo: "You read every page." / "All fourteen of them." / "But did you understand it?" The word "understand" turns error-red and holds.
- duration: 4.395s
- transition_in: cut
- status: animated
- voiceover: "You read every page. All fourteen of them. But did you understand it?"
- src: compositions/frames/01-signature-test.html
- type: hook
- persuasion: Direct address - the viewer is the signer
- beat: unease + curiosity
- blueprint: kinetic-type-beats (Reproduce)
- focal: the three-line kinetic statement stack (typography is the subject; no captured assets)
- roles: none - pure typography beat
- sfx: riser, impact-bass-1

narrativeRole: Open in outcome language, in the viewer's own signing moment, and plant the question the whole video answers.
keyMessage: Reading is not understanding.

Scene 1 (0.0-2.0s): clean white ground; line 1 "You read every page." enters dead-center via kinetic beat-slam (kinetic-beat-slam), smooth long-tail settle; centered framing, type spans ~55% of canvas width; nothing else present.
Scene 2 (2.0-3.6s): instant hard-cut swap to line 2 "All fourteen of them." dropping to the muted gray rung (discrete-text-sequence); the swap itself is the beat; centered, same seat.
Scene 3 (3.6-6.0s): cut to line 3 "But did you understand it?" at the largest weight; on a fixed timeline hit aligned to the spoken "understand", that word flips ink to #B42318 with a compact scale attack-decay envelope driven by timeline position; slight size step-up vs prior lines (3:1 hierarchy).
Scene 4 (6.0-7.0s): hold the read perfectly still; at most subtle low-amplitude jitter on the final line.

## Frame 2 - Hidden in plain sight

- scene: A dense contract wall accumulates (page cards with legalese line textures). Red clause flags flare and pin on traps: "Unlimited liability", "Auto-renewal trap", "Forfeiture penalty". Slow zoom-out, then a push-in shoves pages to the edges as a two-part question builds center: "What are you / really agreeing to?"
- duration: 9.664s
- transition_in: crossfade
- status: animated
- voiceover: "Rental agreements. NDAs. Loan terms. And hidden inside - unlimited liability, auto-renewal traps, penalties you never saw coming."
- src: compositions/frames/02-hidden-traps.html
- type: pain_point
- persuasion: Pain agitation - traps named concretely
- beat: overwhelm into dread
- blueprint: overwhelm-surround (Adapt)
- focal: the pinned red trap flags over the document wall
- roles: none - all elements are HTML/CSS-built (page cards, flag pills, type); no captured assets
- sfx: whoosh-short, impact-bass-2

narrativeRole: Agitate the pain with named, recognizable traps so the relief beat lands hard.
keyMessage: One-sided clauses hide in documents you already sign.

Adapt: keep accumulate-surround-shove signature and the closing serif-weight question; swap tool icons for contract page cards and the avatar morph for named trap flags (story truth - the pain is documents, not app overload).

Scene 1 (0.0-2.5s): #F7F7F7 ground; page cards enter in two staggered groups, slight deterministic rotation scatter, layered-depth 3 layers (back pages dimmed via opacity gradient); each group lands as the VO names a document type; smooth spring-pop settle.
Scene 2 (2.5-6.0s): as each trap is named, its red flag pill pins onto a specific page - three sequential reveals, each a marker-style highlight sweep + pin; flags sit upper-third on their hosts; density rises.
Scene 3 (6.0-8.0s): slow push-in on the wall root; outer pages soften via selective blur so the flagged trio reads focal; surround pressure builds.
Scene 4 (8.0-10.0s): velocity-matched shove - virtual camera pushes in while pages slide to frame edges (viewport-change), opening center negative space; the two-part question builds word-group by word-group (dynamic-content-sequencing), second line lands in #B42318; holds still to the cut.

## Frame 3 - Enter LegiSense

- scene: Pages clear off all four edges. The LegiSense mark draws itself on center (upload arrow + magnifier glyph), the wordmark cascades beneath, tagline locks up: "Your AI Legal Advisor."
- duration: 3.712s
- transition_in: zoom-through
- status: animated
- voiceover: "LegiSense reads the fine print for you - before you sign it."
- src: compositions/frames/03-enter-legisense.html
- type: product_intro
- persuasion: Solution tease - relief named at peak tension
- beat: relief + intrigue
- blueprint: logo-assemble-lockup (Adapt)
- focal: the assembled brand lockup (mark tile + wordmark + tagline)
- roles: none - lockup is built geometry/SVG; no captured assets
- sfx: riser, sparkle

narrativeRole: Land the promise by beat 3; the brand arrives as the answer to frame 2's question.
keyMessage: LegiSense reads the fine print so you never sign blind.

Adapt: keep the mark-comes-to-exist signature and centered lockup resolve; the mark assembles via SVG self-draw instead of orbiting parts - calmer register fits the light brand.

Scene 1 (0.0-2.2s): white ground; rounded ink tile seats center; the magnifier-with-upload-arrow glyph self-draws stroke-by-stroke finishing as the VO reaches "LegiSense"; centered, mark ~20% canvas height.
Scene 2 (2.2-4.2s): wordmark "LegiSense" cascades letter-groups beneath the tile (dynamic-content-sequencing), tracking tightening to final; tagline "Your AI Legal Advisor." fades up on its spoken cue with a smooth settle.
Scene 3 (4.2-8.0s): deliberate breather - the 60px accent line draws under the tagline (svg-path-draw), a single bounded glow blooms once behind the mark (single bounded glow), then the completed lockup holds still with at most subtle jitter; no further motion.

## Frame 4 - It does the reading

- scene: App-surface card in TripGlide light UI. A file chip drops in, the Analyze button press fires working-state theater: status phrases swap ("Extracting text...", "Classifying type...", "Reading clauses..."), progress rail fills, then a receipt card cascades in with rows arriving and checking off (Extract, Classify, Clauses, Risks).
- duration: 8.555s
- transition_in: push-slide LEFT
- status: animated
- voiceover: "Upload any document - PDF, scan, paste, or link. It classifies, extracts, and reads every clause in seconds."
- src: compositions/frames/04-analysis-theater.html
- type: feature_showcase
- persuasion: Show-don't-tell proof - the machine visibly works
- beat: confidence
- blueprint: agent-progress-theater (Reproduce)
- focal: the working analysis card + checked-off receipt
- roles: none - UI reconstructed in HTML/CSS; no captured assets
- sfx: click, pop

narrativeRole: First proof beat - the core loop shown running, not claimed.
keyMessage: Any input format; full-clause analysis in seconds.

Scene 1 (0.0-2.2s): asymmetric 70/30 - app-surface card right; file chip drops into its header slot (smooth spring-pop settle); the Analyze pill presses with tactile compression-recovery (press-release-spring) exactly as the VO says "Upload".
Scene 2 (2.2-5.5s): working theater - status phrase swaps through "Extracting text..." / "Classifying type..." / "Reading clauses..." on threshold steps (discrete-text-sequence); progress rail fills scaleX beneath (stat-bars-and-fills), fill tinted #B42318; input-type tags (PDF/Scan/Paste/Link) cycle subtly in the header as the VO lists them (in-place token cycle).
Scene 3 (5.5-8.5s): receipt card slides up overlapping the card's lower-left (layered depth, soft overlap shadow-stack allowed here as elevation); four rows arrive one per cue, each green tick popping with a tiny press; rows read Extract / Classify / Clauses / Risks.
Scene 4 (8.5-10.0s): hold on the fully-checked receipt; subtle jitter nowhere needed - stillness carries it.

## Frame 5 - Legalese out, plain English in

- scene: Split-stage document view. Left column verbatim legalese excerpts in mono face; right column plain-English twins. Clause rows flip card-style one by one from legalese to plain. Above, a risk gauge counts up 0 to 87 and settles in the HIGH red band; two missing-protection chips spring in ("No dispute resolution", "Data retention vague").
- duration: 8.213s
- transition_in: push-slide LEFT
- status: animated
- voiceover: "Every clause gets a risk score. Every sentence becomes plain English. And missing protections get flagged - before they cost you."
- src: compositions/frames/05-plain-english.html
- type: feature_showcase
- persuasion: Feature-to-benefit translation - comprehension and protection
- beat: clarity + control
- blueprint: dataviz-countup (Adapt)
- focal: the risk gauge counting to 87 over the flipping clause pairs
- roles: none - document view rebuilt in HTML/CSS; no captured assets
- sfx: impact-bass-1, whoosh-short, notification

narrativeRole: The signature interaction - risk quantified and legalese translated live; this is the product's heart made visible.
keyMessage: You finally see what the document actually says.

Adapt: keep the count-up-ring signature as the gauge hero; add the clause state-swap as the second act and missing-protection chips as the third - three acts paced to the VO's three claims.

Scene 1 (0.0-2.5s): split-stage seats (left/right columns as static anchors); gauge donut top-right sweeps its stroke while the number counts 0-to-87 with size scaling on the climb (stat-bars-and-fills ring + scaled counter); "HIGH RISK" label stamps #B42318 as 87 lands on "...risk score."
Scene 2 (2.5-6.5s): as the VO says "plain English", right-column plain cards reveal one per clause pair - each row performs an in-place state swap: legalese text flips away with a quick rotateY half-turn and the plain twin resolves (discrete-text-sequence state change + velocity-matched seam); the second row lands outlined #B42318 as the emphasized example; reveals strictly sequential on the VO.
Scene 3 (6.5-9.5s): on "missing protections get flagged", two warning chips spring in beneath the columns (staggered smooth spring-pops); each chip carries a small alert dot that pulses twice, finite.
Scene 4 (9.5-12.0s): long settled read of the whole board - columns, gauge, chips; gauge dot may idle with the faintest finite breathe; otherwise still.

## Frame 6 - Ask your document

- scene: Chat surface card. A question types into the composer: "Can my landlord raise the rent by 15%?" Send press, brief thinking state, then an answer streams in with two citation chips pinned to clause numbers ("Clause 4.2", "Clause 9.1").
- duration: 5.205s
- transition_in: push-slide LEFT
- status: animated
- voiceover: "Have a question? Just ask. You get cited answers, straight from your own document."
- src: compositions/frames/06-cited-chat.html
- type: feature_showcase
- persuasion: One prompt-to-response round trip - proof of understanding
- beat: ease + trust
- blueprint: prompt-type-submit-generate (Reproduce)
- focal: the typed question streaming into a cited answer
- roles: none - chat surface rebuilt in HTML/CSS; no captured assets
- sfx: typing, click, pop

narrativeRole: Second proof beat - comprehension is interactive, not a static report.
keyMessage: Answers you can verify, cited to exact clauses.

Scene 1 (0.0-2.8s): chat card centered-right (rule-of-thirds); composer field gains focus ring; the question types character-by-character behind a blinking square-wave caret (discrete-text-sequence) timed so the last word lands as the VO finishes "Just ask."
Scene 2 (2.8-4.0s): send control presses (press-release-spring); user bubble snaps up into the thread; thinking dots pulse three beats, finite - brief, confident.
Scene 3 (4.0-7.5s): answer streams sentence-by-sentence into the assistant bubble (dynamic-content-sequencing); as the VO says "cited answers", two citation chips spring onto the bubble edge one after the other, reading Clause 4.2 / Clause 9.1.
Scene 4 (7.5-10.0s): hold the finished exchange; caret blink continues as a finite square-wave within the hold; nothing else moves.

## Frame 7 - Everything around it

- scene: Vertical benefit list self-assembles one row per second past a focal slot on the app card: "Deadline reminders", "Fairer counter-clauses", "Export reports", "Any jurisdiction". List clears and a payoff line lands: "Everything the fine print touches."
- duration: 5.312s
- transition_in: crossfade
- status: animated
- voiceover: "Deadlines tracked. Fairer counter-clauses drafted. Full reports, ready to share."
- src: compositions/frames/07-benefit-list.html
- type: benefit_highlight
- persuasion: Value stacking - accumulating breadth without a feature dump
- beat: aspiration + confidence
- blueprint: grid-card-assemble (Adapt)
- focal: the accumulating numbered benefit list
- roles: none - list and ghost app-card built in HTML/CSS; no captured assets
- sfx: pop, whoosh-short

narrativeRole: Breadth beat - the surrounding capabilities accumulate quickly so the close feels inevitable.
keyMessage: The protection continues past the reading - deadlines, negotiation, export.

Adapt: keep the staggered vertical-list accumulation signature; rows carry numbered step circles that stamp in with each arrival; the optional zoom-out is replaced by a clean upward clear into the payoff line.

Scene 1 (0.0-1.5s): asymmetric 40/60 - ghost app-card seats left as the static anchor (dimmed skeleton rows); right column empty and waiting.
Scene 2 (1.5-5.5s): four benefit rows arrive top-to-bottom roughly one per second, each on its VO phrase - row slides to slot with smooth settle while its step circle stamps with a mini count; rows co-resident and accumulating.
Scene 3 (5.5-7.5s): velocity-matched clear - the list exits upward while the payoff line "Everything the fine print touches." builds word-group by word-group center-right (dynamic-content-sequencing); matched upward velocity on both sides of the seam (cut-the-curve).
Scene 4 (7.5-9.0s): hold on the payoff line; still.

## Frame 8 - Know what you sign

- scene: Stage clears. The LegiSense lockup builds (mark draws on, wordmark cascades), camera pushes through negative space as giant CTA letters streak past and resolve on the held line: "Know what you sign." Sub-line settles beneath: "legisense.app".
- duration: 2.261s
- transition_in: zoom-through
- status: animated
- voiceover: "LegiSense. Know what you sign."
- src: compositions/frames/08-know-what-you-sign.html
- type: cta
- persuasion: Rule of three payoff - name, promise, action
- beat: resolve + motivation-to-act
- blueprint: logo-assemble-lockup (Reproduce)
- focal: the giant resolved tagline with the brand lockup above it
- roles: none - lockup and CTA built in HTML/CSS; no captured assets
- sfx: riser, impact-bass-2, sparkle

narrativeRole: Close on the message itself as the CTA; brand owns the final frame.
keyMessage: Know what you sign.

Scene 1 (0.0-2.5s): white ground; lockup row seats upper-center - mark glyph self-draws stroke-by-stroke, wordmark cascades beside it landing exactly on the spoken "LegiSense."
Scene 2 (2.5-5.2s): camera push-through - the root pushes in as giant CTA letter streaks fly past with directional motion blur (motion-blur-streak), decelerating to resolve the held line "Know what you sign."; the word "you" takes the single #B42318 emphasis on its spoken hit (timeline-aligned attack-decay).
Scene 3 (5.2-7.2s): sub-line "legisense.app" and the solid CTA pill settle beneath (spring-pop-entrance, smooth); one bounded glow blooms behind the lockup (single bounded glow).
Scene 4 (7.2-9.0s): perfect stillness on the final card - no jitter, the confidence of a held signature.
