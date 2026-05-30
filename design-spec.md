# design-spec.md

The frozen visual + behavioral contract for DeejAI screens. This file is authored by a sighted human (in fast mockups), not by agents. Agents and CI implement and verify against it — they never invent values or decide what a control means. If a value isn't here, stop and ask; don't guess from "what looks warm."

**Division of labor:** judgment happens here, once. Translation and enforcement happen downstream, forever. An agent that obeys this file produces warmth it cannot see.

---

## 1. Color tokens — source of truth: `DeejAIColors.swift`

Never write a color literal in a view. Every color resolves to a `DeejAIColors` token. Values below are the contract; the Swift file must match.

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| surface | #F5EFE2 cream | #291F14 walnut | screen background |
| surfaceElevated | #EDE8D4 | #382B1E | cards, up-next container |
| albumTint | #E0BD9E | #66472E | warm bleed behind art |
| trackBackground | #D9CCB8 | #4D3D2E | progress/slider track (unplayed) |
| accentPrimary | #D1733D terracotta | #DE7D47 | play button, progress fill, loved heart |
| accentPrimaryDark | #B35C2E | #BF612E | pressed states |
| accentSecondary | #266B66 teal | #2E807A | infinity (active), accents — sparing |
| accentSecondaryMuted | #4D857A | #5C948A | pills, subtle backgrounds |
| textPrimary | #38291E | #F5EFE2 | titles |
| textSecondary | #665240 | #E0D6C2 | artist, body |
| textTertiary | #9E8A70 | #B3A185 | secondary labels |
| textQuaternary | #B8A68C | #94806A | captions, times, unloved heart |

**Invariant C1:** zero `Color(red:`, `UIColor(red:`, or `#hex` literals in any file under `SwiftUI/DeejAI*` except `DeejAIColors.swift`. ✅ PASSES.

---

## 2. Type tokens — source of truth: `DeejAIFonts.swift`

Serif = Lora (titles, liner-notes feel). Sans = Nunito (everything else). All tokens use `Font.custom(_:relativeTo:)` so Dynamic Type scales.

| Token | Face / size / style | Use |
|-------|---------------------|-----|
| serifDisplay | Lora 32 bold / largeTitle | home greeting |
| serifTitle | Lora 24 bold / title | now-playing track title |
| serifHeadline | Lora 15 semibold / headline | card titles, mix names |
| serifSubheadline | Lora 13 semibold / subheadline | art-overlay text |
| sansBody | Nunito 16 medium / body | artist name |
| sansSubheadline | Nunito 13 medium / body | next/suggested artist |
| sansLabel | Nunito 13 medium / callout | "feel · settled", section labels |
| sansCaption | Nunito 11 semibold / caption | "UP NEXT", context header, play counts |
| sansCaptionBold | Nunito 11 bold / caption | numeric badges |
| monoTime | system 11 mono | elapsed/duration only |

**Invariant T1:** no `.system(size:` anywhere under `SwiftUI/DeejAI*` except `DeejAIFonts.swift` and the single `monoTime` token. ✅ PASSES — all 17 sites replaced.

---

## 3. Shape, spacing, shadow, motion

**Radii** — exactly three, no others:

- `radiusLg = 20` — album art, primary cards
- `radiusMd = 14` — up-next container
- `radiusSm = 8` — thumbnails

Use `.continuous` corner style everywhere.

**Spacing** — 4pt base; use these steps only: 4, 8, 12, 16, 20, 24, 28, 32, 40. No ad-hoc values like 6, 14, 18, 48.

**Shadow** — one warm shadow style only: color = black at 12% opacity, warm-shifted (never neutral gray); y-offset 4; blur 12. No other shadow recipes. ✅ PASSES.

**Motion** — one spring: `.spring(response: 0.4, dampingFraction: 0.8)` for state transitions, love-tap scale, art changes. No linear easing on user-facing transitions. ✅ PASSES.

---

## 4. Per-control semantics — what each control MEANS

This is where blind agents drift: they wire a control to the nearest existing primitive that compiles. These bindings are the contract.

**Love heart** — toggles persisted favorite. Reads `playable.isFavorite` on load; writes back (Core Data + `onToggleFavorite` server hook). Filled+accentPrimary when loved, outline+textQuaternary when not. ✅ DONE — must not regress.

**Infinity** — extends the queue with sequencer-selected sonically-similar tracks ("keep playing like this"). It is NOT repeatMode. ⚠️ OPEN BUG: currently wired to `RepeatMode.all` (repeat), which replays the existing queue instead of generating continuation. Rewire to the radio/sequencer extend path. `accentSecondary` (teal) when active.

**Up next** — data source must be the sequencer's predicted next track, not `getNextQueueItems`. ⚠️ OPEN BUG: currently reads the plain Amperfy queue while labeled "UP NEXT" (implies sonic similarity). Either wire the sequencer or change the label to match the real source. Label and source must always agree.

**Play/transport** — standard. Shuffle intentionally absent (a flow system doesn't randomize). Do not re-add.

**Feel pill** — the ONLY exposed model control. One human word ("settled"). Never expose epsilon / "drunk" / lookback / raw similarity params.

---

## 5. UIKit chrome — source of truth: `DeejAIAppearance.swift`

The app is UIKit+SwiftUI hybrid. Unstyled UIKit chrome leaking system blue/gray is the #1 "skinned" tell.

**Invariant U1:** appearance proxies driven from the same tokens, covering at minimum:

- `UINavigationBarAppearance` — set BOTH `standardAppearance` AND `scrollEdgeAppearance`. Background `surface`, title text `textPrimary`.
- `UITabBarAppearance` — both appearances. Selected item `accentPrimary`, background `surface`.
- Window/global `tintColor = accentPrimary`.
- `UISwitch.appearance().onTintColor = accentSecondary`
- `UISlider` min-track, table selection tint — all from tokens.

✅ PASSES.

---

## 6. CI gates (Xcode Cloud) — enforce without eyes

- **grep-lint script** (cheap, runs first, fails fast): assert invariants C1, T1, U1 and "no shadow recipe outside the approved one."
- **Snapshot tests** (swift-snapshot-testing), one per screen, light + dark, against approved reference images. Generate references in the same Xcode Cloud simulator/OS they're checked against.

**Workflow rule:** explore design in fast mockup → freeze values here → agents implement to this file → grep-lint + snapshot in CI → review build against the approved reference image (binary "matches / doesn't", not open-ended taste).

---

## 7. Library architecture (decided)

Segmented control: **Artists / Albums / Songs** — the only three top-level browse types.

Persistent control bar: search field (scoped) + sort menu (name A-Z, date added, recently played, play count asc/desc, random).

Filter chips: All / Favorites / Recently played — apply across whichever segment is active.

A-Z scrubber on the right edge when sorted by name.

Podcasts: removed by HIDING, not excision. Leave upstream code paths dormant.

---

## 8. Home playlist shelf (decided)

Playlists migrate from Library to Home as a secondary shelf beneath the hero/mixes.

"Chosen for you" (next-listen hero, mixes) above; "chosen by you" (playlists) below.

Playlist authoring: "+" on the shelf + edit affordances on detail. Don't lose create/edit flows.

---

## 9. Settings architecture (rules, not an inventory)

Two-tier rule: top level shows frequency-touched settings + category doors + app info. Everything granular lives one tap down.

Categories map to user INTENT: Playback, Library & Sync, Appearance, Account, Advanced/Developer.

Model-knob containment: granular behavioral controls → YES in Playback. Raw model parameters → walled in Developer behind "advanced" framing.

---

## Open must-fix list (this revision)

| # | Item | Status |
|---|------|--------|
| T1 | Replace .system(size:) with DeejAIFonts tokens | ✅ DONE |
| U1 | Add UIKit appearance proxies (both standard + scrollEdge) | ✅ DONE |
| Infinity | Rewire from repeatMode to sequencer queue-extend | ⚠️ OPEN |
| Up next | Wire sequencer OR soften label to match queue source | ⚠️ OPEN |
| Radii | Reconcile art 16→20 and off-scale spacing | ✅ DONE |
