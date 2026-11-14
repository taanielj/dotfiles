#!/usr/bin/env bash
# herdr-app on WSL: this distro's ids bare, the Windows app's own as local/<id>
set -euo pipefail

app=herdr-app.exe

# Mod commands such as the nav keys' keys.go-left take and print no ids
if [[ $# -eq 2 && $1 == do && $2 == keys.* ]] || [[ ${1:-} != ls && ${1:-} != status && ${1:-} != do ]]; then
    exec "$app" "$@"
fi

core=$(jq -r .id "${XDG_STATE_HOME:-$HOME/.local/state}/herdr-core/default/core.json" 2>/dev/null) || exec "$app" "$@"
cache="${XDG_RUNTIME_DIR:-/tmp}/herdr-app-machine"
machine=""
[[ -r $cache ]] && read -r cached machine <"$cache" && [[ $cached == "$core" ]] || {
    machine=$(hc.exe machine ls --json | jq -r --arg id "$core" 'first(.machines[] | select(.id == $id) | .name) // ""')
    [[ -n $machine ]] && echo "$core $machine" >"$cache"
}
# Without this distro among the app's machines, every id is the app's own
[[ -n $machine ]] || exec "$app" "$@"

# "id" also names layout blocks, so only space, tab and pane ids count
# shellcheck disable=SC2016 # jq variables
defs='
def keys: ["terminal", "agent", "parent", "pane", "focused_pane", "space", "tab", "target", "id"];
def address($k): $k != "id" or test("^([^/]+/)?(sp|tb|p)[0-9a-f]{32}$");
def outward: if startswith($m + "/") then .[($m | length) + 1:] elif contains("/") then . else "local/" + . end;
def inward: if startswith("local/") then .[6:] elif contains("/") then . else $m + "/" + . end;
'

inward() {
    local key=$1 value=$2
    jq -rn --arg m "$machine" --arg k "$key" --arg v "$value" \
        "$defs"'$v | if ($k | IN(keys[])) and address($k) then inward else . end'
}

args=("$@")
if [[ $1 == do ]]; then
    args=(do "$2")
    shift 2
    if [[ ${1:-} == "{"* ]]; then
        args+=("$(jq -c --arg m "$machine" --arg cmd "${args[1]}" "$defs"'
            with_entries(if (.key | IN(keys[])) and (.value | type) == "string" and (.key as $k | .value | address($k))
                then .value |= inward else . end)
            | if $cmd == "space.new" and (has("machine") | not) then .machine = $m else . end' <<<"$1")")
    else
        machine_given=false
        while [[ $# -gt 0 ]]; do
            if [[ $1 == --* && $# -gt 1 ]]; then
                [[ $1 == --machine ]] && machine_given=true
                args+=("$1" "$(inward "${1#--}" "$2")")
                shift 2
            else
                args+=("$1")
                shift
            fi
        done
        # Spaces made from here open on this distro
        [[ ${args[1]} == space.new && $machine_given == false ]] && args+=(--machine "$machine")
    fi
fi

status=0
out=$("$app" "${args[@]}") || status=$?
jq --arg m "$machine" "$defs"'
    walk(if type == "object" then with_entries(
        if (.key | IN(keys[])) and (.value | type) == "string" and (.key as $k | .value | address($k)) then .value |= outward
        elif .key == "sub_agents" and (.value | type) == "array" then .value |= map(if type == "string" then outward else . end)
        else . end) else . end)' <<<"$out" 2>/dev/null || printf '%s\n' "$out"
exit "$status"
