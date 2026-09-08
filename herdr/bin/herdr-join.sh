#!/usr/bin/env bash
# Pull another pane into the current herdr tab, picking it with fzf.
set -euo pipefail

dir="${1:-right}" # right | down
source "$(dirname "${BASH_SOURCE[0]}")/herdr-panes.sh"

IFS=$'\t' read -r pane_id _ _ < <(pick_pane "join pane ($dir) > " "${HERDR_ACTIVE_TAB_ID:-}") || true
[[ -n "${pane_id:-}" ]] || exit 0

"$herdr" pane move "$pane_id" --tab "${HERDR_ACTIVE_TAB_ID}" --split "$dir" --focus
