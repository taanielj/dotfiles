#!/usr/bin/env bash
# Reload the config and leave the result for herdr-reload-status.sh to show in
# the tab bar. A popup or toast would take input or leave the terminal; the
# tab bar does neither.
set -uo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/herdr"
mkdir -p "$state"

result=$("${HERDR_BIN_PATH:-herdr}" server reload-config 2>&1 |
    jq -r '"config " + .result.status
        + (if (.result.diagnostics | length) > 0
           then ": " + (.result.diagnostics | map(tostring) | join("; "))
           else "" end)')
# First field is when the message expires; the bar polls once a second.
echo "$(($(date +%s) + 2)) ${result:-config reload failed}" >"$state/reload-result"
