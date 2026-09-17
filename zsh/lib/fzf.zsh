# _choose <what> [fzf args]
# Reads candidates on stdin and prints the fzf pick.
_choose() {
    local what=$1 pick; shift
    pick=$(fzf --preview-window=down:60%:wrap "$@") && [[ -n "$pick" ]] && { print -r -- "$pick"; return }
    echo "No $what selected" >&2
    return 1
}

# _log_preview <command>
# Prints an fzf --preview string that runs the command and colours it as a log.
_log_preview() {
    local cmd="$1 2>&1"
    command -v bat &>/dev/null && cmd+=" | bat -p -l log --color=always"
    print -r -- "$cmd"
}
