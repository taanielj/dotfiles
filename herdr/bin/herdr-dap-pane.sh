#!/usr/bin/env bash
# nvim-dap's external terminal inside herdr, see nvim/lua/lib/herdr_debug_pane.lua.
# Usage: herdr-dap-pane.sh <label> <program> [args...]
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
label="$1"
shift

pane=$("$herdr" pane split --pane "${HERDR_PANE_ID:?}" --direction down --cwd "$PWD" --no-focus |
    jq -r '.result.pane.pane_id')
"$herdr" pane rename "$pane" "$label" >/dev/null
# A leading space keeps the command out of zsh history (HIST_IGNORE_SPACE)
"$herdr" pane run "$pane" " $(printf '%q ' "$@")&& exit" >/dev/null
