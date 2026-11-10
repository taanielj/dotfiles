#!/usr/bin/env bash
# alt+hjkl resizes the focused pane, and alt+shift+hjkl (`fine`) resizes it in
# smaller steps.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

dir="${1:?usage: herdr-resize.sh <left|down|up|right> [fine]}"
fine="${2:-}"
chord=alt step=0.03 os_step=nil
[[ -n "$fine" ]] && chord=alt+shift step=0.01 os_step=0.01

case "$dir" in
    left)  letter=h; sides=(left right) ;;
    down)  letter=j; sides=(up down) ;;
    up)    letter=k; sides=(up down) ;;
    right) letter=l; sides=(left right) ;;
    *) echo "herdr-resize.sh: unknown direction: $dir" >&2; exit 2 ;;
esac

pane_id="${HERDR_ACTIVE_PANE_ID:-}"
# herdr-splits.nvim resizes Neovim's split or calls back into herdr
if runs_nvim "$pane_id"; then
    exec "$herdr" pane send-keys "$pane_id" "$chord+$letter"
fi

# A pane that spans the layout along the direction's axis resizes the macOS
# window (hammerspoon/init.lua)
edges=$("$herdr" pane edges --current 2>/dev/null || true)
if [[ "$edges" == *"\"${sides[0]}\":true"* && "$edges" == *"\"${sides[1]}\":true"* &&
    "$edges" != *'"zoomed":true'* &&
    "$(hammerspoon "resizeWindow('$dir', $os_step)")" == true ]]; then
    exit 0
fi

exec "$herdr" pane resize --direction "$dir" --amount "$step" --current
