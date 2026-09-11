[[ -z "$(command -v kubectl)" ]] && return

alias k="kubectl"
ka() { kubectl --as admin --as-group system:masters "$@"; }

# kubectl completion is slow to generate - cache until the binary changes
if [[ -o interactive ]]; then
    _kubectl_comp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/kubectl-completion.zsh"
    if [[ ! -s "$_kubectl_comp" || "${commands[kubectl]}" -nt "$_kubectl_comp" ]]; then
        mkdir -p "${_kubectl_comp:h}"
        kubectl completion zsh >| "$_kubectl_comp"
    fi
    source "$_kubectl_comp"
    compdef _kubectl k
    unset _kubectl_comp
fi

kc() {
    local context="$1"
    if [ -z "$context" ]; then
        context=$(kubectl config get-contexts -o name | fzf)
    else
        if ! kubectl config use-context "$context" 2>/dev/null; then
            context=$(kubectl config get-contexts -o name | fzf --query="$context")
        else
            return 0
        fi
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
    else
        if ! kubectl config set-context --current --namespace "$namespace" 2>/dev/null; then
            namespace=$(kubectl get namespaces -o name | fzf --query="$namespace" | cut -d'/' -f2)
        else
            return 0
        fi
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

kp() {
    local all="$1"

    if [[ "$all" == "--all" || "$all" == "-a" ]]; then
        kcn
        shift
    fi

    if [ -z "$(kubectl config current-context 2>/dev/null)" ]; then
        kc
    fi

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
    kp >/dev/null || return

    local query pod
    if [[ $# -gt 0 ]]; then
        query="$1"
        shift

        local matches
        matches=$(kubectl get pods -o name | grep "$query" || true)

        if [[ -n "$matches" && $(echo "$matches" | wc -l) -eq 1 ]]; then
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
    [ -z "$verb" ] && read "verb?Verb (e.g. get): "
    [ -z "$resource" ] && read "resource?Resource (e.g. pods): "
    kubectl auth can-i "$verb" "$resource" --as self
}

kxe() {
    kp >/dev/null || return

    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -z "$pod" ]] && echo "No pod selected" && return 1

    local container=$(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n' | fzf)
    [[ -z "$container" ]] && echo "No container selected" && return 1

    kubectl exec -it "$pod" -c "$container" --as admin --as-group system:masters -- \
        sh -c 'command -v bash >/dev/null && exec bash || exec sh'
}

[[ -z "$(command -v stern)" ]] && return

s() {
    if [[ $# -gt 0 ]]; then
        stern "$@"
        return
    fi

    kp >/dev/null || return
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -n "$pod" ]] && stern "$pod"
}

sj() {
    if [[ $# -gt 0 ]]; then
        stern --output ppextjson "$@"
        return
    fi

    kp >/dev/null || return
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -n "$pod" ]] && stern --output ppextjson "$pod"
}

sg() {
    kp >/dev/null || return
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -z "$pod" ]] && return
    local pattern
    read -r "pattern?Search pattern: "
    stern "$pod" | rg --color=always "$pattern"
}

sd() {
    kp >/dev/null || return
    local deployment=$(kubectl get deploy -o name | fzf | cut -d'/' -f2)
    [[ -n "$deployment" ]] && stern "$deployment"
}

sc() {
    kp >/dev/null || return
    local pod=$(kubectl get pods -o name | fzf | cut -d'/' -f2)
    [[ -z "$pod" ]] && return
    local container=$(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n' | fzf)
    [[ -z "$container" ]] && return
    stern "$pod" -c "$container"
}
