# CLAUDE.md

Personal iOS music app — a fork of Amperfy (Swift, UIKit + SwiftUI hybrid; Ampache/Subsonic/Navidrome backend). This file is the source of truth for project intent. Read it fully each session.

## Thesis

The goal is **not discovery**. It's listening to more of the music I already own, with zero friction. The app acts as a personalized, context-aware pipeline (Deej-AI–style sonic-similarity embeddings + real completion rates + context) so my local library never feels like a forgotten archive.

Two load-bearing consequences:
- **Zero friction** means the right thing plays on open / CarPlay without me deciding. The primary verb is *radio* ("keep playing like this"), not browsing.
- **Resurfacing is a separate mechanism from preference.** Optimizing only on completion creates the forgotten archive it's meant to abolish. Exploitation (what fits now) and exploration (loved-but-unplayed) are different jobs.

## Pipeline shape (for UI honesty)

Two stages, kept separate: **selector** = context + completion-conditioned-on-context picks the pool; **sequencer** = sonic similarity orders it so it flows. Similarity is a precompute-once embedding + cheap nearest-neighbor at play time. **No LLM in the hot path** — playback decisions must be instant and deterministic.

## Design vocabulary (warm mid-century modern)

The aesthetic is a deliberate rejection of Liquid Glass: warm, flat, **solid color blocks** — no frosted translucency, no glass effects on content surfaces. Coherent MCM thesis, not a recolor.

- **Palette**: cream backgrounds, terracotta hero accent, deep teal secondary (sparing), warm brown text (never pure black). Album-art–derived tint wash behind cover art (DominantColors dep already in tree).
- **Type**: serif for track/album titles (liner-notes feel), rounded/humanist sans for everything else.
- **Shape/depth**: generous corner radii (16–24pt), warm-tinted soft shadows — never neutral gray, never glassy floating.
- **Motion**: spring physics, not linear easing. The love-tap spring is the model.
- **Copy**: human, warm. Context header ("evening, friday"). "up next · flows on" signals the sequencer's pick. One-word "feel" pill is the *only* exposed model knob.
- **Restraint**: 2–3 radii, one shadow style, one motion curve, constrained palette, repeated everywhere. Repetition reads as intentional; scattered effects read as a skin.

## Hard rules (DO NOT)

- **Never scatter literal RGB/hex in views.** Everything routes through semantic tokens (`textPrimary`, `surface`, `accentPrimary`, …) — not paint names.
- **Tokens must be UIColor-based with explicit light/dark pairs** (asset-catalog Color Sets or dynamic `UIColor { traitCollection }` providers), exposed to SwiftUI via `Color(uiColor:)`. The *same* source must drive UIKit appearance proxies. This is a hybrid app — unstyled UIKit chrome (nav bars, tab bars, switches, table selection, search cursor) leaking system blue is the #1 "skinned" tell. Style both `standardAppearance` AND `scrollEdgeAppearance`.
- **Never ship a control that animates but doesn't persist.** The love heart and infinity toggle were local `@State` no-ops in the first build — beautiful and meaningless. Any signal-capture control must read initial state from the model and write back to it.
- **Keep Dynamic Type alive.** Custom fonts load via `Font.custom(_:size:relativeTo:)` — never bare `.system(size:)`, which disables accessibility scaling.
- **Don't expose model parameters.** No "Drunk"/epsilon/lookback sliders. Opinionated defaults; at most one soft human control.
- **Don't surface labels the backend can't back up.** "flows on" must reflect the real sequencer, or soften the label until it does.

## Known issues from first build (now-playing screen)

`Amperfy/SwiftUI/DeejAINowPlaying/` — `DeejAINowPlayingView.swift`, `DeejAIPlayerState.swift`, `DeejAIColors.swift`.

1. **Heart is a no-op** — toggles local `isLoved`, never touches `playable.isFavorite`, never reads initial state. This is the most important control in the app (feeds the completion/love signal). Wire to the real model (`AbstractPlayable` favorite handling; `RatingView` exists in tree).
2. **Infinity is a no-op + recessive** — ~~local `radioContinues` bool~~ → **behavior resolved (2026-05-30); hierarchy still open.** Now drives real sonic-similarity continuation (Subsonic `getSimilarSongs2` via `requestSimilarSongs`), NOT `repeatMode`: `toggleContinuation()` on enable appends similar tracks to the queue now and engages the shared "Instant Mix After End" policy (the `AudioPlayer.playNext` queue-empty path) so the intentional control and the passive setting share one engine. State reads `settings.user.isAutoMixAfterEnd`. **Still open:** give it real visual hierarchy near the transport — currently `DeejAIColors.teal`/`.tanLight`, pending the token refactor (build order #4).
3. **Up-next reads the plain Amperfy queue**, not the sequencer — label says "flows on" but isn't yet true.
4. **`DeejAIColors` is SwiftUI-only, flat RGB, no dark mode.** Refactor to UIColor-based dynamic semantic tokens feeding both SwiftUI and appearance proxies.
5. **Serif is system serif (New York)** — a default. Register a deliberate humanist/transitional face via `UIAppFonts`.
6. Progress timer polls every second even when paused — gate on `isPlaying`. Verify `subsubtitle` is actually the album. `ScrollView` on a non-scrolling screen allows rubber-band bounce.

## Build order

1. Wire the heart → real `isFavorite` (read + write). **Do this first.**
2. Wire infinity → real state; fix its hierarchy.
3. Make up-next honest (wire sequencer or soften label).
4. Token refactor → UIColor dynamic semantic tokens + UIKit appearance proxies. (Vocabulary lock — do before designing new screens so they inherit a real system.)
5. Custom font + Dynamic Type.
6. Then: home/launch screen (the other half of zero-friction — one confident pre-decided "just play", not a wall of options).

## Workflow

- Work on a branch; commit current state before agentic edits.
- Run `AmperfyKitTests` before considering changes done; tests trigger SwiftFormat (Google Swift Style).
- When corrected, add a rule here so the mistake doesn't repeat.
