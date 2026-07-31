#!/usr/bin/env bash
# Pull another pane into the current herdr tab, picking it with fzf.
# Faithful port of tmux `choose-window` -> `join-pane`. Arg: split direction.
set -euo pipefail

dir="${1:-right}" # right | down
herdr="${HERDR_BIN_PATH:-herdr}"

line=$("$herdr" pane list | jq -r --arg cur "${HERDR_ACTIVE_PANE_ID:-}" --arg tab "${HERDR_ACTIVE_TAB_ID:-}" '
    .result.panes[]
    | select(.pane_id != $cur and .tab_id != $tab)
    | [ .pane_id,
        (.workspace_id + " · " + .tab_id + "  " + (.cwd | split("/") | last)
          + "  " + (.terminal_title_stripped // .agent // "shell")) ]
    | @tsv
' | fzf --with-nth=2.. --delimiter='\t' --prompt="join pane ($dir) > ") || exit 0

pane_id="${line%%$'\t'*}"
[[ -n "$pane_id" ]] || exit 0

"$herdr" pane move "$pane_id" --tab "${HERDR_ACTIVE_TAB_ID}" --split "$dir" --focus
