command -v docker &>/dev/null || return

_compose_file() {
    find . -type f \( -iname '*compose*.yaml' -o -iname '*compose*.yml' \) |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" _choose "compose file" --select-1 --exit-0
}

# --find picks the compose file in fzf; everything else passes through
_docker_compose() {
    local file args=("${(@)@:#--find}")
    (( $#args == $# )) && { docker compose "$@"; return }
    file=$(_compose_file) || return
    docker compose -f "$file" "${args[@]}"
}

dc() { _docker_compose "$@"; }
dcu() { _docker_compose up -d --build "$@"; }
dcd() { _docker_compose down "$@"; }
dcr() { dcd && dcu "$@"; }
dcD() { _docker_compose down -v "$@"; }
dcR() { dcD && dcu "$@"; }
alias ds="docker ps"
alias di="docker images"
alias dprune="docker system prune"

drmi() {
    (( $# )) && { docker rmi "$@"; return }
    setopt localoptions pipefail
    local ids
    ids=$(docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}' |
        _choose image --multi --header-lines=1 --prompt="Remove images: " | awk '{print $3}') || return
    docker rmi ${=ids}
}

_compose_services() {
    command -v yq &>/dev/null || return
    local root file
    root=$(git rev-parse --show-toplevel 2>/dev/null) || root=.
    for file in "$root"/{docker-,}compose.{yml,yaml}; do
        [[ -f "$file" ]] || continue
        yq e '.services | keys | .[]' "$file" 2>/dev/null
        return
    done
    return 1
}

# Lists "name status" for every container, this repo's compose services first.
_containers() {
    local all services pattern
    all=$(docker ps -a --format '{{.Names}} {{.Status}}')
    services=(${(f)"$(_compose_services)"})
    (( $#services )) || { print -r -- "$all"; return }
    pattern="^([^ ]*[-_])?(${(j:|:)services})([-_][^ ]*)? "
    print -r -- "$all" | grep -E "$pattern"
    print -r -- "$all" | grep -Ev "$pattern"
}

_pick_container() {
    local pick
    pick=$(_containers | _choose container --preview "$(_log_preview 'docker logs --tail 40 {1}')" "$@") || return
    print -r -- "${pick%% *}"
}

# de [container] [command]
de() {
    local container
    if (( $# )); then
        container=$1; shift
    else
        container=$(_pick_container) || return
    fi
    local exec=(docker exec -it -e TERM=xterm-256color "$container")
    (( $# )) && { "${exec[@]}" "$@"; return }
    "${exec[@]}" sh -c 'command -v bash >/dev/null && exec bash || exec sh'
}

# dl [container-substring] [docker logs args]
dl() {
    local container=$1
    if ! docker container inspect "$container" &>/dev/null; then
        container=$(_pick_container --exact --select-1 --exit-0 ${1:+--query="$1"}) || return
    fi
    (( $# )) && shift
    if [[ $(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null) == true ]]; then
        jsonl docker logs -f --tail 1000 "$container" "$@"
    else
        echo "$container is not running, showing full logs" >&2
        jsonl docker logs "$container" "$@"
    fi
}
