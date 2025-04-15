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
dcu() { _docker_compose up -d "$@"; }
dcd() { _docker_compose down "$@"; }
dcdu() { dcd && dcu "$@"; }
dcdv() { _docker_compose down -v "$@"; }
dcr() { dcd && dcu "$@"; }
dcR() { dcdv && dcu "$@"; }

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
    (($#)) && "${cmd[@]}" "$@" && return

    "${cmd[@]}" bash 2>/dev/null ||
        "${cmd[@]}" sh 2>/dev/null ||
        echo "No suitable shell found in container: $container"
}

# ─────────────────────────────────────────────────────────────
# Docker Logs (interactive or static if not running)
# ─────────────────────────────────────────────────────────────

_pipe_json_if_valid() {
    while IFS= read -r line; do
        # Strip leading timestamp if present
        content=$(echo "$line" | sed -E 's/^[0-9T:.Z-]+ //')
        
        # Check if the content is a JSON object
        if [[ "$content" =~ ^\{.*\}$ ]]; then
            # Test if it's valid JSON and pretty print with color
            if echo "$content" | jq empty &>/dev/null 2>&1; then
                # Use bat for syntax highlighting if available
                if command -v bat &>/dev/null; then
                    echo "$content" | jq . | bat --color=always --language=json --style=plain
                else
                    echo "$content" | jq .
                fi
                continue
            fi
        fi
        
        # Otherwise, print the original line
        echo "$line"
    done
}

# Modified dl function with color support
dl() {
    local container="$(_select_container)"
    [[ -z "$container" ]] && echo "No container selected" && return 1

    # Set environment variable to ensure color output
    export CLICOLOR_FORCE=1
    
    if docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null | grep -q true; then
        docker logs -f --tail 1000 "$container" "$@" | _pipe_json_if_valid
    else
        echo "Container $container is not running — showing full logs"
        docker logs "$container" "$@" | _pipe_json_if_valid
    fi
}
