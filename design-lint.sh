#!/usr/bin/env bash
# design-lint.sh — structural-invariant checks for DeejAI.
# Runs first in the Xcode Cloud workflow (ci_post_clone or a pre-build step).
# Catches font/literal/material/honesty/placeholder/chrome drift WITHOUT a render.
# Exit non-zero on any violation so the build goes red before it's worth compiling.
#
# NOTE: a grep over a missing path matches nothing and reports green — a silently
# disabled check is worse than none. The guard below fails loudly if a search root
# has moved, so a future rename can't quietly turn enforcement off.

set -uo pipefail
SWIFT_DEEJAI="SwiftUI/DeejAINowPlaying SwiftUI/DeejAIHome SwiftUI/DeejAIForYou SwiftUI/DeejAICoverArt"
SWIFT_SETTINGS="SwiftUI/Settings SwiftUI/Basics"
UIKIT="Screens"
fail=0

note() { echo "❌ $1"; fail=1; }
ok()   { echo "✅ $1"; }

# --- Guard: every search root must exist, or the checks below false-clean ---
for d in $SWIFT_DEEJAI $SWIFT_SETTINGS $UIKIT; do
  if [ ! -d "$d" ]; then note "GUARD: search root '$d' not found — path moved? checks over it would false-clean"; fi
done
[ "$fail" -ne 0 ] && { echo "design-lint ABORTED (bad search roots)"; exit 1; }

# C1 — no color literals in DeejAI views (tokens only)
if grep -rn --include=*.swift -E 'Color\(red:|UIColor\(red:|#[0-9A-Fa-f]{6}' $SWIFT_DEEJAI \
     | grep -v 'DeejAIColors.swift' | grep -v '//' ; then
  note "C1: color literal in a view — route through DeejAIColors"
else ok "C1: no color literals in views"; fi

# T1 — no bare .system(size:) in DeejAI views (except DeejAIFonts monoTime)
if grep -rn --include=*.swift '\.system(size:' $SWIFT_DEEJAI \
     | grep -v 'DeejAIFonts.swift' | grep -v '//' ; then
  note "T1: .system(size:) in a view — use DeejAIFonts tokens (kills Dynamic Type + custom face)"
else ok "T1: font tokens used in DeejAI views"; fi

# T2 (SCOPED) — only the redesigned-identity UIKit surfaces must use DeejAIFonts; utility/
# dense text (lyrics, login, etc.) may stay system. Add `// design-lint:allow-system-font`
# on a line to intentionally opt it out. Edit T2_SCOPE to expand the enforced surface set.
T2_SCOPE="Screens/ViewController/LibraryNavigatorConfigurator.swift Screens/Player/MiniPlayerView.swift"
for f in $T2_SCOPE; do [ -e "$f" ] || note "T2: scoped file '$f' missing — path moved?"; done
if grep -rn --include=*.swift -E '\.preferredFont\(forTextStyle:|\.systemFont\(ofSize:' $T2_SCOPE 2>/dev/null \
     | grep -v 'DeejAIFonts' | grep -v 'design-lint:allow-system-font' | grep -v '//' ; then
  note "T2: system UIFont on a redesigned surface — route through DeejAIFonts UIFont bridge"
else ok "T2: redesigned UIKit surfaces use DeejAIFonts (utility text exempt)"; fi

# MATERIAL — no Liquid Glass / blur materials on redesigned surfaces (.blur allowed).
# Covers BOTH mini-player presentation paths (TabBarVC + SplitVC) — image showed the pill
# rendering translucent over collection views, so a per-context regression must be catchable.
MATERIAL_SURFACES="Screens/Player/MiniPlayerView.swift Screens/ViewController/TabBarVC.swift Screens/ViewController/SplitVC.swift $SWIFT_DEEJAI"
if grep -rn --include=*.swift -E 'UIGlassEffect|UIVisualEffectView|setBackgroundBlur|\.(ultraThin|thin|regular|thick)Material' \
     $MATERIAL_SURFACES | grep -v '//' ; then
  note "MATERIAL: glass/blur material on a redesigned surface — use solid surfaceElevated + warm shadow"
else ok "MATERIAL: no glass on redesigned surfaces (both mini-player paths checked)"; fi
# MATERIAL-2 — 'glassContainer' is now a solid UIView, but if anyone re-assigns an effect to it
# the name will hide the regression. Flag any effect assignment onto the mini-player container.
if grep -rn --include=*.swift -E 'glassContainer\.effect|\.effect[[:space:]]*=[[:space:]]*UIGlass' Screens | grep -v '//' ; then
  note "MATERIAL-2: an effect is being assigned to the mini-player container — it must stay a solid UIView"
else ok "MATERIAL-2: mini-player container stays solid (no effect re-assigned)"; fi

# U1 — appearance proxies must exist and set BOTH standard + scrollEdge
if ! grep -rqn 'scrollEdgeAppearance' $UIKIT ; then
  note "U1: no scrollEdgeAppearance — nav/tab bars snap to stock chrome"
else ok "U1: scrollEdgeAppearance present"; fi
if ! grep -rqn 'UISwitch.appearance' $UIKIT ; then
  note "U1: UISwitch tint not set — UIKit switches render stock"
else ok "U1: UIKit switch tint set"; fi

# U2 (NEW) — SwiftUI settings chrome. UISwitch.appearance() does NOT touch SwiftUI Toggle,
# and List stays system-grouped unless scrollContentBackground is hidden.
if ! grep -rqn 'scrollContentBackground(.hidden)' $SWIFT_SETTINGS ; then
  note "U2: no scrollContentBackground(.hidden) in Settings — List stays stock grouped chrome"
else ok "U2: settings list background overridden"; fi
if grep -rqn --include=*.swift 'Toggle' $SWIFT_SETTINGS ; then
  if ! grep -rqn --include=*.swift -E '\.tint\(|toggleStyle' $SWIFT_SETTINGS ; then
    note "U2: SwiftUI Toggle present but no .tint/.toggleStyle — switches render stock, not terracotta"
  else ok "U2: settings toggles tinted"; fi
else ok "U2: no untinted settings toggles"; fi

# FLOWSON — label must not promise sequencing until Phase 3
if grep -rn --include=*.swift 'flows on' $SWIFT_DEEJAI | grep -v '//' ; then
  note "FLOWSON: 'flows on' present — sequencer is Phase 3; use plain UP NEXT until real"
else ok "FLOWSON: no premature sequencing label"; fi

# PLACEHOLDER (BLOCK-AWARE) — flag stat literals / 'Daily Mix' ONLY when NOT inside a
# #if DEBUG ... #endif block. A line-level "grep -v DEBUG" can't see block scope and
# false-fails correctly-gated demo data, so track scope with awk instead.
placeholder_hits=$(
  for f in $(grep -rl --include=*.swift -E 'plays:[[:space:]]*[0-9]+|Daily Mix' $SWIFT_DEEJAI 2>/dev/null); do
    awk -v file="$f" '
      /#if[[:space:]]+DEBUG/ { depth++; next }
      /#endif/              { if (depth>0) depth--; next }
      /\/\//              { next }                 # skip comment lines
      (/plays:[[:space:]]*[0-9]+/ || /Daily Mix/) && depth==0 { print file ":" FNR ": " $0 }
    ' "$f"
  done
)
if [ -n "$placeholder_hits" ]; then
  echo "$placeholder_hits"
  note "PLACEHOLDER: hardcoded stat literal (plays: N) or 'Daily Mix' OUTSIDE #if DEBUG — wire real data or gate it"
else ok "PLACEHOLDER: no ungated hardcoded stats"; fi

echo "---"
if [ "$fail" -ne 0 ]; then echo "design-lint FAILED"; exit 1; else echo "design-lint passed"; fi
