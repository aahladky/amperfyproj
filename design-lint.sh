#!/usr/bin/env bash
# design-lint.sh — structural-invariant checks for DeejAI.
set -uo pipefail
SWIFT_DEEJAI="Amperfy/SwiftUI/DeejAINowPlaying Amperfy/SwiftUI/DeejAIHome Amperfy/SwiftUI/DeejAIForYou Amperfy/SwiftUI/DeejAICoverArt"
SWIFT_SETTINGS="Amperfy/SwiftUI/Settings Amperfy/SwiftUI/Basics"
UIKIT="Amperfy/Screens"
REDESIGNED_UIKIT="Amperfy/Screens/Player/MiniPlayerView.swift"
fail=0

note() { echo "FAIL: $1"; fail=1; }
ok()   { echo "  OK: $1"; }

for d in $SWIFT_DEEJAI $SWIFT_SETTINGS $UIKIT; do
  if [ ! -d "$d" ]; then note "GUARD: search root '$d' not found"; fi
done
[ "$fail" -ne 0 ] && { echo "design-lint ABORTED (bad search roots)"; exit 1; }

# C1
if grep -rn --include=*.swift -E 'Color\(red:|UIColor\(red:|#[0-9A-Fa-f]{6}' $SWIFT_DEEJAI \
     | grep -v 'DeejAIColors.swift' | grep -v '//' ; then
  note "C1: color literal in a view"
else ok "C1: no color literals in views"; fi

# T1
if grep -rn --include=*.swift '\.system(size:' $SWIFT_DEEJAI \
     | grep -v 'DeejAIFonts.swift' | grep -v '//' ; then
  note "T1: .system(size:) in a view"
else ok "T1: font tokens used in DeejAI views"; fi

# T2 — only check redesigned UIKit screens (MiniPlayerView)
if grep -rn --include=*.swift -E '\.preferredFont\(forTextStyle:|\.systemFont\(ofSize:' $REDESIGNED_UIKIT \
     | grep -v 'DeejAIFonts' | grep -v '//' ; then
  note "T2: system UIFont in MiniPlayerView"
else ok "T2: no raw system UIFont in MiniPlayerView"; fi

# MATERIAL
if grep -rn --include=*.swift -E 'UIGlassEffect|UIVisualEffectView|setBackgroundBlur|\.(ultraThin|thin|regular|thick)Material' \
     Amperfy/Screens/Player/MiniPlayerView.swift Amperfy/Screens/ViewController/TabBarVC.swift $SWIFT_DEEJAI \
     | grep -v '//' ; then
  note "MATERIAL: glass/blur material on a redesigned surface"
else ok "MATERIAL: no glass on redesigned surfaces"; fi

# U1
if ! grep -rqn 'scrollEdgeAppearance' $UIKIT ; then
  note "U1: no scrollEdgeAppearance"
else ok "U1: scrollEdgeAppearance present"; fi
if ! grep -rqn 'UISwitch.appearance' $UIKIT ; then
  note "U1: UISwitch tint not set"
else ok "U1: UIKit switch tint set"; fi

# U2
if ! grep -rqn 'scrollContentBackground(.hidden)' $SWIFT_SETTINGS ; then
  note "U2: no scrollContentBackground(.hidden) in Settings"
else ok "U2: settings list background overridden"; fi
if grep -rqn --include=*.swift 'Toggle' $SWIFT_SETTINGS ; then
  if ! grep -rqn --include=*.swift -E '\.tint\(|toggleStyle' $SWIFT_SETTINGS ; then
    note "U2: SwiftUI Toggle present but no .tint/.toggleStyle"
  else ok "U2: settings toggles tinted"; fi
else ok "U2: no untinted settings toggles"; fi

# FLOWSON
if grep -rn --include=*.swift 'flows on' $SWIFT_DEEJAI | grep -v '//' ; then
  note "FLOWSON: 'flows on' present"
else ok "FLOWSON: no premature sequencing label"; fi

# PLACEHOLDER — skip lines inside #if DEBUG blocks
PLACEHOLDER_HITS=$(python3 -c "
import re, os, sys
hits = []
for d in '''$SWIFT_DEEJAI'''.split():
    for root, dirs, files in os.walk(d):
        for f in files:
            if not f.endswith('.swift'): continue
            path = os.path.join(root, f)
            with open(path) as fh:
                in_debug = False
                for i, line in enumerate(fh, 1):
                    if '#if DEBUG' in line: in_debug = True
                    elif '#endif' in line and in_debug: in_debug = False
                    elif not in_debug and not line.strip().startswith('//'):
                        if re.search(r'plays:\s*[0-9]+|Daily Mix', line):
                            hits.append(f'{path}:{i}:{line.rstrip()}')
for h in hits: print(h)
" 2>/dev/null)
if [ -n "$PLACEHOLDER_HITS" ]; then
  echo "$PLACEHOLDER_HITS"
  note "PLACEHOLDER: hardcoded stat literal outside #if DEBUG"
else ok "PLACEHOLDER: no hardcoded stats outside DEBUG"; fi

echo "---"
if [ "$fail" -ne 0 ]; then echo "design-lint FAILED"; exit 1; else echo "design-lint passed"; fi
