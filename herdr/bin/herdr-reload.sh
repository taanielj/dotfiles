#!/usr/bin/env bash
# Reload the config and show the result in a popup for a moment, or until a
# key is pressed. Toasts go to the OS so agents are heard outside the
# terminal; this stays in the terminal where the config was just edited.
set -uo pipefail

"${HERDR_BIN_PATH:-herdr}" server reload-config 2>&1 |
    jq -r '"config " + .result.status
        + (if (.result.diagnostics | length) > 0
           then ": " + (.result.diagnostics | map(tostring) | join("; "))
           else "" end)'
read -r -s -n 1 -t 2 || true
