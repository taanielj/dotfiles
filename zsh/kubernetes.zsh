# ----------------------------
# Basic Aliases
# ----------------------------

[[ -z "$(command -v kubectl)" ]] && return

alias k="kubectl"                                                    # kubectl shorthand
ka() { kubectl --as admin --as-group system:masters "$@"; }        # kubectl with admin privileges
source <(kubectl completion zsh)                                   # enable kubectl completion
compdef _kubectl k                                                 # enable completion for k alias

# ----------------------------
# Context and Namespace Selectors
# ----------------------------

kc() {                                                              # switch context (with fzf if no arg)
    local context="$1"
    if [ -z "$context" ]; then
        context=$(kubectl config get-contexts -o name | fzf)
    fi
    [ -n "$context" ] && kubectl config use-context "$context"
}

kn() {                                                              # switch namespace (with fzf if no arg)
    local namespace="$1"
    if [ -z "$(kubectl config current-context 2>/dev/null)" ]; then
        kc
    fi
    if [ -z "$namespace" ]; then
        namespace=$(kubectl get namespaces -o name | fzf | cut -d'/' -f2)
    fi
    [ -n "$namespace" ] && kubectl config set-context --current --namespace "$namespace"
}

kcn() {                                                             # switch context and namespace
    kc "$1"
    kn "$2"
}

kcnp() {                                                            # switch context, namespace, show pods
    kc "$1"
    kn "$2"
    kp
}

kcl() {                                                             # clear all kubectl config
    kubectl config unset current-context
    kubectl config unset contexts
    kubectl config unset users
    kubectl config unset clusters
}

# ----------------------------
# Pod Utils (context-aware)
# ----------------------------

kp() {                                                              # list pods (context-aware)
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

kd() {                                                              # describe pod (with fzf selection)
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

kl() {                                                              # tail pod logs (with fzf selection)
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



kauth() {                                                           # check kubernetes permissions
    local verb="$1"
    local resource="$2"
    [ -z "$verb" ] && read -p "Verb (e.g. get): " verb
    [ -z "$resource" ] && read -p "Resource (e.g. pods): " resource
    kubectl auth can-i "$verb" "$resource" --as self
}

# ----------------------------
# Exec with fuzzy pod/container pick
# ----------------------------

kxe() {                                                             # exec into pod with admin (fzf selection)
    kp >/dev/null || return

    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -z "$pod" ]] && echo "No pod selected" && return 1

    local container=$(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n' | fzf)
    [[ -z "$container" ]] && echo "No container selected" && return 1

    # Try bash first, then sh
    kubectl exec -it "$pod" -c "$container" --as admin --as-group system:masters -- bash || \
        kubectl exec -it "$pod" -c "$container" --as admin --as-group system:masters -- sh
}

# ----------------------------
# Stern (log tailing) with helpers
# ----------------------------
[[ -z "$(command -v stern)" ]] && return

s() {                                                               # stern logs (with fzf if no args)
    if [[ $# -gt 0 ]]; then
        stern "$@"
        return
    fi

    kp >/dev/null || return
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -n "$pod" ]] && stern "$pod"
}

sj() {                                                              # stern logs with pretty JSON output
    if [[ $# -gt 0 ]]; then
        stern --output ppextjson "$@"
        return
    fi

    kp >/dev/null || return
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -n "$pod" ]] && stern --output ppextjson "$pod"
}

sg() {                                                              # stern logs with grep pattern
    kp >/dev/null || return
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -z "$pod" ]] && return
    read -rp "Search pattern: " pattern
    stern "$pod" | rg --color=always "$pattern"
}

sd() {                                                              # stern logs for deployment
    kp >/dev/null || return
    local deployment=$(kubectl get deploy -o name | fzf | cut -d'/' -f2)
    [[ -n "$deployment" ]] && stern "$deployment"
}

sc() {                                                              # stern logs with container selection
    kp >/dev/null || return
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -z "$pod" ]] && return
    local container=$(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n' | fzf)
    [[ -z "$container" ]] && return
    stern "$pod" -c "$container"
}
