#!/usr/bin/env bash
# Pick another pane with fzf over a preview of its screen, then jump to it or
# pull it into the current tab. Panes are labelled the way the UI shows them.
# Previews run in a non-interactive shell, so aliases do not apply.
#
# Usage: herdr-pane-pick.sh goto
#        herdr-pane-pick.sh join <right|down>
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"

# TSV per pane: pane_id, tab_id, workspace_id, label. The current pane is left
# out; $1 is a tab id whose panes are left out too.
pane_lines() {
    {
        "$herdr" pane list
        "$herdr" tab list
        "$herdr" workspace list
    } |
        jq -rs --arg cur "${HERDR_ACTIVE_PANE_ID:-}" --arg skip_tab "${1:-}" '
        (.[1].result.tabs | INDEX(.tab_id)) as $tabs
        | (.[2].result.workspaces | INDEX(.workspace_id)) as $ws
        | .[0].result.panes[]
        | select(.pane_id != $cur and .tab_id != $skip_tab)
        | $tabs[.tab_id] as $t
        | ((.cwd // "") | split("/") | last) as $dirname
        | [ .pane_id, .tab_id, .workspace_id,
            ($ws[.workspace_id].label // .workspace_id)
              + " · " + (($t.number // "?") | tostring) + ":" + ($t.label // "")
              + (if $t.label == $dirname then "" else "  " + $dirname end)
              + "  " + (.terminal_title_stripped // .agent // "shell") ]
        | @tsv
    '
}

# Prints the chosen pane's pane_id, tab_id, workspace_id as TSV; nothing when
# cancelled. $1 is the fzf prompt, $2 a tab id to leave out.
pick_pane() {
    pane_lines "${2:-}" |
        fzf --height=100% --with-nth=4.. --delimiter='\t' --prompt="$1" \
            --preview "\"$herdr\" pane read {1} --source visible --format ansi" \
            --preview-window=down,50% |
        cut -f1-3
}

case "${1:-}" in
goto)
    # The CLI focuses workspaces and tabs, so this lands on the pane's tab.
    IFS=$'\t' read -r _ tab_id workspace_id < <(pick_pane "goto > ") || true
    [[ -n "${tab_id:-}" ]] || exit 0
    "$herdr" workspace focus "$workspace_id"
    "$herdr" tab focus "$tab_id"
    ;;
join)
    dir="${2:?usage: herdr-pane-pick.sh join <right|down>}"
    IFS=$'\t' read -r pane_id _ _ < <(pick_pane "join pane ($dir) > " "${HERDR_ACTIVE_TAB_ID:-}") || true
    [[ -n "${pane_id:-}" ]] || exit 0
    "$herdr" pane move "$pane_id" --tab "${HERDR_ACTIVE_TAB_ID}" --split "$dir" --focus
    ;;
*)
    echo "usage: herdr-pane-pick.sh goto | join <right|down>" >&2
    exit 2
    ;;
esac
