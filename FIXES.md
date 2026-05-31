# FIXES.md — build 32 on-device review

Scoped, file-and-line-precise fixes from reviewing build 32 on device. Each item: location, what's wrong, the fix, and an acceptance check. Implement against `design-spec.md` — do not invent values. When done, run the grep-lint (see design-spec §6) and report which checks pass.

Priority order is deliberate: 1–3 are the most visible / thesis-contradicting, 4–6 are correctness, 7 is provenance (needs human confirmation).

---

## 1. De-glass the mini-player — CRITICAL, contradicts core thesis

**File:** `Screens/Player/MiniPlayerView.swift:884`
**What's wrong:** `glassContainer` is a `UIVisualEffectView` with `UIGlassEffect(style: .regular)` — literal iOS 26 Liquid Glass. This is the frosted pill visible on every screen; it's the single most corrosive leak because it's persistent and it's exactly the material the project rejects.
**Fix:** Replace the `UIVisualEffectView`/`UIGlassEffect` with a solid container: background `DeejAIColors.surfaceElevated`, corner radius `radiusMd` (14), the one approved warm shadow (black 12% warm-shifted, y4, blur12). Keep the same Auto Layout constraints. Drop `glassEffect` entirely.
**Accept:** no `UIGlassEffect` / `UIVisualEffectView` in MiniPlayerView; mini-player renders as a solid warm pill; grep-lint MATERIAL check passes for this file.

## 2. De-glass the tab bar + add appearance proxies — closes design-spec §U1

**File:** `Screens/ViewController/TabBarVC.swift` (currently sets only `tabBarMinimizeBehavior` at :139 — no appearance config at all)
**What's wrong:** Zero appearance-proxy setup anywhere in the project (confirmed: grep for `*Appearance` returns nothing). Tab bar + nav bars + the settings grouped-table + switches all inherit stock iOS chrome — this is the white-cards / default-switch-tint leak visible on the Settings screen.
**Fix:** Add a single token-driven appearance setup (new `DeejAIAppearance.swift`, called at app launch), covering:
- `UITabBarAppearance`: set BOTH `standardAppearance` AND `scrollEdgeAppearance`; background `surface`, selected item `accentPrimary`. Configure with `configureWithOpaqueBackground()` (no translucency).
- `UINavigationBarAppearance`: BOTH `standardAppearance` AND `scrollEdgeAppearance` (missing scrollEdge = bar snaps to default on scroll-to-top); background `surface`, title text `textPrimary`.
- `UISwitch.appearance().onTintColor = DeejAIColors.accentPrimary`
- `UISlider` min-track + window/global `tintColor = accentPrimary`.
**Accept:** both appearance objects set standard + scrollEdge; Settings switch is terracotta when on; tab bar is opaque warm; grep-lint U1 check passes.

## 3. "flows on" — make label match data source (design-spec §4 honesty)

**File:** `SwiftUI/DeejAIHome/DeejAIHomeView.swift:280` — hardcoded `Text("· flows on")`
**What's wrong:** It's a literal string, not conditional on whether the next track is actually sequencer-selected. Per the project plan, sonic sequencing is Phase 3 (gated on Essentia extraction, not built). So the label promises a capability that doesn't exist, and appears even on plain-queue next tracks. Now-playing (`DeejAINowPlayingView`) already correctly shows plain "UP NEXT" — make Home match.
**Fix:** Remove the `· flows on` suffix everywhere until the sequencer is real. Plain "UP NEXT". (Re-add later, conditionally, only when the next track genuinely comes from sequencer output.)
**Accept:** no "flows on" string in any DeejAI view; grep-lint FLOWSON check passes.

## 4. Infinity control — rewire from repeatMode to sequencer extend (design-spec §4, still open)

**File:** `SwiftUI/DeejAINowPlaying/DeejAIPlayerState.swift` `toggleRadioMode()` (~:106)
**What's wrong:** Wired to `RepeatMode.all` — that's repeat, not radio. The vision's infinity = extend the queue with sequencer-selected similar tracks ("keep playing like this"). Repeat replays the existing queue; it does not generate continuation.
**Fix:** Rewire to the radio/sequencer queue-extend path. NOTE: this depends on the backend's real continuation API — confirm the endpoint/behavior with Aaron before implementing; do not substitute another existing primitive to make it compile.
**Accept:** infinity triggers queue extension, not repeat; `repeatMode` no longer touched by this control.

## 5. Finish T1 — replace `.system(size:)` with font tokens (design-spec §2)

**Files:** ~17 sites across `DeejAINowPlayingView`, `DeejAIHomeView`, `DeejAIForYouView`, `DeejAICoverArtView` (see prior grep; e.g. NowPlaying :190/:229/:242/:251/:288/:305).
**What's wrong:** bare `.system(size:)` renders in San Francisco (not Lora/Nunito) AND disables Dynamic Type — the exact regression `DeejAIFonts` exists to prevent.
**Fix:** replace each with the matching `DeejAIFonts.` token. Only legitimate exception: the `monoTime` token itself.
**Accept:** no `.system(size:` under `SwiftUI/DeejAI*` except in `DeejAIFonts.swift`; grep-lint T1 check passes.

## 6. Reconcile off-scale radii + spacing (design-spec §3)

**What's wrong:** album art radius is 16 (spec target 20); ad-hoc spacings 6 / 14 / 48 exist (spec scale: 4/8/12/16/20/24/28/32/40).
**Fix:** art → `radiusLg` (20); snap stray spacings to nearest scale step. Define `radiusLg/Md/Sm` constants if not present.
**Accept:** only 8/14/20 radii in use; no spacing values off the named scale.

## 7. Home placeholder data — label or wire (design-spec §4 provenance) — NEEDS AARON

**File:** `SwiftUI/DeejAIForYou/DeejAIForYouView.swift:18-31` — hardcoded `@State`: "Daily Mix 1/2/3" and TopArtistCard plays (142/118/97…).
**What's wrong:** Hardcoded placeholders that look identical to real data on a device build — they will ship by accident. Separately, "Daily Mix" is Spotify's vocabulary on the screen whose job is to feel like *your* system.
**Fix:** (a) Until wired to real own-library data, mark placeholder content unmistakably (or gate behind a debug flag) so it can't be mistaken for real. (b) Rename "Daily Mix N" to project-native vocabulary. (c) When wiring real plays: per provenance rule, do NOT surface Spotify-history counts as owned-library listening — only local/Plexamp-resolved plays count as "your" plays.
**Accept:** no unlabeled hardcoded stats render in a release build; "Daily Mix" renamed.

---

## Also confirmed clean (do not regress)
- Color tokens: no hex/`Color(red:)` literals in views (C1 passing).
- Love heart: reads + persists `isFavorite` (design-spec §4 — done).
- Cover-art placeholder system (gradient + serif title) handles missing artwork well.
- The two intentional `.blur(radius:)` calls (NowPlaying :136 art shadow, Home :173) are warm-shadow decoration, NOT glass materials — leave them. (MATERIAL grep-lint targets `UIGlassEffect`/`UIVisualEffectView`/`setBackgroundBlur`/SwiftUI `Material`, not `.blur`.)

## Out of scope here (upstream Amperfy, decide separately)
`UIGlassEffect` in `LoginVC.swift:341/563` and `setBackgroundBlur(.prominent)` in QueueVC/PlainDetailsVC/EntityPreviewVC/NotificationDetailVC/PopupPlayerVC are inherited Amperfy screens not yet redesigned. Flag for a later pass; not part of the build-32 surfaces under review.
