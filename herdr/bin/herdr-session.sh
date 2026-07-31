#!/usr/bin/env bash
# Build (or focus) a herdr workspace with one tab per repo — starting the herdr
# server and attaching if needed (herdr's server doesn't auto-start on API
# calls the way tmux does on session-create). Generic: label + repos come from
# the environment, so no work-specific paths live in this public repo.
#
#   HERDR_SESSION_LABEL   workspace label, e.g. "work" (arg $1 overrides)
#   HERDR_SESSION_REPOS   "tab:path;tab:path;..." — path under ${GIT_PATH:-$HOME/git}
#                         unless absolute; repos whose dir is missing are skipped
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
git="${GIT_PATH:-$HOME/git}"
label="${1:-${HERDR_SESSION_LABEL:-}}"
spec="${HERDR_SESSION_REPOS:-}"

[[ -n "$label" && -n "$spec" ]] || {
    echo "set HERDR_SESSION_LABEL and HERDR_SESSION_REPOS (see private shell config)" >&2
    exit 1
}

server_up() { ! "$herdr" status server 2>/dev/null | grep -q "not running"; }

# The workspace API below needs a running server; start one headless if needed.
if ! server_up; then
    nohup "$herdr" server >/dev/null 2>&1 &
    for _ in {1..200}; do server_up && break; sleep 0.05; done
fi

# Find the workspace, or build it from the repo list.
id=$("$herdr" workspace list | jq -r --arg l "$label" '.result.workspaces[] | select(.label==$l) | .workspace_id' | head -1)
if [[ -z "$id" ]]; then
    present=()
    IFS=';' read -ra entries <<<"$spec"
    for e in "${entries[@]}"; do
        e="${e#"${e%%[![:space:]]*}"}" # ltrim
        [[ -n "$e" ]] || continue
        p="${e#*:}"
        [[ "$p" == /* ]] || p="$git/$p"
        [[ -d "$p" ]] && present+=("${e%%:*}:$p")
    done
    [[ ${#present[@]} -gt 0 ]] || { echo "no repos from HERDR_SESSION_REPOS exist under $git" >&2; exit 1; }

    first="${present[0]}"
    out=$("$herdr" workspace create --cwd "${first#*:}" --label "$label" --focus)
    id=$(echo "$out" | jq -r '.result.root_pane.workspace_id')
    "$herdr" tab rename "$(echo "$out" | jq -r '.result.root_pane.tab_id')" "${first%%:*}"
    for e in "${present[@]:1}"; do
        "$herdr" tab create --workspace "$id" --cwd "${e#*:}" --label "${e%%:*}" --no-focus >/dev/null
    done
fi

"$herdr" workspace focus "$id" >/dev/null

# Attach unless we're already inside a herdr client.
[[ "${HERDR_ENV:-}" == "1" ]] || exec "$herdr"
