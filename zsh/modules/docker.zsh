# ─────────────────────────────────────────────────────────────
# Docker Compose Helpers
# ─────────────────────────────────────────────────────────────

[[ -x $(command -v docker) ]] || return

_find_compose_file() {
    find . -type f \( -iname '*compose*.yaml' -o -iname '*compose*.yml' \) | fzf --select-1 --exit-0
}

_docker_compose() {
    local find_mode=0
    local compose_file=""
    local args=()

    # --find picks a compose file via fzf; -f passes through to docker compose
    for arg in "$@"; do
        [[ "$arg" == "--find" ]] && find_mode=1 || args+=("$arg")
    done

    if ((find_mode)); then
        compose_file=$(_find_compose_file)
        [[ -z "$compose_file" ]] && echo "No compose file selected" && return 1
        docker compose -f "$compose_file" "${args[@]}"
    else
        docker compose "${args[@]}"
    fi
}

# Basic aliases
dc() { _docker_compose "$@"; }
dcu() { _docker_compose up -d --build "$@"; }
dcd() { _docker_compose down "$@"; }
dcr() { dcd && dcu "$@"; }
dcD() { _docker_compose down -v "$@"; }
dcR() { dcD && dcu "$@"; }
ds() { docker ps "$@"; }
di() { docker images "$@"; }

drmi() {
    if [[ $# -gt 0 ]]; then
        docker rmi "$@"
        return
    fi

    local images
    images=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | fzf --multi --header-lines=1 --prompt="Select images to remove: " --header="Use TAB to select multiple, ENTER to confirm")

    [[ -z "$images" ]] && echo "No images selected" && return 1

    local image_ids
    image_ids=$(echo "$images" | awk '{print $3}')

    [[ -z "$image_ids" ]] && echo "No valid image IDs found" && return 1

    echo "Removing selected images..."
    echo "$image_ids" | xargs docker rmi
}
dprune() { docker system prune "$@"; }

# ─────────────────────────────────────────────────────────────
# Container FZF Picker
# ─────────────────────────────────────────────────────────────

_git_root() {
    git rev-parse --show-toplevel 2>/dev/null || echo "."
}

_get_compose_services() {
    local root=$(_git_root)
    local compose_file=""
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
        [[ -f "$root/$f" ]] && compose_file="$root/$f" && break
    done

    [[ -z "$compose_file" ]] && return 1
    command -v yq >/dev/null || return 1

    yq e '.services | keys | .[]' "$compose_file" 2>/dev/null
}

_filter_containers_by_services() {
    local services=("$@")
    docker ps -a --format '{{.Names}} {{.Status}}' | awk -v s="${services[*]}" '
        BEGIN { split(s, svc, " ") }
        {
            for (i in svc) {
                if (index($1, "_" svc[i] "_") || $1 == svc[i]) {
                    print
                    break
                }
            }
        }
    '
}

_select_container() {
    local services=()
    local container_list=""

    if services=($(_get_compose_services)); then
        container_list=$(_filter_containers_by_services "${services[@]}")
    fi

    [[ -z "$container_list" ]] && container_list=$(docker ps -a --format '{{.Names}} {{.Status}}')
    echo "$container_list" | fzf --select-1 --exit-0 | awk '{print $1}'
}

# ─────────────────────────────────────────────────────────────
# Docker Exec (into container)
# ─────────────────────────────────────────────────────────────

de() {
    local container
    [[ $# -gt 0 ]] && container="$1" && shift || container="$(_select_container)"
    [[ -z "$container" ]] && echo "No container selected" && return 1

    local cmd=(docker exec -it -e TERM=xterm-256color "$container")

    if (($#)); then
        if "${cmd[@]}" sh -c "command -v $1" &>/dev/null; then
            "${cmd[@]}" "$@"
        else
            echo "Command '$1' not found in container: $container"
            return 127
        fi
        return
    fi

    if "${cmd[@]}" sh -c 'command -v bash' &>/dev/null; then
        "${cmd[@]}" bash
    elif "${cmd[@]}" sh -c 'command -v sh' &>/dev/null; then
        "${cmd[@]}" sh
    else
        echo "No suitable shell found in container: $container"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────
# Docker Logs (interactive or static if not running)
# ─────────────────────────────────────────────────────────────

dl() {
    local query container=""

    if [[ $# -gt 0 ]]; then
        query="$1"
        shift
    fi

    if [[ -n "$query" ]]; then
        if docker ps -a --format '{{.Names}}' | grep -Fxq "$query"; then
            container="$query"
        else
            container=$(docker ps -a --format '{{.Names}} {{.Status}}' | fzf --query="$query" --select-1 --exit-0 | awk '{print $1}')
        fi
    else
        container="$(_select_container)"
    fi

    [[ -z "$container" ]] && echo "No container selected" && return 1

    # Force color; tools drop it when stdout is not a tty
    export CLICOLOR_FORCE=1

    if docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null | grep -q true; then
        docker logs -f --tail 1000 "$container" "$@" | _pipe_json_if_valid
    else
        echo "Container $container is not running — showing full logs"
        docker logs "$container" "$@" | _pipe_json_if_valid
    fi
}
