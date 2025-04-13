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

alias x="exit"

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



alias cl="clear && printf '\e[3J'"
alias cle="clear && printf '\e[3J' && exec zsh"




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
