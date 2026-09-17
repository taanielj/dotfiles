# _choose <what> [fzf args]
# Reads candidates on stdin and prints the fzf pick.
_choose() {
    local what=$1 pick; shift
    pick=$(fzf "$@") && [[ -n "$pick" ]] && { print -r -- "$pick"; return }
    echo "No $what selected" >&2
    return 1
}
