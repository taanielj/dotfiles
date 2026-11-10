#!/usr/bin/env bash
# ctrl+hjkl moves focus one step:
#   - In a pane running Neovim, herdr-splits forwards the key to Neovim.
#   - From any other unzoomed pane at the layout's edge, focus moves to the macOS
#     window in that direction, if there is one (hammerspoon/init.lua).
#   - Otherwise herdr-splits moves focus to the next pane, unzooming first and
#     wrapping around at the edge.
# ctrl+shift+hjkl passes `window` to move focus straight to the macOS window.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

dir="${1:?usage: herdr-nav.sh <left|down|up|right> [window]}"

if [[ "${2:-}" == window ]]; then
    hammerspoon "focusWindow('$dir')" >/dev/null
    exit 0
fi

if ! runs_nvim "${HERDR_ACTIVE_PANE_ID:-}"; then
    edges=$("$herdr" pane edges --current 2>/dev/null || true)
    if [[ "$edges" == *"\"$dir\":true"* && "$edges" != *'"zoomed":true'* &&
        "$(hammerspoon "focusWindow('$dir')")" == true ]]; then
        exit 0
    fi
fi

exec "$herdr" plugin action invoke "nav-$dir" --plugin herdr-splits
