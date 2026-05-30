# DeejAI — Design + Architecture Spec

> Frozen visual + behavioral contract. **Agents: implement against this file.** Do not re-derive these choices each session. Judgment happens here once; translation happens downstream forever.

---

## 1. Identity (Non-Negotiable)

- Primary verb: **radio** ("keep playing like this"), not browsing
- Zero friction: one confident pre-decided pick on open, no grid of choices
- Resurfacing ≠ preference: exploitation (what fits now) vs exploration (loved-but-unplayed) are separate jobs
- Hot path: **no LLM** — playback decisions must be instant and deterministic
- Pipeline: selector (context + completion → pool) → sequencer (sonic similarity → order)
- Similarity: precompute-once embedding + cheap nearest-neighbor at play time

---

## 2. Color Tokens (Invariant)

| Token | Light | Dark | Role |
|-------|-------|------|------|
| `accentPrimary` | `#D1733D` | warm-bright terracotta | love, play/pause, active progress, primary actions |
| `accentPrimaryDark` | `#B35C2D` | — | pressed/hover states |
| `accentSecondary` | `#266B66` | slightly brighter teal | infinity pill, feel pill, secondary CTA |
| `accentSecondaryMuted` | `#4D8C84` | — | secondary surface fills, tags, subtle borders |
| `accentTertiary` | `#D4A843` | — | gradients, decorative fills, warm highlights |
| `accentTertiaryDark` | `#B08A2E` | — | deeper warm highlight |
| `accentQuaternary` | `#F5C99C` | — | very light warm highlights |
| `surface` | `#F5EFE2` | `#291F14` | main background |
| `surfaceElevated` | `#EDE6D7` | `#322418` | cards, elevated containers |
| `surfaceSunken` | `#E2DACB` | `#1D1409` | insets, inputs, wells |
| `textPrimary` | `#38291E` | `#F5EFE2` | headings, primary content |
| `textSecondary` | `#665240` | `#C4B8A8` | body text |
| `textTertiary` | `#9E8A70` | `#A09480` | labels, meta, timestamps |
| `textQuaternary` | `#B8A992` | `#8A7E70` | placeholders, disabled |
| `success` | `#4CAF82` | — | completion indicator |
| `error` | `#E05C5C` | — | destructive actions |
| `divider` | 10% `textPrimary` | — | list separators |

**Hard rules:**
- No `#hex` or RGB values in view files — always use tokens
- No `Color`/`UIColor` constructors with literal components in views
- Dark mode uses warm dark backgrounds (`#291F14`), not cold black

---

## 3. Type Tokens (Invariant)

| Token | Font | Style | Example |
|-------|------|-------|---------|
| `serifDisplay` | Lora Bold | 32pt / `.largeTitle` | Hero pick title |
| `serifTitle` | Lora Bold | 24pt / `.title3` | Now-playing track title |
| `serifHeadline` | Lora SemiBold | 15pt / `.headline` | Track titles in lists |
| `serifSubheadline` | Lora SemiBold | 13pt / `.subheadline` | Album/artist on art |
| `sansBody` | Nunito Medium | 16pt / `.body` | Primary body text |
| `sansSubheadline` | Nunito Medium | 13pt / `.body` | Artist names, secondary body |
| `sansLabel` | Nunito Medium | 13pt / `.callout` | Metadata, labels |
| `sansCaption` | Nunito Medium | 11pt / `.caption` | Timestamps, section headers |
| `sansCaptionBold` | Nunito Bold | 11pt / `.caption` | Badges, emphasis in captions |
| `monoTime` | SF Mono | 11pt | Playback timestamps only |

**Hard rules:**
- All custom fonts use `Font.custom(_:size:relativeTo:)` — Dynamic Type alive
- Never `.system(size:)` for text — that disables accessibility scaling
- SF Symbols stay system (they're icons, not text)

---

## 4. Shape (Invariant)

| Element | Radius |
|---------|--------|
| Album art | 20 |
| Mini art / thumbnails | 8 |
| Full-width cards | 14 |
| Pill / capsule | 999 |

Only three radii in active use: **20, 14, 8**. Capsule is 999.

---

## 5. Spacing (Invariant)

Use these steps only: **0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 56**

**Hard rules:**
- No magic numbers — all spacing from the named steps
- List row height: 56pt fixed
- Section spacing: 20pt
- Card internal padding: 16pt
- Hero content internal padding: 20pt

---

## 6. Shadow (Single Recipe)

```swift
.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
```

One shadow everywhere. No other values. No colored shadows except album tint on NowPlaying.

---

## 7. Motion (Spring Only)

```swift
.spring(response: 0.4, dampingFraction: 0.8)
```

One spring everywhere for user-facing transitions. No `easeInOut`. No linear. No other spring values.

---

## 8. Per-Control Semantics

### NowPlaying screen

**Love (heart):**
- ✅ Reads initial `isFavorite` from model
- ✅ On tap: writes favorite to model
- ✅ On tap: spring-scale 1.0 → 1.15
- ✅ On favorite: animate fill with `interpolateSpring(mass: 1, stiffness: 300, damping: 15)`
- ✅ Haptics: `.impact(flexibility: .soft, intensity: 0.45)`

**Infinity (queue-extend):**
- ❌ Currently wired to `repeatMode == .all` — should be sequencer queue-extend
- Should toggle auto-extend of the queue by the sequencer
- Active state: `accentSecondary` fill, `surface` foreground, subtle glow
- Inactive state: `accentSecondary` 12% fill

**Up-next:**
- ❌ Source is plain Amperfy queue — should be sequencer's pick (or label softened)
- Card layout: mini art thumbnail | track info | chevron
- On tap: play next track in sequence

**Playback controls:**
- Previous / play-pause / next
- Play-pause is hero control: 64pt circle, `accentPrimary` fill
- Previous/next are secondary: `textSecondary`, subtle hit area
- On tap: spring scale 1.0 → 0.95

**Progress bar:**
- Track: `accentPrimary` 12% opacity
- Fill: `accentPrimary`
- Playhead: no visible dot, just the fill edge
- Elapsed/remaining: `monoTime` text

### Home screen

**Hero pick:**
- 280pt album art, corner radius 20, warm shadow
- "Play Radio" capsule button below
- Context header: "evening, friday" etc.

**Alternative picks:**
- 3 smaller cards (130pt art), spring-delayed fade-in

### For You screen

**Mix cards:**
- Horizontal scroll, 180pt wide
- Gradient fills from `accentSecondary`/`accentPrimary`

---

## 9. UIKit Chrome (Invariant)

These MUST use the same DeejAIColors tokens:

- `UINavigationBar.standardAppearance` AND `.scrollEdgeAppearance`
- `UITabBar.standardAppearance` AND `.scrollEdgeAppearance`
- `UIView.appearance().tintColor`
- `UISwitch.appearance().onTintColor`
- `UITableView.appearance()` selection color

No system blue leaking through. No unstyled nav bars. No frosted glass.

---

## 10. CI / Agent Guardrails

### Color literal grep-lint

```bash
! grep -rn 'Color(red:\|UIColor(red:\|#\([0-9a-fA-F]\{6\}\|8\})' \
  Amperfy/SwiftUI/DeejAINowPlaying/ Amperfy/SwiftUI/DeejAIHome/ \
  Amperfy/SwiftUI/DeejAIForYou/ Amperfy/SwiftUI/DeejAICoverArt/ \
  | grep -v 'DeejAIColors\.swift'
```

### Font literal grep-lint

```bash
! grep -rn '\.system(size:' \
  Amperfy/SwiftUI/DeejAINowPlaying/ Amperfy/SwiftUI/DeejAIHome/ \
  Amperfy/SwiftUI/DeejAIForYou/ Amperfy/SwiftUI/DeejAICoverArt/ \
  | grep -v 'DeejAIFonts\.swift'
```

### Snapshot golden tests (future)

SwiftUI preview snapshots stored as PNGs. CI compares new renders against goldens. Any pixel diff = fail.

---

## 11. Architecture

### Library screen

- Segmented control with tabs: **Artists**, **Albums**, **Songs**
- Default tab: **Artists**
- Each tab has contextual sort and filter options
- Playlists are hidden from Library — they live on Home

### Settings

- Two tiers: top-level intent categories → drill-down detail pages
- Example: "Playback & Audio" → Music Services, Sleep Timer, Audio Quality, etc.
- No monolithic settings dump

### Playback

- Persistent "Now Playing" bar at bottom of all screens
- Tap to expand to full-screen Now Playing
- Expand/collapse transitions use spring animation

---

## 12. Open Bugs

| Bug | Status | Notes |
|-----|--------|-------|
| **Infinity reads repeatMode, not sequencer** | Open | Need sequencer queue-extend API |
| **Up-next reads plain queue** | Open | Label softened to "UP NEXT" for now |
| **No "Now Playing" persistent bar** | Open | Need bottom bar across all tabs |
