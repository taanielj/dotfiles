# Aliases configuration
if command -v nvim &>/dev/null; then
    alias vim=nvim
fi
if command -v bat &>/dev/null; then
    alias cat="bat -p --paging=never"
elif command -v batcat &>/dev/null; then
    alias cat="batcat -p --paging=never"
else
    alias cat="cat"
fi

if command -v fd &>/dev/null; then
    alias fd="fd"
elif command -v fdfind &>/dev/null; then
    alias fd="fdfind"
else
    alias fd="find"
fi

# exa is nolonger maintained, using eza instead, a maintained fork
if command -v eza &>/dev/null; then
    alias l="eza"

    # Function to wrap eza while correctly handling -l and -a flags
    _eza_wrapper() {
        local args=("$@")

        # If invoked as 'la', force -l -a
        if [[ "${FUNCNAME[1]}" == "la" ]]; then
            set -- -l -a "${args[@]}"
        fi

        eza --group-directories-first --icons --color=always --git -h "$@"
    }
    # Use aliases to redirect to the wrapper function
    alias ls="_eza_wrapper"
    alias la="_eza_wrapper -l -a"
    alias tree="eza --tree"
else
    alias l="ls"
    alias ls="ls --color=auto"
    alias la="ls -la --color=auto"
    alias tree="tree"
fi

# docker compose aliases
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcdu="docker compose down && docker compose up -d"
alias dcdv="docker compose down -v"
alias dcr="docker compose run --rm"
alias dcrs="docker compose down && docker compose up -d"

de() {
    local container
    [ $# -gt 0 ] && container="$1" && shift
    container=$(docker ps --format '{{.Names}}' | grep -i "${container:-}" | fzf --select-1 --exit-0)

    [[ -z "$container" ]] && echo "No container selected" && return 1

    local cmd=(docker exec -it -e TERM=xterm-256color "$container")

    [ $# -gt 0 ] && "${cmd[@]}" "$@" && return
    s
    "${cmd[@]}" bash 2>/dev/null ||
        "${cmd[@]}" sh 2>/dev/null ||
        echo "No suitable shell found in container: $container"
    }

    alias cl="clear && printf '\e[3J'"

# ----------------------------
# Basic Aliases
# ----------------------------

alias k="kubectl"
alias kx="kubectl exec -it --stdin --tty"
alias s="stern"

# ----------------------------
# Context and Namespace Selectors
# ----------------------------

kc() {
    local context="$1"
    if [ -z "$context" ]; then
        context=$(kubectl config get-contexts -o name | fzf)
    fi
    [ -n "$context" ] && kubectl config use-context "$context"
}

kn() {
    local namespace="$1"
    if [ -z "$(kubectl config current-context 2>/dev/null)" ]; then
        kc
    fi
    if [ -z "$namespace" ]; then
        namespace=$(kubectl get namespaces -o name | fzf | cut -d'/' -f2)
    fi
    [ -n "$namespace" ] && kubectl config set-context --current --namespace "$namespace"
}

kcn() {
    kc "$1"
    kn "$2"
}

kcnp() {
    kc "$1"
    kn "$2"
    kp
}

kcl() {
    kubectl config unset current-context
    kubectl config unset contexts
    kubectl config unset users
    kubectl config unset clusters
}

# ----------------------------
# Pod Utils (context-aware)
# ----------------------------

kp() {
    local all="$1"

    # If passed --all or -a, re-select context and namespace
    if [[ "$all" == "--all" || "$all" == "-a" ]]; then
        kcn
        shift
    fi

    # Ensure context is set
    if [ -z "$(kubectl config current-context 2>/dev/null)" ]; then
        kc
    fi

    # Ensure namespace is set
    if [ -z "$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)" ]; then
        kn
    fi

    kubectl get pods "$@"
}

kd() {
    kp >/dev/null
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [ -n "$pod" ] && kubectl describe pod "$pod"
}

kl() {
    kp >/dev/null
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [ -n "$pod" ] && kubectl logs "$pod" -f
}

kauth() {
    local verb="$1"
    local resource="$2"
    [ -z "$verb" ] && read -p "Verb (e.g. get): " verb
    [ -z "$resource" ] && read -p "Resource (e.g. pods): " resource
    kubectl auth can-i "$verb" "$resource" --as self
}

# ----------------------------
# Exec with fuzzy pod/container pick
# ----------------------------

kxe() {
    kp >/dev/null

    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [ -z "$pod" ] && return

    local container=$(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n' | fzf)
    [ -z "$container" ] && return

    local original_context=$(kubectl config current-context)
    local original_namespace=$(kubectl config view --minify -o jsonpath='{..namespace}')

    local admin_context="$original_context"
    if [[ "$original_context" != *"-admin" ]]; then
        admin_context="${original_context}-admin"
        kubectl config use-context "$admin_context" >/dev/null
        kubectl config set-context --current --namespace "$original_namespace" >/dev/null
    fi

    kubectl exec -it "$pod" -c "$container" -- bash ||
        kubectl exec -it "$pod" -c "$container" -- sh

    # Restore original context and namespace if switched
    if [[ "$original_context" != *"-admin" ]]; then
        kubectl config use-context "$original_context" >/dev/null
        kubectl config set-context --current --namespace "$original_namespace" >/dev/null
    fi
}

# ----------------------------
# Stern (log tailing) with helpers
# ----------------------------

sp() {
    local context="$(kubectl config current-context 2>/dev/null)"
    if [ -z "$context" ]; then
        context=$(kubectl config get-contexts -o name | fzf)
        [ -n "$context" ] && kubectl config use-context "$context"
    fi
    local namespace="$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)"
    if [ -z "$namespace" ]; then
        namespace=$(kubectl get namespaces -o name | fzf | cut -d'/' -f2)
        [ -n "$namespace" ] && kubectl config set-context --current --namespace "$namespace"
    fi
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [ -n "$pod" ] && stern --context "$context" --namespace "$namespace" "$pod"
}

sl() {
    kp >/dev/null
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [ -n "$pod" ] && stern "$pod"
}

slg() {
    kp >/dev/null
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [ -z "$pod" ] && return
    read -rp "Search term (ripgrep): " pattern
    stern "$pod" | rg --color=always "$pattern"
}

slog() {
    kp >/dev/null
    local deployment=$(kubectl get deploy -o name | fzf | cut -d'/' -f2)
    [ -n "$deployment" ] && stern "$deployment"
}

slogg() {
    kp >/dev/null
    local deployment=$(kubectl get deploy -o name | fzf | cut -d'/' -f2)
    [ -z "$deployment" ] && return
    read -rp "Search term (ripgrep): " pattern
    stern "$deployment" | rg --color=always "$pattern"
}

spg() {
    kp >/dev/null
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [ -z "$pod" ] && return
    read -rp "Search term (ripgrep): " pattern
    stern "$pod" | rg --color=always "$pattern"
}

sselect() {
    kp >/dev/null
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [ -z "$pod" ] && return
    local container=$(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n' | fzf)
    [ -z "$container" ] && return
    read -rp "Pattern to grep: " pattern
    stern "$pod" -c "$container" | rg --color=always "$pattern"
}

# ----------------------------
# FZF Defaults (recommended)
# ----------------------------

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# TMUX sessions
default_sessions=(
    "notes"
    "shell"
)
# if macOS append zqa and zendesk to default sessions
if [[ "$OSTYPE" == "darwin"* ]]; then
    default_sessions+=(
    "zqa"
    "zendesk"
)
fi

default_sessions=(
    "zqa"
    "zendesk"
    "shell"
    "notes"
)

# Helper: Start all sessions if not already started
start_all_sessions() {
    for session in "${default_sessions[@]}"; do
        if ! tmux has-session -t "$session" 2>/dev/null; then
            [[ "$OSTYPE" != "darwin"* && "$session" =~ ^(zqa|zendesk)$ ]] && continue
            tmux new-session -d -s "$session"
        fi
    done
}

# Main entry: attach to first available session (default: notes)
ts() {
    start_all_sessions

    for session in "${default_sessions[@]}"; do
        if ! tmux list-clients -t "$session" 2>/dev/null | grep -q '^'; then
            tmux attach-session -t "$session"
            return
        fi
    done

    echo "You have shells attached to all sessions."
    return 1
}

# Attach helpers
tsn() {
    start_all_sessions
    tmux attach-session -t notes
}

tss() {
    start_all_sessions
    tmux attach-session -t shell
}

tsz() {
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "🧘 Relax, you're not at work (not on macOS)."
        return 0
    fi
    start_all_sessions
    tmux attach-session -t zendesk
}

tsq() {
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "🧘 Relax, you're not at work (not on macOS)."
        return 0
    fi
    start_all_sessions
    tmux attach-session -t zqa
}
