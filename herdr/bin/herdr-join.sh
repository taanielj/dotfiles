#!/usr/bin/env bash
# Pull another pane into the current herdr tab, picking it with fzf.
# Faithful port of tmux `choose-window` -> `join-pane`. Arg: split direction.
set -euo pipefail

dir="${1:-right}" # right | down
herdr="${HERDR_BIN_PATH:-herdr}"

# Panes labelled the way the UI shows them: workspace label, tab number:label,
# cwd basename (when it differs from the tab label), pane title.
line=$({
    "$herdr" pane list
    "$herdr" tab list
    "$herdr" workspace list
} |
    jq -rs --arg cur "${HERDR_ACTIVE_PANE_ID:-}" --arg tab "${HERDR_ACTIVE_TAB_ID:-}" '
    (.[1].result.tabs | INDEX(.tab_id)) as $tabs
    | (.[2].result.workspaces | INDEX(.workspace_id)) as $ws
    | .[0].result.panes[]
    | select(.pane_id != $cur and .tab_id != $tab)
    | $tabs[.tab_id] as $t
    | (.cwd | split("/") | last) as $dirname
    | [ .pane_id,
        ($ws[.workspace_id].label // .workspace_id)
          + " · " + (($t.number // "?") | tostring) + ":" + ($t.label // "")
          + (if $t.label == $dirname then "" else "  " + $dirname end)
          + "  " + (.terminal_title_stripped // .agent // "shell") ]
    | @tsv
' | fzf --with-nth=2.. --delimiter='\t' --prompt="join pane ($dir) > " \
    --preview "\"$herdr\" pane read {1} --source recent --lines 40 --format text" \
    --preview-window=down,50%) || exit 0

pane_id="${line%%$'\t'*}"
[[ -n "$pane_id" ]] || exit 0

"$herdr" pane move "$pane_id" --tab "${HERDR_ACTIVE_TAB_ID}" --split "$dir" --focus
