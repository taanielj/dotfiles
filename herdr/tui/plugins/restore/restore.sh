#!/bin/sh
# Remembers which pane runs a program from `programs` and reruns it in that pane
# after a herdr server restart. Pane ids survive a restart and are never reused.
#
#   restore.sh        startup hook: rerun the saved programs, then start the loop
#   restore.sh loop   save on an interval, until a newer loop takes over
#
# Whole seconds, from the herdr server's environment
ac_save_secs=${HERDR_RESTORE_AC_INTERVAL:-1}
battery_save_secs=${HERDR_RESTORE_BATTERY_INTERVAL:-10}
power_check_secs=${HERDR_RESTORE_POWER_INTERVAL:-10}
set -u

herdr=${HERDR_BIN_PATH:-herdr}
here=$(cd "$(dirname "$0")" && pwd)
session=$(basename "$(dirname "${HERDR_SOCKET_PATH:?}")")
dir=${HERDR_PLUGIN_STATE_DIR:?}
state=$dir/$session.json    # pane id -> {pid, argv} of the program it runs
shells=$dir/$session.shells # "pane-id shell-pid" lines, looked up once per pane
pidfile=$dir/$session.pid
mkdir -p "$dir"
[ -f "$state" ] || echo '{}' >"$state"

# Reads herdr's pane list on the first line and `ps` output after it. Prints the
# pane id of each pane whose shell still runs, then one of:
#   pid  the pane's foreground program, when `programs` lists it
#   -    the shell or an unlisted program is in the foreground
#   ?    the pane's shell pid isn't in $shells yet
# shellcheck disable=SC2016
find_programs='
    BEGIN {
        while ((getline line < programs) > 0) if (line !~ /^#/ && line != "") want[line]
        while ((getline line < shells) > 0) { split(line, f, " "); shell[f[1]] = f[2] }
    }
    NR == 1 {
        while (match($0, /"pane_id":"[^"]*"/)) {
            panes[++n] = substr($0, RSTART + 11, RLENGTH - 12)
            $0 = substr($0, RSTART + RLENGTH)
        }
        next
    }
    {
        group[$1] = $3; fg[$1] = $4; kids[$2] = kids[$2] " " $1
        name = $0; sub(/^ *[0-9]+ +[0-9]+ +[0-9]+ +-?[0-9]+ +/, "", name); sub(/.*\//, "", name)
        comm[$1] = name
    }
    END {
        for (i = 1; i <= n; i++) {
            pane = panes[i]; s = shell[pane]
            if (s == "") { print pane, "?"; continue }
            if (!(s in group)) continue
            found = "-"
            if (fg[s] != group[s]) {
                k = split(kids[s], kid, " ")
                for (j = 1; j <= k; j++)
                    if (group[kid[j]] == fg[s] && comm[kid[j]] in want) found = kid[j]
            }
            print pane, found
        }
    }'

restore() {
    list=$("$herdr" pane list) || return
    live=$(printf '%s\n' "$list" | jq -r '.result.panes[].pane_id')
    jq -r 'to_entries[]
        | "\(.key)\t\(.value.argv | map(if test("^[A-Za-z0-9_./:=@%+,-]+$") then . else @sh end) | join(" "))"' "$state" |
        while IFS='	' read -r pane cmd; do
            printf '%s\n' "$live" | grep -qxF "$pane" || continue
            # The program keeps running across `herdr update --handoff`
            shell_in_foreground=$("$herdr" pane process-info --pane "$pane" |
                jq '.result.process_info | .foreground_process_group_id == .shell_pid')
            if [ "$shell_in_foreground" = true ]; then "$herdr" pane run "$pane" "$cmd"; fi
        done
    # Drop panes that were closed while their program ran
    printf '%s\n' "$live" | jq -R . | jq -s --slurpfile s "$state" \
        '. as $live | $s[0] | with_entries(select(.key | IN($live[])))' >"$state.tmp" &&
        mv "$state.tmp" "$state"
}

# Returns 1 once the server is gone.
tick() {
    list=$("$herdr" pane list) || return 1
    seen=$({ printf '%s\n' "$list"; ps -A -o pid=,ppid=,pgid=,tpgid=,comm=; } |
        awk -v programs="$here/programs" -v shells="$shells" "$find_programs")
    # jq runs only when a pane or its program changes
    [ "$seen" = "$last_seen" ] && return 0

    case $seen in *' ?'*)
        # Record the shell pids of new panes, and read the panes' programs next tick
        printf '%s\n' "$seen" | while read -r pane pid; do
            [ "$pid" = '?' ] && "$herdr" pane process-info --pane "$pane" |
                jq -r --arg p "$pane" '"\($p) \(.result.process_info.shell_pid)"' >>"$shells"
        done
        return 0
        ;;
    esac
    printf '%s\n' "$seen" | awk 'NR == FNR { live[$1]; next } $1 in live' - "$shells" >"$shells.tmp" &&
        mv "$shells.tmp" "$shells"

    # Fetch argv only for programs not in $state yet, one herdr call each
    jq -rn --arg seen "$seen" --slurpfile s "$state" '
        $seen | split("\n")[] | split(" ")
        | select(.[1] != "-" and ($s[0][.[0]].pid | tostring) != .[1]) | join(" ")' |
        while read -r pane pid; do
            "$herdr" pane process-info --pane "$pane" | jq -c --arg p "$pane" --argjson pid "$pid" \
                '{pane: $p, pid: $pid, argv: (.result.process_info.foreground_processes[] | select(.pid == $pid) | .argv)}'
        done >"$state.argv"

    jq -n --arg seen "$seen" --slurpfile s "$state" --slurpfile got "$state.argv" '
        reduce ($seen | split("\n")[] | split(" ")) as [$pane, $pid] ($s[0];
            if $pid == "-" then del(.[$pane])
            else (first($got[] | select(.pane == $pane)) // null) as $g
                | if $g then .[$pane] = {pid: $g.pid, argv: $g.argv} else . end
            end)' >"$state.tmp" || return 0
    if cmp -s "$state.tmp" "$state"; then rm "$state.tmp"; else mv "$state.tmp" "$state"; fi
    last_seen=$seen
}

case ${1:-startup} in
loop)
    echo $$ >"$pidfile"
    last_seen=
    interval=$ac_save_secs
    since_power_check=$power_check_secs
    command -v pmset >/dev/null && has_pmset=true || has_pmset=false
    while read -r owner <"$pidfile" && [ "$owner" = $$ ] && tick; do
        if [ "$has_pmset" = true ] && [ "$since_power_check" -ge "$power_check_secs" ]; then
            case $(pmset -g ps) in
            *"'Battery Power'"*) interval=$battery_save_secs ;;
            *) interval=$ac_save_secs ;;
            esac
            since_power_check=0
        fi
        sleep "$interval"
        since_power_check=$((since_power_check + interval))
    done
    ;;
*)
    for dep in "$herdr" jq awk ps; do
        command -v "$dep" >/dev/null || { echo "restore: $dep not found on PATH" >&2; exit 1; }
    done
    rm -f "$shells" # every pane has a new shell after a restart
    restore
    sh "$here/restore.sh" loop </dev/null >/dev/null 2>&1 &
    ;;
esac
