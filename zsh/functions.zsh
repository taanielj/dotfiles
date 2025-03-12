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
nvim() {
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

# tmux() {
#     # If arguments are provided, run tmux normally
#     [[ $# -ne 0 ]] && command tmux "$@" && return
#
#     # If already inside tmux, create a new window and switch to it
#     [[ -n "$TMUX" ]] && command tmux new-window && return
#
#     # If session 0 exists and is detached, attach to it
#     if tmux has-session -t 0 2>/dev/null; then
#         if [[ $(tmux list-sessions -F '#{session_name} #{session_attached}' | awk '$1 == "0" {print $2}') -eq 0 ]]; then
#             command tmux attach-session -t 0
#             return
#         fi
#     fi
#
#     # Otherwise, start a new tmux session
#     command /usr/local/bin/tmux
# }
