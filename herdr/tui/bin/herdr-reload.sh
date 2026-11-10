#!/usr/bin/env bash
# Reloads the config and writes the result for herdr-reload-status.sh to show in
# the tab bar.
set -uo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/herdr"
mkdir -p "$state"

result=$("${HERDR_BIN_PATH:-herdr}" server reload-config 2>&1 |
    jq -r '"config " + .result.status
        + (if (.result.diagnostics | length) > 0
           then ": " + (.result.diagnostics | map(tostring) | join("; "))
           else "" end)')
# The first field is when the message expires. The tab bar polls once a second.
echo "$(($(date +%s) + 2)) ${result:-config reload failed}" >"$state/reload-result"
