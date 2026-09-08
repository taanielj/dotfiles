#!/usr/bin/env bash
# One-percent pane resize for alt+shift+hjkl. When Neovim is in the foreground
# the chord is forwarded so herdr-splits.nvim resizes the split or hands back
# to herdr; the same split as the plugin's own alt+hjkl script.
set -euo pipefail

dir="${1:?usage: herdr-resize-fine.sh <left|down|up|right>}"
herdr="${HERDR_BIN_PATH:-herdr}"

case "$dir" in
    left)  key="alt+shift+h" ;;
    down)  key="alt+shift+j" ;;
    up)    key="alt+shift+k" ;;
    right) key="alt+shift+l" ;;
    *) echo "herdr-resize-fine.sh: unknown direction: $dir" >&2; exit 2 ;;
esac

pane_id="${HERDR_ACTIVE_PANE_ID:-}"
if [[ -n "$pane_id" ]] &&
    "$herdr" pane process-info --pane "$pane_id" 2>/dev/null |
    grep -qE '"name"\s*:\s*"(g?(view|l?n?vim?x?)(diff)?)"'; then
    exec "$herdr" pane send-keys "$pane_id" "$key"
fi

exec "$herdr" pane resize --direction "$dir" --amount 0.01 --current
