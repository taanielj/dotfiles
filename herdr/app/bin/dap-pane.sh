#!/usr/bin/env bash
# nvim-dap's external terminal inside the Herdr app, see nvim/lua/lib/herdr_debug_pane.lua.
# Appends the terminal's address to <state file>, for herdr_debug_pane.lua to
# kill when the debug session ends.
# Usage: dap-pane.sh <state file> <program> [args...]
set -euo pipefail

state="$1"
shift

# A program that fails leaves a shell open to read why
open=$(jq -nc --arg folder "$PWD" \
    '{folder: $folder, place: "down",
      argv: (["sh", "-c", "\"$@\" || exec \"${SHELL:-sh}\"", "sh"] + $ARGS.positional)}' --args -- "$@")
terminal=$(herdr-app "do" terminal.open "$open" | jq -r .terminal)
mkdir -p "$(dirname "$state")"
echo "$terminal" >>"$state"
# terminal.open focused the new pane
herdr-app "do" pane.focus --terminal "${HC_TERMINAL_ID:?}" >/dev/null
