# design-spec.md

The frozen visual + behavioral contract for DeejAI screens. **This file is authored by a sighted human (in fast mockups), not by agents.** Agents and CI implement and verify *against* it — they never invent values or decide what a control means. If a value isn't here, stop and ask; don't guess from "what looks warm."

Division of labor: **judgment happens here, once. Translation and enforcement happen downstream, forever.** An agent that obeys this file produces warmth it cannot see.

---

## 1. Color tokens — source of truth: `DeejAIColors.swift`

Never write a color literal in a view. Every color resolves to a `DeejAIColors` token. Values below are the contract; the Swift file must match.

| Token | Light | Dark | Use |
|---|---|---|---|
| `surface` | `#F5EFE2` cream | `#291F14` walnut | screen background |
| `surfaceElevated` | `#EDE8D4` | `#382B1E` | cards, up-next container |
| `albumTint` | `#E0BD9E` | `#66472E` | warm bleed behind art |
| `trackBackground` | `#D9CCB8` | `#4D3D2E` | progress/slider track (unplayed) |
| `accentPrimary` | `#D1733D` terracotta | `#DE7D47` | play button, progress fill, loved heart |
| `accentPrimaryDark` | `#B35C2E` | `#BF612E` | pressed states |
| `accentSecondary` | `#266B66` teal | `#2E807A` | infinity (active), accents — sparing |
| `accentSecondaryMuted` | `#4D857A` | `#5C948A` | pills, subtle backgrounds |
| `textPrimary` | `#38291E` | `#F5EFE2` | titles |
| `textSecondary` | `#665240` | `#E0D6C2` | artist, body |
| `textTertiary` | `#9E8A70` | `#B3A185` | secondary labels |
| `textQuaternary` | `#B8A68C` | `#94806A` | captions, times, **unloved heart** |

**Invariant C1:** zero `Color(red:`, `UIColor(red:`, or `#hex` literals in any file under `SwiftUI/DeejAI*` except `DeejAIColors.swift`. (Currently passes — keep it.)

---

## 2. Type tokens — source of truth: `DeejAIFonts.swift`

Serif = **Lora** (titles, liner-notes feel). Sans = **Nunito** (everything else). All tokens use `Font.custom(_:relativeTo:)` so Dynamic Type scales.

| Token | Face / size / style | Use |
|---|---|---|
| `serifDisplay` | Lora 32 bold / largeTitle | home greeting |
| `serifTitle` | Lora 24 bold / title | now-playing track title |
| `serifHeadline` | Lora 15 semibold / headline | card titles, mix names |
| `serifSubheadline` | Lora 13 semibold / subheadline | art-overlay text |
| `sansBody` | Nunito 16 medium / body | artist name |
| `sansSubheadline` | Nunito 13 medium / body | next/suggested artist |
| `sansLabel` | Nunito 13 medium / callout | "feel · settled", section labels |
| `sansCaption` | Nunito 11 semibold / caption | "UP NEXT", context header, play counts |
| `sansCaptionBold` | Nunito 11 bold / caption | numeric badges |
| `monoTime` | system 11 mono | elapsed/duration **only** |

**Invariant T1 (OPEN — must fix):** no `.system(size:` anywhere under `SwiftUI/DeejAI*` except `DeejAIFonts.swift` and the single `monoTime` token. ~17 sites currently violate this — they render in system San Francisco (not Lora/Nunito) AND disable Dynamic Type. Replace each with the matching `DeejAIFonts.` token.

---

## 3. Shape, spacing, shadow, motion

**Radii — exactly three, no others:**
- `radiusLg` = 20 — album art, primary cards *(note: art is currently 16; spec target is 20 — reconcile)*
- `radiusMd` = 14 — up-next container
- `radiusSm` = 8 — thumbnails
Use `.continuous` corner style everywhere.

**Spacing — 4pt base; use these steps only:** 4, 8, 12, 16, 20, 24, 28, 32, 40. (No ad-hoc values like 6, 14, 18, 48.) Reconcile existing `spacing: 6`, `spacing: 14`, `spacing: 48` to the nearest step.

**Shadow — one warm shadow style only:** color = black at 12% opacity, *warm-shifted* (never neutral gray); y-offset 4; blur 12. No other shadow recipes.

**Motion — one spring:** `.spring(response: 0.4, dampingFraction: 0.8)` for state transitions, love-tap scale, art changes. No linear easing on user-facing transitions.

---

## 4. Per-control semantics — what each control MEANS (not just looks like)

This is where blind agents drift: they wire a control to the nearest existing primitive that compiles. These bindings are the contract.

- **Love heart** — toggles persisted favorite. Reads `playable.isFavorite` on load; writes back (Core Data + `onToggleFavorite` server hook). Filled+`accentPrimary` when loved, outline+`textQuaternary` when not. ✓ DONE — must not regress.
- **Infinity** — **extends the queue with sequencer-selected sonically-similar tracks** ("keep playing like this"). It is **NOT** `repeatMode`. **OPEN BUG:** currently wired to `RepeatMode.all` (repeat), which replays the existing queue instead of generating continuation. Rewire to the radio/sequencer extend path. `accentSecondary` (teal) when active.
- **Up next** — data source **must be the sequencer's predicted next track**, not `getNextQueueItems`. **OPEN BUG:** currently reads the plain Amperfy queue while labeled "flows on" (implies sonic similarity). Either wire the sequencer or change the label to match the real source. Label and source must always agree.
- **Play/transport** — standard. Shuffle intentionally absent (a flow system doesn't randomize). Do not re-add.
- **Feel pill** — the ONLY exposed model control. One human word ("settled"). Never expose epsilon / "drunk" / lookback / raw similarity params.

---

## 5. UIKit chrome — source of truth: a single appearance-config driven from `DeejAIColors`

The app is UIKit+SwiftUI hybrid. Unstyled UIKit chrome leaking system blue/gray is the #1 "skinned" tell, and it's nearly invisible on a casual device glance — so it must be enforced mechanically, not by eye.

**Invariant U1 (OPEN — must fix):** appearance proxies do not exist yet (zero matches in the ViewController layer). Add a single setup, driven from the same tokens, covering at minimum:
- `UINavigationBarAppearance` — set BOTH `standardAppearance` AND `scrollEdgeAppearance` (missing the latter = bar snaps to default on scroll-to-top). Background `surface`, title text `textPrimary`.
- `UITabBarAppearance` — `standardAppearance` AND `scrollEdgeAppearance`. Selected item `accentPrimary`, background `surface`.
- Window/global `tintColor` = `accentPrimary`.
- `UISwitch.appearance().onTintColor`, `UISlider` min-track, table selection tint — all from tokens.

---

## 6. CI gates (Xcode Cloud) — enforce without eyes

1. **grep-lint script** (cheap, runs first, fails fast): assert invariants C1, T1, U1 and "no shadow recipe outside the approved one." A regex pass catches the entire font/literal/proxy class of drift before a build is even worth doing. Most "it's fine" casualties die here.
2. **Snapshot tests** (`swift-snapshot-testing`), one per screen, light + dark, against approved reference images. Generate references in the **same Xcode Cloud simulator/OS** they're checked against (font hinting/scale differ across machines, or you'll chase phantom diffs). A snapshot verifies *matches approved reference* — NOT *reference is good*. Human sighted approval happens once, at reference-update time.

**Workflow rule:** explore design in fast mockup → freeze values here → agents implement to this file → grep-lint + snapshot in CI → review build against the approved reference image (binary "matches / doesn't", not open-ended taste). Don't spend a 25-min deploy to *discover* a design; spend it to *confirm* one.

---

## Open must-fix list (this revision)

1. **T1** — replace ~17 `.system(size:)` sites with `DeejAIFonts` tokens (restores custom faces + Dynamic Type).
2. **U1** — add UIKit appearance proxies (both standard + scrollEdge), token-driven.
3. **Infinity** — rewire from `repeatMode` to sequencer queue-extend.
4. **Up next** — wire sequencer OR soften label to match the queue source.
5. Reconcile radii (art 16→20) and off-scale spacing (6/14/48) to the named steps.

---

# 7. Library architecture (decided)

The Library consolidates Amperfy's ~10-row server-browser taxonomy into **three browse types + a filter/sort layer** (the thing Amperfy lacks). Reference: Plexamp's library.

**Structure:**
- **Segmented control: Artists / Albums / Songs** — the only three top-level browse types. Replaces the separate Artists/Albums/Newest/Recently-Played/Songs/Favorite-Songs rows.
- **Persistent control bar** under the segment switch: search field (scoped to current segment) + sort menu.
- **Sort menu** (the core gap being filled): name (A-Z), date added, recently played, **play count (asc AND desc)**, random. Play-count-descending surfaces most-loved; play-count-ascending surfaces the neglected — this is the "never a forgotten archive" thesis as a concrete browse affordance, not just an algorithm.
- **Filter chips:** All / Favorites / Recently played — apply across whichever segment is active (so "favorite albums," "recently played artists" are all reachable, unlike Amperfy's single hardcoded combos).
- **A-Z scrubber** on the right edge (Plexamp-style fast-jump) when sorted by name.

**Removed / relocated:**
- **Podcasts: removed by HIDING, not excision.** Cut the entry points (Library row, nav). Leave upstream podcast code paths dormant — ripping them out destabilizes the player and conflicts every upstream merge. Removal-by-hiding.
- **Directories, "Newest Albums" as a row:** dropped/buried. "Newest" is just a sort option; Directories is a raw-filesystem view that fights the curated-library feel.
- **Playlists: relocated to Home** (see §8).

**Implementation notes:**
- Build against the Subsonic API (Navidrome exposes play counts + starred state). But: sort-by-play-count is only as honest as the play data — fully meaningful only after the Plexamp backfill + feedback loop land. The screen can be built now; the data behind the sort matures later.
- Songs (flat list of a large library) needs a **virtualized list** for performance.
- Font: route `LibraryNavigatorConfigurator` labels through the DeejAIFonts UIFont bridge (closes the open T2 lint item).

# 8. Home playlist shelf (decided)

Playlists migrate from Library to Home, but as a **secondary shelf**, not crowding the hero.
- Home's split becomes: chosen *for* you (next-listen hero, mixes) above; chosen *by* you (playlists) below — a horizontal card row beneath the hero/mixes.
- **Playlist *authoring* must not be orphaned.** Accessing playlists (the shelf) and creating/editing/reordering them are different needs. The shelf solves access; create/edit flows (currently reachable via the removed Library row) need an explicit home — a "+" on the shelf and edit affordances on the playlist detail. Do not lose these in the migration.

# 9. Settings architecture (rules, not an inventory)

Principle: **simple top level, granular underneath.** This is progressive disclosure. It is too early to enumerate every setting; these are the placement RULES so every future setting has an obvious home and the top level never drifts into a flat wall of toggles.

**Two-tier rule:**
- **Top level** shows only: (a) the handful of settings touched with real frequency, (b) category doors, (c) app info (version/build).
- **Everything granular** lives one tap down inside a category.

**Promotion test (what earns top level):** frequency, NOT importance. The test is "how often does Aaron touch this, and how much regret if buried one tap deeper" — not "is this important" (everything in settings is important to someone). Significance and frequency are different axes; sort top-level real estate by frequency.

**Categories map to user INTENT, not system architecture.** Current Amperfy groupings are engineering-shaped (mirror code layout). Prefer intent-based: Playback, Library & Sync, Appearance, Account, + a walled Advanced/Developer. (A `DeveloperView` already exists — use it as the wall.)

**Model-knob containment (critical — ties to the "don't expose the knobs" rule):** Settings is where the temptation to surface epsilon / lookback / "drunk" / cosine thresholds is strongest, because "granular control" feels like "every knob available." The line:
- Granular control over *experienced behavior* (continuation on/off, resurfacing aggressiveness in human terms, context sensitivity) → YES, in Playback settings, in human language.
- Raw *model parameters* → walled in Advanced/Developer behind a clear "advanced — changes how recommendations are computed" framing, never in the top two tiers. The main UI still exposes at most the one "feel" control (§4); settings must not become the ML panel the app is designed to avoid.

**Current skeleton (basis to evolve from, not a redesign):** top level = Version/Build (info), Offline Mode + Prevent Screen Lock (genuine top-level toggles), then doors: Account, Display & Interaction, Library, Player Stream & Scrobble, Equalizer, Swipe, Artwork, Support, License, X-Callback, Developer. Evolution direction: regroup the doors toward intent-based categories; verify the two promoted toggles are genuinely Aaron's highest-frequency items; ensure DeejAI playback-intelligence settings get a clear home (Playback) and any true model knobs go to Developer.
