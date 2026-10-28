# Sources the output of a slow init command such as `brew shellenv`, cached
# until the command's binary is newer than the cache. Only for commands whose
# output doesn't depend on the environment it runs in.
source_cached() {
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/${(j:-:)${@:t}}.zsh"
    if [[ ! -s $cache || ${commands[$1]:-$1} -nt $cache ]]; then
        mkdir -p "${cache:h}"
        "$@" >| "$cache"
    fi
    source "$cache"
}
