# Aliases configuration
if command -v nvim &>/dev/null; then
    alias vim=nvim
fi
# Only alias cat to bat in interactive shells to avoid cache issues in scripts/hooks
if [[ -o interactive ]]; then
    if command -v bat &>/dev/null; then
        alias cat="bat -p --paging=never"
    elif command -v batcat &>/dev/null; then
        alias cat="batcat -p --paging=never"
    fi
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
    # Use aliases to redirect to the wrapper function (only when interactive)
    if [[ -o interactive ]]; then
        alias ls="_eza_wrapper"
    fi
    alias la="_eza_wrapper -l -a"
    alias tree="eza --tree"
else
    alias l="ls"
    if [[ -o interactive ]]; then
        alias ls="ls --color=auto"
    fi
    alias la="ls -la --color=auto"
    alias tree="tree"
fi

alias cl="clear && printf '\e[3J'"
alias cle="clear && printf '\e[3J' && exec zsh"
alias cld="cd && clear && printf '\e[3J' && exec zsh"

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

    if [[ -n "$dir" && -d "$dir" ]]; then
        tmux new-window -t "$session" -n "$window_name" -c "$dir"
    else
        tmux new-window -t "$session" -n "$window_name"
    fi
}

# Helper: Start all sessions if not already started
_start_all_sessions() {
    for session in "${default_sessions[@]}"; do
        if ! tmux has-session -t "$session" 2>/dev/null; then
            [[ "$OSTYPE" != "darwin"* && "$session" =~ ^(zqa|zendesk)$ ]] && continue

            case "$session" in
                zendesk)
                    # Skip if ZENDESK_CODE_DIR is not set
                    [[ -z "$ZENDESK_CODE_DIR" ]] && continue

                    _tmux_new_session_maybe_dir zendesk zig "${ZENDESK_CODE_DIR}/zendesk-identity-governance"
                    _tmux_new_window_maybe_dir zendesk proto "${ZENDESK_CODE_DIR}/zendesk_protobuf_schemas"
                    ;;
                zqa)
                    # Skip if ZENDESK_CODE_DIR is not set
                    [[ -z "$ZENDESK_CODE_DIR" ]] && continue

                    _tmux_new_session_maybe_dir zqa publ "${ZENDESK_CODE_DIR}/zqa-analytics-publisher"
                    _tmux_new_window_maybe_dir zqa etl "${ZENDESK_CODE_DIR}/zqa-etl-pipelines"
                    _tmux_new_window_maybe_dir zqa dbt_klaus "${ZENDESK_CODE_DIR}/zdp_dbt_regional_klaus"
                    ;;
                notes)
                    _tmux_new_session_maybe_dir notes notes "$HOME/Code/notes"
                    _tmux_new_window_maybe_dir notes dotfiles "$HOME/Code/dotfiles"
                    ;;
                shell)
                    # Create shell session (no special setup)
                    tmux new-session -d -s shell
                    ;;
                *)
                    # Default: create session without special setup
                    tmux new-session -d -s "$session"
                    ;;
            esac
        fi
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

tsz() {
    if [[ -z "$ZENDESK_CODE_DIR" ]]; then
        echo "🧘 Relax, you're not at work."
        return 0
    fi
    _start_all_sessions
    tmux attach-session -t zendesk
}

tsq() {
    if [[ -z "$ZENDESK_CODE_DIR" ]]; then
        echo "🧘 Relax, you're not at work."
        return 0
    fi
    _start_all_sessions
    tmux attach-session -t zqa
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
