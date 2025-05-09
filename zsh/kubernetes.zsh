# ----------------------------
# Basic Aliases
# ----------------------------

[[ -z "$(command -v kubectl)" ]] && return

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

kl() {
    kp >/dev/null || return

    local query pod
    if [[ $# -gt 0 ]]; then
        query="$1"
        shift

        local matches
        matches=$(kubectl get pods -o name | grep "$query" || true)

        if [[ $(echo "$matches" | wc -l) -eq 1 ]]; then
            pod=$(echo "$matches" | cut -d'/' -f2)
        else
            pod=$(kubectl get pods -o name | fzf --query="$query" --select-1 --exit-0 | cut -d'/' -f2)
        fi
    else
        pod=$(kubectl get pods -o name | fzf --select-1 --exit-0 | cut -d'/' -f2)
    fi

    [[ -z "$pod" ]] && echo "No pod selected" && return 1

    kubectl logs "$pod" -f "$@" | _pipe_json_if_valid
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
[[ -z "$(command -v stern)" ]] && return
alias s="stern"
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
