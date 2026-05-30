#!/usr/bin/env bash
# design-lint.sh — structural-invariant checks for DeejAI.
set -uo pipefail
SWIFT_DEEJAI="Amperfy/SwiftUI/DeejAINowPlaying Amperfy/SwiftUI/DeejAIHome Amperfy/SwiftUI/DeejAIForYou Amperfy/SwiftUI/DeejAICoverArt"
fail=0

note() { echo "FAIL: $1"; fail=1; }
ok()   { echo "  OK: $1"; }

# C1
if grep -rn --include=*.swift -E 'Color\(red:|UIColor\(red:|#[0-9A-Fa-f]{6}' $SWIFT_DEEJAI \
     | grep -v 'DeejAIColors.swift' | grep -v '//' ; then
  note "C1: color literal in a view"
else ok "C1: no color literals in views"; fi

# T1
if grep -rn --include=*.swift '\.system(size:' $SWIFT_DEEJAI \
     | grep -v 'DeejAIFonts.swift' | grep -v '//' ; then
  note "T1: .system(size:) in a view"
else ok "T1: font tokens used everywhere"; fi

# MATERIAL
if grep -rn --include=*.swift -E 'UIGlassEffect|UIVisualEffectView|setBackgroundBlur|\.(ultraThin|thin|regular|thick)Material' \
     Amperfy/Screens/Player/MiniPlayerView.swift Amperfy/Screens/ViewController/TabBarVC.swift $SWIFT_DEEJAI \
     | grep -v '//' ; then
  note "MATERIAL: glass/blur material on a redesigned surface"
else ok "MATERIAL: no glass on redesigned surfaces"; fi

# U1
if ! grep -rqn 'scrollEdgeAppearance' Amperfy/Screens ; then
  note "U1: no scrollEdgeAppearance set"
else ok "U1: scrollEdgeAppearance present"; fi
if ! grep -rqn 'UISwitch.appearance' Amperfy/Screens Amperfy/AppDelegate.swift; then
  note "U1: UISwitch tint not set"
else ok "U1: switch tint set"; fi

# FLOWSON
if grep -rn --include=*.swift 'flows on' $SWIFT_DEEJAI | grep -v '//' ; then
  note "FLOWSON: 'flows on' present — sequencer is Phase 3"
else ok "FLOWSON: no premature sequencing label"; fi

# PLACEHOLDER
if grep -rn --include=*.swift 'Daily Mix' $SWIFT_DEEJAI | grep -v '//' ; then
  note "PLACEHOLDER: 'Daily Mix' literal present"
else ok "PLACEHOLDER: no Daily Mix literal"; fi

echo "---"
if [ "$fail" -ne 0 ]; then echo "design-lint FAILED"; exit 1; else echo "design-lint passed"; fi
