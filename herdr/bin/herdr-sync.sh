#!/usr/bin/env bash
# Usage: herdr-sync app|tui
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
socket="${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}"
to="${1:-}"
[[ "$to" == app || "$to" == tui ]] || { echo "usage: herdr-sync app|tui" >&2; exit 1; }

# The popup running this closes as soon as it exits
trap 'status=$?; if ((status)); then printf "\nFailed. Press enter to close."; read -r _; fi' EXIT

app() { herdr-app do "$@"; }

# The herdr CLI has no command for layout.export and layout.apply
tui_api() {
    printf '{"id":"sync","method":"%s","params":%s}\n' "$1" "$2" | nc -U "$socket" |
        jq -c 'if .error then error(.error.message) else .result end'
}

tui_id() { tui_api "$1" "{\"$2\":\"$3\"}"; }

# herdr-app's commands don't expose its split trees
app_layout_doc() {
    printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"doc.get","params":{"name":"herdr-app"}}' | hc connect | jq -c .result.value
}

# Usage: plan_pane <key> <cwd> [<program> <pid> <program cwd>]
plan_pane() {
    local key=$1 cwd=$2 name=${3:-} pid=${4:-} run="" session
    case "${name##*/}" in
    nvim) run=nvim cwd=$5 pid="" ;;
    claude)
        # Claude records its session in <config dir>/sessions/<pid>.json
        session=$(ls "$HOME"/.claude*/sessions/"$pid".json 2>/dev/null | head -1)
        [[ -n "$session" ]] || { echo "no session file for Claude pid $pid" >&2; exit 1; }
        run="claude --resume $(jq -r .sessionId "$session")" cwd=$5
        ;;
    *) pid="" ;;
    esac
    jq -nc --arg key "$key" --arg cwd "$cwd" --arg run "$run" --arg pid "$pid" '{key: $key, cwd: $cwd, run: $run, pid: $pid}'
}

# A plan is {focused, spaces: [{name, active, tabs: [{name, focus, root}]}], panes},
# with focused and active as indexes, focus as a pane key, root as a tree of
# {type: "split", direction: "right" | "down", ratio, first, second} and
# {type: "pane", key} nodes, and panes mapping each key to its plan_pane.

read_tui() {
    local snapshot panes trees id cwd
    snapshot=$("$herdr" api snapshot | jq -c .result.snapshot)
    panes=$(jq -r '.panes[] | "\(.pane_id)\t\(.foreground_cwd // .cwd)"' <<<"$snapshot" |
        while IFS=$'\t' read -r id cwd; do
            # shellcheck disable=SC2046
            plan_pane "$id" "$cwd" $("$herdr" pane process-info --pane "$id" | jq -r '
                [.result.process_info.foreground_processes[] | select(.argv[0] | sub(".*/"; "") | IN("nvim", "claude"))]
                | first // empty | "\(.argv[0]) \(.pid) \(.cwd)"')
        done | jq -sc 'INDEX(.key)')
    trees=$(jq -r '.tabs[].tab_id' <<<"$snapshot" | while read -r id; do
        tui_id layout.export tab_id "$id"
    done | jq -sc 'map(.layout | {key: .tab_id, value: .root}) | from_entries')
    jq -c --argjson panes "$panes" --argjson trees "$trees" '
        def keyed: if .type == "pane" then {type, key: .pane_id} else .first |= keyed | .second |= keyed end;
        (.workspaces | sort_by(.number)) as $ws | . as $s
        | {
            panes: $panes,
            focused: ([$ws[].workspace_id] | index($s.focused_workspace_id)),
            spaces: [$ws[] | .workspace_id as $w | .active_tab_id as $active
                | ($s.tabs | map(select(.workspace_id == $w)) | sort_by(.number)) as $tabs
                | {
                    name: (.label // ""),
                    active: ([$tabs[].tab_id] | index($active)),
                    tabs: [$tabs[] | . as $t | ($s.layouts[] | select(.tab_id == $t.tab_id)) as $l | {
                        name: (.label // ""), focus: $l.focused_pane_id, root: ($trees[.tab_id] | keyed)
                    }]
                }]
        }' <<<"$snapshot"
}

read_app() {
    local spaces doc panes id
    spaces=$(herdr-app ls | jq -c '[.spaces[] | select(.machine == null)]')
    doc=$(app_layout_doc)
    panes=$(jq -r '.[].tabs[].terminals[].terminal' <<<"$spaces" | while read -r id; do
        # shellcheck disable=SC2046
        plan_pane "$id" $(hc get "$id" --json | jq -r '"\(.cwd) \(.foreground.argv[0] // "") \(.foreground.pid // "") \(.foreground.cwd // "")"')
    done | jq -sc 'INDEX(.key)')
    jq -c --argjson panes "$panes" --argjson doc "$doc" --slurpfile view "$HOME/.config/herdr-app/view.json" '
        ($doc.spaces | map(.tabs[]) | INDEX(.id)) as $trees
        | def binary:
            if .type == "block" then (if .content.terminal then {type: "pane", key: .content.terminal} else empty end)
            else (if .type == "row" then "right" else "down" end) as $dir
                | [.children[] | {node: binary, weight: (.size.weight // 1)}]
                | def pair: if length == 1 then .[0].node else {
                      type: "split", direction: $dir, ratio: (.[0].weight / (map(.weight) | add)),
                      first: .[0].node, second: (.[1:] | pair)
                  } end;
                  if length == 0 then empty else pair end
            end;
          def keys: if .type == "pane" then [.key] else (.first | keys) + (.second | keys) end;
        {
            panes: $panes,
            focused: (map(.active) | index(true)),
            spaces: [.[] | {
                name,
                active: (.tabs | map(.active) | index(true)),
                tabs: [.tabs[] | ($trees[.id].root | binary) as $root | ($view[0].tabs[.id].focused // "") as $focused
                    | (first($trees[.id].root | .. | objects | select(.id == $focused) | .content.terminal) // null) as $f
                    | {name, root: $root, focus: ($f // ($root | keys[0]))}]
            }]
        }' <<<"$spaces"
}

confirm() {
    jq -r --arg from "$1" '
        def keys: if .type == "pane" then [.key] else (.first | keys) + (.second | keys) end;
        "From \($from): \(.spaces | length) spaces, \([.spaces[].tabs[]] | length) tabs, \([.spaces[].tabs[].root | keys[]] | length) panes",
        (.spaces[] | "  \(.name): \([.tabs[].name] | join(", "))"),
        "Stops \([.panes[] | select(.pid != "")] | length) Claude sessions in \($from) to resume them here."' <<<"$plan"
    echo "Closes all $3 spaces in $2, ending their terminals."
    read -r -p 'Type yes to continue: ' answer
    [[ "$answer" == yes ]] || exit 0
}

# Two Claude processes on one session would both write its transcript
stop_claudes() {
    local pids pid
    pids=$(jq -r '.panes[] | select(.pid != "") | .pid' <<<"$plan")
    for pid in $pids; do kill -TERM "$pid"; done
    for pid in $pids; do
        for _ in {1..100}; do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
        if kill -0 "$pid" 2>/dev/null; then echo "Claude pid $pid didn't stop" >&2; exit 1; fi
    done
}

pane_field() { jq -r --arg k "$1" ".panes[\$k].$2" <<<"$plan"; }

# Typed into the pane's shell rather than run as its program, for the shell to load
# the folder's direnv first
pane_commands() { jq -r '.panes[] | select(.run != "") | [.key, .run] | @tsv' <<<"$plan"; }

# Unlike wait, fails when a job fails
wait_all() {
    local status
    while :; do
        status=0
        wait -n || status=$?
        ((status == 127)) && return 0 # no jobs left
        ((status == 0)) || return "$status"
    done
}

# Usage: build_app_tab <tab plan> <space name>
# Creates the space when $space is empty, and sets $space and $tab_id
build_app_tab() {
    local tab=$1 first name created from place key
    first=$(jq -r '.root | until(.type == "pane"; .first) | .key' <<<"$tab")
    name=$(jq -r .name <<<"$tab")
    if [[ -z "$space" ]]; then
        created=$(app space.new --name "$2" --tab "$name" --folder "$(pane_field "$first" cwd)")
    else
        created=$(app tab.new --space "$space" --name "$name" --folder "$(pane_field "$first" cwd)")
    fi
    app_terminal[$first]=$(jq -r .terminal <<<"$created")
    space=$(jq -r .space <<<"$created")
    tab_id=$(jq -r .tab <<<"$created")
    # Each split's second half opens beside the first pane of its first half
    while IFS=$'\t' read -r from place key; do
        app pane.focus --terminal "${app_terminal[$from]}" >/dev/null
        app_terminal[$key]=$(app terminal.open --place "$place" --folder "$(pane_field "$key" cwd)" | jq -r .terminal)
    done < <(jq -r '
        def first_key: until(.type == "pane"; .first) | .key;
        .root | recurse(.first, .second; .type == "split") | select(.type == "split")
        | [(.first | first_key), .direction, (.second | first_key)] | @tsv' <<<"$tab")
    size_app_tab "$tab"
}

size_app_tab() {
    local terminals id weight
    terminals=$(for key in "${!app_terminal[@]}"; do printf '%s\t%s\n' "$key" "${app_terminal[$key]}"; done |
        jq -Rsc 'split("\n") | map(select(. != "") | split("\t") | {key: .[0], value: .[1]}) | from_entries')
    app_layout_doc | jq -r --arg tab "$tab_id" --argjson plan "$1" --argjson terminals "$terminals" '
        def rects($r):
            if .type == "pane" then {($terminals[.key]): $r}
            else .ratio as $q
                | if .direction == "right" then
                    (.first | rects($r + {w: ($r.w * $q)})) + (.second | rects($r + {x: ($r.x + $r.w * $q), w: ($r.w * (1 - $q))}))
                else
                    (.first | rects($r + {h: ($r.h * $q)})) + (.second | rects($r + {y: ($r.y + $r.h * $q), h: ($r.h * (1 - $q))}))
                end
            end;
        ($plan.root | rects({x: 0, y: 0, w: 1, h: 1})) as $rects
        | def leaves: if .content.terminal then [$rects[.content.terminal]] else [.children[] | leaves] | add end;
          def extent($pos; $size): leaves | (map(.[$pos] + .[$size]) | max) - (map(.[$pos]) | min);
        .spaces[].tabs[] | select(.id == $tab) | .root
        | .. | objects | select((.type == "row" or .type == "column") and (.children | length) > 1)
        | (if .type == "row" then ["x", "w"] else ["y", "h"] end) as [$pos, $size]
        | .children[] | "\(.id)\t\(extent($pos; $size))"' |
        while IFS=$'\t' read -r id weight; do
            app layout.resize "$(jq -nc --arg id "$id" --argjson w "$weight" '{id: $id, weight: $w}')" >/dev/null
        done
}

to_app() {
    local old plan_space tab ids i active pane
    old=$(herdr-app ls | jq -r '.spaces[] | select(.machine == null) | .id')
    confirm "the herdr TUI" "the Herdr app" "$(grep -c . <<<"$old")"
    stop_claudes
    declare -A app_terminal
    local spaces=() tabs=() space tab_id
    while read -r plan_space; do
        space="" ids=""
        while read -r tab; do
            build_app_tab "$tab" "$(jq -r .name <<<"$plan_space")"
            ids+="$tab_id "
        done < <(jq -c '.tabs[]' <<<"$plan_space")
        spaces+=("$space")
        tabs+=("$ids")
    done < <(jq -c '.spaces[]' <<<"$plan")

    # In parallel, because each hc send waits for a pause in typing
    while IFS=$'\t' read -r pane run; do
        hc send "${app_terminal[$pane]}" "$run" >/dev/null &
    done < <(pane_commands)
    wait_all

    while read -r pane; do
        app pane.focus --terminal "${app_terminal[$pane]}" >/dev/null
    done < <(jq -r '.spaces[].tabs[].focus' <<<"$plan")
    i=0
    while read -r active; do
        read -ra ids <<<"${tabs[$i]}"
        app tab.select --id "${ids[$active]}" >/dev/null
        i=$((i + 1))
    done < <(jq -r '.spaces[].active' <<<"$plan")
    app space.select --id "${spaces[$(jq -r .focused <<<"$plan")]}" >/dev/null

    for id in $old; do app space.close --id "$id" --confirmed true >/dev/null; done
}

# Prints the folder's checkout and its main checkout, which differ in a linked worktree
checkout_roots() {
    git -C "$1" rev-parse --show-toplevel --path-format=absolute --git-common-dir 2>/dev/null |
        sed '2s|/\.git$||' | paste -sd '\t' - || true
}

# Usage: close_old_tui_workspaces <linked>
close_old_tui_workspaces() {
    local id
    for id in $(jq -r --argjson linked "$1" --arg popup "$popup_workspace" --arg main "$popup_main_workspace" '.[]
        | select((.worktree.is_linked_worktree == true) == $linked and (.workspace_id | IN($popup, $main) | not)) | .workspace_id' <<<"$old"); do
        tui_id workspace.close workspace_id "$id" >/dev/null &
    done
    wait_all
}

# herdr-core runs these closes, because closing the popup's workspace ends the popup.
# A worktree's main checkout closes after it: herdr refuses to close a main
# checkout's workspace while workspaces of its linked worktrees are open.
close_popup_workspace() {
    jq -e --arg popup "$popup_workspace" 'any(.workspace_id == $popup)' <<<"$old" >/dev/null || return 0
    hc run --bg --no-parent --rm -- sh -c '
        for id in $2; do
            printf "{\"id\":\"sync\",\"method\":\"workspace.close\",\"params\":{\"workspace_id\":\"%s\"}}\n" "$id" | nc -U "$1"
        done' sh "$socket" "$popup_workspace $popup_main_workspace" >/dev/null
}

space_cwd() { pane_field "$(jq -r '.tabs[0].root | until(.type == "pane"; .first) | .key' <<<"${plan_spaces[$1]}")" cwd; }

# Usage: fill_tui_workspace <space index> <created workspace>
fill_tui_workspace() {
    local workspace initial tab applied key id ids=""
    workspace=$(jq -r .workspace.workspace_id <<<"$2")
    initial=$(jq -r .tab.tab_id <<<"$2")
    while read -r tab; do
        applied=$(tui_api layout.apply "$(jq -c --arg w "$workspace" --argjson panes "$panes" '
            def node: if .type == "pane" then {type, cwd: $panes[.key].cwd} else .first |= node | .second |= node end;
            {workspace_id: $w, tab_label: (if .name == "" then null else .name end), root: (.root | node)}' <<<"$tab")")
        ids+="$(jq -r .layout.tab_id <<<"$applied") "
        # The applied tree has the plan's shape
        while IFS=$'\t' read -r key id; do tui_pane[$key]=$id; done < <(jq -r --argjson applied "$applied" '
            def zip($a; $b): if $a.type == "pane" then [[$a.key, $b.pane_id]] else zip($a.first; $b.first) + zip($a.second; $b.second) end;
            zip(.root; $applied.layout.root)[] | @tsv' <<<"$tab")
    done < <(jq -c '.tabs[]' <<<"${plan_spaces[$1]}")
    tui_id tab.close tab_id "$initial" >/dev/null
    workspaces[$1]=$workspace
    tabs[$1]=$ids
}

create_tui_workspace() {
    fill_tui_workspace "$1" "$(tui_api workspace.create "$(jq -c --arg c "$(space_cwd "$1")" \
        '{label: (.name | if . == "" then null else . end), cwd: $c}' <<<"${plan_spaces[$1]}")")"
}

to_tui() {
    local old popup_workspace="${HERDR_ACTIVE_WORKSPACE_ID:-}" popup_main_workspace panes i roots top main created key active
    old=$("$herdr" workspace list | jq -c .result.workspaces)
    popup_main_workspace=$(jq -r --arg popup "$popup_workspace" '(.[] | select(.workspace_id == $popup and .worktree.is_linked_worktree)) as $p
        | first(.[] | select(.worktree.checkout_path == $p.worktree.repo_root and (.worktree.is_linked_worktree | not)) | .workspace_id) // empty' <<<"$old")
    confirm "the Herdr app" "the herdr TUI" "$(jq length <<<"$old")"
    stop_claudes
    # Before the build, because worktree.open reuses a workspace open in the
    # worktree. Linked worktrees first: herdr refuses to close a main checkout's
    # workspace while workspaces of its linked worktrees are open.
    close_old_tui_workspaces true
    close_old_tui_workspaces false

    declare -A tui_pane main_workspace linked_spaces
    local plan_spaces workspaces=() tabs=()
    mapfile -t plan_spaces < <(jq -c '.spaces[]' <<<"$plan")
    panes=$(jq -c .panes <<<"$plan")

    # Main checkouts first, because their linked worktrees open from their workspace
    for i in "${!plan_spaces[@]}"; do
        roots=$(checkout_roots "$(space_cwd "$i")")
        top=${roots%%$'\t'*} main=${roots#*$'\t'}
        if [[ -n "$roots" && "$top" != "$main" ]]; then
            linked_spaces[$i]=$roots
            continue
        fi
        create_tui_workspace "$i"
        [[ -z "$roots" ]] || main_workspace[$main]=${workspaces[$i]}
    done
    for i in "${!linked_spaces[@]}"; do
        top=${linked_spaces[$i]%%$'\t'*} main=${linked_spaces[$i]#*$'\t'}
        created=""
        if [[ -n "${main_workspace[$main]:-}" ]]; then
            created=$(tui_api worktree.open "$(jq -c --arg w "${main_workspace[$main]}" --arg p "$top" \
                '{workspace_id: $w, path: $p, label: (.name | if . == "" then null else . end)}' <<<"${plan_spaces[$i]}")")
        fi
        # Open only in the popup's workspace, which the sync closes last
        if [[ -n "$created" ]] && jq -e '.already_open | not' <<<"$created" >/dev/null; then
            fill_tui_workspace "$i" "$created"
        else
            create_tui_workspace "$i"
        fi
    done

    while IFS=$'\t' read -r key run; do
        "$herdr" pane run "${tui_pane[$key]}" "$run" >/dev/null &
    done < <(pane_commands)
    while read -r key; do
        tui_id pane.focus pane_id "${tui_pane[$key]}" >/dev/null &
    done < <(jq -r '.spaces[].tabs[].focus' <<<"$plan")
    wait_all
    i=0
    while read -r active; do
        read -ra ids <<<"${tabs[$i]}"
        tui_id tab.focus tab_id "${ids[$active]}" >/dev/null &
        i=$((i + 1))
    done < <(jq -r '.spaces[].active' <<<"$plan")
    wait_all
    tui_id workspace.focus workspace_id "${workspaces[$(jq -r .focused <<<"$plan")]}" >/dev/null

    close_popup_workspace
}

if [[ "$to" == app ]]; then
    plan=$(read_tui)
    to_app
else
    plan=$(read_app)
    to_tui
fi
