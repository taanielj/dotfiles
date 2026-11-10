#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

GIT_DEFAULTS=(
    "init.defaultBranch=main"
    "core.excludesfile=$HOME/.gitignore_global"
    "push.autoSetupRemote=true"  # first push of a new branch needs no -u
    "pull.rebase=true"
    "rebase.autoStash=true"
    "fetch.prune=true"
    "rerere.enabled=true"        # reuse recorded conflict resolutions
    "diff.algorithm=histogram"
    "merge.conflictStyle=zdiff3" # conflicts also show the common ancestor
    "branch.sort=-committerdate"
    "core.untrackedCache=true"
)
# core.fsmonitor starts a watcher daemon per repo, which keeps git status fast
# in large repos. On Linux the daemons exhaust inotify's per-user watch limit.
[[ "$OSTYPE" == darwin* ]] && GIT_DEFAULTS+=("core.fsmonitor=true")

main_git() {
    configure_git
}

ensure_git_identity() {
    local key="$1" prompt="$2" value
    git config --global --get "$key" >/dev/null && return 0
    log -n "$prompt: "
    read -r value || true
    [[ -z "$value" ]] && warn "Skipping $key; set it later with: git config --global $key \"...\"" && return 0
    run_quiet "Setting $key" git config --global "$key" "$value"
}

configure_git() {
    log "Configuring git..."

    link_file "$REPO_ROOT/gitignore_global" "$HOME/.gitignore_global"

    local entry key value
    for entry in "${GIT_DEFAULTS[@]}"; do
        key="${entry%%=*}" value="${entry#*=}"
        git config --global --get "$key" >/dev/null && continue # keeps a value set by hand
        run_quiet "Setting $key=$value" git config --global "$key" "$value"
    done

    ensure_git_identity user.name "Git user name"
    ensure_git_identity user.email "Git user email"

    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        run_quiet "Using gh as the GitHub credential helper" gh auth setup-git
    elif command -v gh &>/dev/null; then
        warn "gh is not logged in; run 'gh auth login && gh auth setup-git' to use it for credentials."
    fi

    success "Git configuration completed."
}

teardown_git() {
    log "Removing git configuration..."

    unlink_file "$REPO_ROOT/gitignore_global" "$HOME/.gitignore_global"

    local entry key value
    for entry in "${GIT_DEFAULTS[@]}"; do
        key="${entry%%=*}" value="${entry#*=}"
        [[ "$(git config --global --get "$key")" == "$value" ]] || continue
        run_quiet "Unsetting $key" git config --global --unset "$key"
    done

    success "Git configuration removed. Identity and credential settings are kept."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_git "$@"
fi
