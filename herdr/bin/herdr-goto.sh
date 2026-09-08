#!/usr/bin/env bash
# Jump to another pane, picking it with fzf over a preview of its screen.
# The CLI focuses workspaces and tabs, so this lands on the pane's tab.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/herdr-panes.sh"

IFS=$'\t' read -r _ tab_id workspace_id < <(pick_pane "goto > ") || true
[[ -n "${tab_id:-}" ]] || exit 0

"$herdr" workspace focus "$workspace_id"
"$herdr" tab focus "$tab_id"
