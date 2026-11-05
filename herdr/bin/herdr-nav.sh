#!/usr/bin/env bash
# ctrl+hjkl: herdr-splits' navigation, except that a plain pane at the layout
# edge first hands focus to the macOS window that way (hammerspoon/init.lua).
# herdr-splits forwards the key into Neovim, unzooms, and wraps when no window
# is there. ctrl+shift+hjkl passes `window` to go straight to the macOS window,
# past panes and Neovim.
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
