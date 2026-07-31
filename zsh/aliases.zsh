# Aliases configurationalias
#
# Interactive-only guard: these are conveniences for a human at the keyboard
# (eza/bat/tree wrappers, etc). Sourcing them into non-interactive shells
# (scripts, hooks, tooling) caused partially-applied aliases and cache issues,
# so bail out early unless we're interactive.
GIT_PATH="$HOME/git"
[[ -o interactive ]] || return

if command -v nvim &>/dev/null; then
    alias vim=nvim
fi
if command -v bat &>/dev/null; then
    alias cat="bat -p --paging=never"
elif command -v batcat &>/dev/null; then
    alias cat="batcat -p --paging=never"
fi

if command -v fd &>/dev/null; then
    alias fd="fd"
elif command -v fdfind &>/dev/null; then
    alias fd="fdfind"
else
    alias fd="find"
fi

alias x="exit"
envload() {
    if [[ ! -f .env ]]; then
        echo "No .env file in $(pwd)"
        return 1
    fi
    local vars=($(grep -v '^#' .env | grep -v '^\s*$' | xargs))
    export "${vars[@]}"
    echo "Loaded ${#vars[@]} var(s) from .env"
}

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
alias cld="cd && clear && printf '\e[3J' && exec zsh"

# TMUX sessions. Work sessions register from the notes repo (overlay in
# zshrc.zsh), keeping this file free of work-specific config.
typeset -ga default_sessions=()
typeset -gA _tmux_session_builders=()

register_tmux_session() {
    default_sessions+=("$1")
    _tmux_session_builders[$1]="$2"
}

# Helper: Create tmux session with optional directory
_tmux_new_session_maybe_dir() {
    local session="$1"
    local window_name="$2"
    local dir="$3"

    if [[ -n "$dir" && -d "$dir" ]]; then
        tmux new-session -d -s "$session" -n "$window_name" -c "$dir"
    else
        tmux new-session -d -s "$session" -n "$window_name"
    fi
}

# Helper: Create tmux window with optional directory
_tmux_new_window_maybe_dir() {
    local session="$1"
    local window_name="$2"
    local dir="$3"

    # Trailing colon forces a session target, even when a window shares the name.
    if [[ -n "$dir" && -d "$dir" ]]; then
        tmux new-window -t "${session}:" -n "$window_name" -c "$dir"
    else
        tmux new-window -t "${session}:" -n "$window_name"
    fi
}

_tmux_build_notes() {
    _tmux_new_session_maybe_dir notes notes "${GIT_PATH}/notes"
    _tmux_new_window_maybe_dir notes dotfiles "${GIT_PATH}/dotfiles"
}
_tmux_build_shell() {
    tmux new-session -d -s shell
}
register_tmux_session notes _tmux_build_notes
register_tmux_session shell _tmux_build_shell

_start_all_sessions() {
    local session builder
    for session in "${default_sessions[@]}"; do
        tmux has-session -t "$session" 2>/dev/null && continue
        builder="${_tmux_session_builders[$session]}"
        [[ -n "$builder" ]] && "$builder"
    done
}

# Main entry: attach to first available session (default: notes)
ts() {
    _start_all_sessions

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
    _start_all_sessions
    tmux attach-session -t notes
}

tss() {
    _start_all_sessions
    tmux attach-session -t shell
}

# Reset the current git repository
reset_repo() {
    echo -e "\033[1;33mWARNING: This will DELETE and RECLONE the repo!\033[0m"

    # Get root of the repo (ensures we operate from the correct directory)
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$REPO_ROOT" ]]; then
        echo -e "\033[1;31mError: Not in a git repository. Please navigate to a git repo and try again.\033[0m"
        return 1
    fi
    cd "$REPO_ROOT" || return 1 # Move to repo root
    # Get the repo name from git remote
    GIT_REMOTE=$(git remote get-url origin 2>/dev/null)
    if [[ -z "$GIT_REMOTE" ]]; then
        echo -e "\033[1;31mError: No remote repository found. Are you in a git repo?\033[0m"
        return 1
    fi

    echo -e "Root Repo Path: \033[1;34m$REPO_ROOT\033[0m"
    echo -e "Git Remote: \033[1;34m$GIT_REMOTE\033[0m"
    echo -e "New Clone Path: \033[1;34m$REPO_ROOT/\033[0m"

    # 🚨 Prevent execution if there are uncommitted changes
    if [[ -n "$(git status --porcelain)" ]]; then
        echo -e "\033[1;31mError: You have uncommitted changes. Commit or discard them before proceeding.\033[0m"
        git status --short
        return 1
    fi

    # 🚨 Prevent execution if there are stashed changes
    if [[ -n "$(git stash list)" ]]; then
        echo -e "\033[1;31mError: You have stashed changes. Apply or drop them before proceeding.\033[0m"
        git stash list
        return 1
    fi

    # Confirm action (zsh-compatible)
    echo -n "Type YES to confirm: "
    read CONFIRM
    if [[ "$CONFIRM" != "YES" ]]; then
        echo -e "\033[1;31mOperation cancelled.\033[0m"
        return 1
    fi

    echo -e "\033[1;33mDeleting and recloning into: $REPO_ROOT\033[0m"

    # Delete old repo and reclone
    cd $REPO_ROOT && cd .. || return 1
    rm -rf "$REPO_ROOT" || return 1
    git clone "$GIT_REMOTE" "$REPO_ROOT" || return 1
    cd "$REPO_ROOT" || return 1

    echo -e "\033[1;32mRepository reset complete.\033[0m"
}

# Neovim
nvim() {
    # set term to xterm-kitty just for nvim, for better blinking cursor support
    [[ "$TERM_PROGRAM" == "kitty" ]] && export TERM="xterm-kitty"
    [[ $# -ne 0 ]] && command nvim "$@" && return

    local venv_path=$(__resolve_venv_path)
    [[ -z $venv_path || ! -f "$venv_path/bin/activate" ]] && command nvim && return

    source "$venv_path/bin/activate"
    command nvim
}

nvimf() {
    if [[ "$1" != "" && -d -$1 ]]; then
        nvim $(fd . $1 | fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}')]
    else
        nvim $(fd --type f --hidden | fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}')
    fi
}

# Git file history log
alias gflog='git log --follow --stat --date=format:'%Y-%m-%d' --pretty=format:"%C(yellow)%h%Creset %C(cyan)%cd%Creset %s %C(auto)%d%Creset%n" --'

if command -v claude &>/dev/null; then
    alias clask='claude -p'
    clmd() {
        claude -p --model haiku "Output ONLY a single bash command, no explanation, no markdown, no backticks. Task: $*" | pbcopy
        echo "copied"
    }
fi

agyr() {
    if ! command -v fzf &>/dev/null; then
        echo "Error: fzf is not installed." >&2
        return 1
    fi

    local brain_dir="$HOME/.gemini/antigravity-cli/brain"
    if [[ ! -d "$brain_dir" ]]; then
        echo "Error: Directory $brain_dir does not exist." >&2
        return 1
    fi

    local files=$(grep -l "$PWD" "$brain_dir"/*/.system_generated/logs/transcript.jsonl 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "No conversations found for $PWD."
        return 0
    fi

    local options=""
    for file in ${(f)files}; do
        local uuid=$(echo "$file" | awk -F'/' '{print $7}')
        local date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file")
        options+="$date | $uuid\n"
    done

    local selected=$(echo -e "$options" | awk 'NF' | fzf --prompt="Select conversation to resume: ")

    if [[ -n "$selected" ]]; then
        local selected_uuid=$(echo "$selected" | awk -F'|' '{print $2}' | xargs)
        echo "Resuming $selected_uuid..."
        agy --conversation "$selected_uuid"
    fi
}
