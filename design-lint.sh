#!/usr/bin/env bash
# design-lint.sh ƒ?" structural-invariant checks for DeejAI.
# Runs first in the Xcode Cloud workflow (ci_post_clone or a pre-build step).
# Catches the font/literal/material/honesty/placeholder drift classes WITHOUT a render.
# Exit non-zero on any violation so the build goes red before it's worth compiling.

set -uo pipefail
SWIFT_DEEJAI="SwiftUI/DeejAINowPlaying SwiftUI/DeejAIHome SwiftUI/DeejAIForYou SwiftUI/DeejAICoverArt"          # SwiftUI views under review
fail=0

note() { echo "ƒ?O $1"; fail=1; }
ok()   { echo "ƒo. $1"; }

# C1 ƒ?" no color literals in views (tokens only)
if grep -rn --include=*.swift -E 'Color\(red:|UIColor\(red:|#[0-9A-Fa-f]{6}' $SWIFT_DEEJAI \
     | grep -v 'DeejAIColors.swift' | grep -v '//' ; then
  note "C1: color literal in a view ƒ?" route through DeejAIColors"
else ok "C1: no color literals in views"; fi

# T1 ƒ?" no bare .system(size:) except the DeejAIFonts monoTime token
if grep -rn --include=*.swift '\.system(size:' $SWIFT_DEEJAI \
     | grep -v 'DeejAIFonts.swift' | grep -v '//' ; then
  note "T1: .system(size:) in a view ƒ?" use DeejAIFonts tokens (kills Dynamic Type + custom face)"
else ok "T1: font tokens used everywhere"; fi

# MATERIAL ƒ?" no Liquid Glass / blur materials in redesigned surfaces
# (.blur(radius:) is allowed ƒ?" it's warm-shadow decoration, not a glass material)
if grep -rn --include=*.swift -E 'UIGlassEffect|UIVisualEffectView|setBackgroundBlur|\.(ultraThin|thin|regular|thick)Material' \
     Screens/Player/MiniPlayerView.swift Screens/ViewController/TabBarVC.swift $SWIFT_DEEJAI \
     | grep -v '//' ; then
  note "MATERIAL: glass/blur material on a redesigned surface ƒ?" use solid surfaceElevated + warm shadow"
else ok "MATERIAL: no glass on redesigned surfaces"; fi

# U1 ƒ?" appearance proxies must exist and set BOTH standard + scrollEdge
if ! grep -rqn 'scrollEdgeAppearance' Screens ; then
  note "U1: no scrollEdgeAppearance set ƒ?" nav/tab bars will snap to stock chrome"
else ok "U1: scrollEdgeAppearance present"; fi
if ! grep -rqn 'UISwitch.appearance' Screens ; then
  note "U1: UISwitch tint not set from tokens ƒ?" switches render stock green/blue"
else ok "U1: switch tint set"; fi

# FLOWSON ƒ?" label must not promise sequencing until Phase 3
if grep -rn --include=*.swift 'flows on' $SWIFT_DEEJAI | grep -v '//' ; then
  note "FLOWSON: 'flows on' present ƒ?" sequencer is Phase 3; use plain UP NEXT until real"
else ok "FLOWSON: no premature sequencing label"; fi

# PLACEHOLDER ƒ?" guard against hardcoded demo data shipping as real
if grep -rn --include=*.swift 'Daily Mix' $SWIFT_DEEJAI | grep -v '//' ; then
  note "PLACEHOLDER: 'Daily Mix' literal present ƒ?" rename to native vocabulary + wire real data"
else ok "PLACEHOLDER: no Daily Mix literal"; fi

echo "---"
if [ "$fail" -ne 0 ]; then echo "design-lint FAILED"; exit 1; else echo "design-lint passed"; fi

