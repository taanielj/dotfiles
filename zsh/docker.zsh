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

    for arg in "$@"; do
        [[ "$arg" == "-f" || "$arg" == "--find" ]] && find_mode=1 || args+=("$arg")
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
dcdu() { dcd && dcu "$@"; }
dcD() { _docker_compose down -v "$@"; }
dcDu() { dcD && dcu "$@"; }
dcr() { dcd && dcu "$@"; }
dcR() { dcD && dcu "$@"; }

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

    # If additional arguments are passed, try to validate the command exists first
    if (($#)); then
        if "${cmd[@]}" sh -c "command -v $1" &>/dev/null; then
            "${cmd[@]}" "$@"
        else
            echo "Command '$1' not found in container: $container"
            return 127
        fi
        return
    fi

    # Interactive shell fallback, preferring bash
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

_pipe_json_if_valid() {
    while IFS= read -r line; do
        # Strip leading timestamp if present (ISO 8601 + space)
        content="${line##+([0-9T:.Z-]) }"

        # Fast path: skip lines that don't look like JSON objects
        [[ "$content" =~ ^\{.*\}$ ]] || { echo "$line"; continue; }

        # Try to parse with jq
        if parsed=$(echo "$content" | jq . 2>/dev/null); then
            if command -v bat &>/dev/null; then
                echo "$parsed" | bat --color=always --language=json --style=plain --paging=never
            else
                echo "$parsed"
            fi
        else
            # Fallback: print original if jq fails
            echo "$line"
        fi
    done
}

dl() {
    local query="$1"
    shift || true

    local container=""
    if [[ -n "$query" ]]; then
        # Try to find exact match first
        if docker ps -a --format '{{.Names}}' | grep -Fxq "$query"; then
            container="$query"
        else
            # Fuzzy search with pre-filled input
            container=$(docker ps -a --format '{{.Names}} {{.Status}}' | fzf --query="$query" --select-1 --exit-0 | awk '{print $1}')
        fi
    else
        container="$(_select_container)"
    fi

    [[ -z "$container" ]] && echo "No container selected" && return 1

    # Always force color, just in case
    export CLICOLOR_FORCE=1

    if docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null | grep -q true; then
        docker logs -f --tail 1000 "$container" "$@" | _pipe_json_if_valid
    else
        echo "Container $container is not running — showing full logs"
        docker logs "$container" "$@" | _pipe_json_if_valid
    fi
}
