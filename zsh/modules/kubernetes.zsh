command -v kubectl &>/dev/null || return

alias k="kubectl"
ka() { kubectl --as admin --as-group system:masters "$@"; }

# kubectl completion is slow to generate - cache until the binary changes
_kubectl_comp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/kubectl-completion.zsh"
if [[ ! -s "$_kubectl_comp" || "${commands[kubectl]}" -nt "$_kubectl_comp" ]]; then
    mkdir -p "${_kubectl_comp:h}"
    kubectl completion zsh >| "$_kubectl_comp"
fi
source "$_kubectl_comp"
compdef _kubectl k
unset _kubectl_comp

# Reads names on stdin and prints the fzf pick.
_k8s_choose() {
    local what=$1 name; shift
    name=$(fzf "$@") && [[ -n "$name" ]] && { print -r -- "$name"; return }
    echo "No $what selected" >&2
    return 1
}

# Applies $target directly when kubectl accepts it, else picks one from the list seeded with it.
_k8s_use() {
    local apply=$1 list=$2 target=$3
    [[ -n "$target" ]] && ${=apply} "$target" 2>/dev/null && return
    target=$(${=list} | _k8s_choose "${list##* }" ${target:+--query="$target"}) || return
    ${=apply} "$target"
}

_k8s_names() { kubectl get "$@" -o custom-columns=:metadata.name --no-headers }

_k8s_ensure_context() {
    [[ -n "$(kubectl config current-context 2>/dev/null)" ]] || kc || return
    [[ -n "$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)" ]] || kn
}

# _k8s_pick <resource> [fzf args]
_k8s_pick() {
    local resource=$1; shift
    _k8s_ensure_context || return
    _k8s_names "$resource" | _k8s_choose "$resource" "$@"
}

_k8s_pick_container() {
    kubectl get pod "$1" -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n' | _k8s_choose container
}

kc() { _k8s_use "kubectl config use-context" "kubectl config get-contexts -o name" "$1" }

kn() {
    [[ -n "$(kubectl config current-context 2>/dev/null)" ]] || kc || return
    _k8s_use "kubectl config set-context --current --namespace" "_k8s_names namespaces" "$1"
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
    if [[ "$1" == "--all" || "$1" == "-a" ]]; then
        kcn
        shift
    fi
    _k8s_ensure_context || return
    kubectl get pods "$@"
}

kd() {
    local pod
    pod=$(_k8s_pick pod) || return
    kubectl describe pod "$pod"
}

# kl [pod-substring] [kubectl logs args]
kl() {
    local pod query
    (( $# )) && { query=$1; shift }
    pod=$(_k8s_pick pod --exact --select-1 --exit-0 ${query:+--query="$query"}) || return
    kubectl logs "$pod" -f "$@" | jsonl
}

kauth() {
    local verb="$1"
    local resource="$2"
    [[ -z "$verb" ]] && read "verb?Verb (e.g. get): "
    [[ -z "$resource" ]] && read "resource?Resource (e.g. pods): "
    kubectl auth can-i "$verb" "$resource" --as self
}

kxe() {
    local pod container
    pod=$(_k8s_pick pod) || return
    container=$(_k8s_pick_container "$pod") || return
    kubectl exec -it "$pod" -c "$container" --as admin --as-group system:masters -- \
        sh -c 'command -v bash >/dev/null && exec bash || exec sh'
}

command -v stern &>/dev/null || return

s() {
    local pod
    (( $# )) || pod=$(_k8s_pick pod) || return
    stern "${@:-$pod}"
}

sj() {
    local pod
    (( $# )) || pod=$(_k8s_pick pod) || return
    stern --output ppextjson "${@:-$pod}"
}

sg() {
    local pod pattern
    pod=$(_k8s_pick pod) || return
    read -r "pattern?Search pattern: "
    stern "$pod" | rg --color=always "$pattern"
}

sd() {
    local deployment
    deployment=$(_k8s_pick deployment) || return
    stern "$deployment"
}

sc() {
    local pod container
    pod=$(_k8s_pick pod) || return
    container=$(_k8s_pick_container "$pod") || return
    stern "$pod" -c "$container"
}
