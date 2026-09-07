#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_git() {
    configure_git
}

configure_git() {
    log "Configuring git..."

    link_file "$REPO_ROOT/gitignore_global" "$HOME/.gitignore_global"

    run_quiet "Configuring global core.excludesfile" git config --global core.excludesfile "$HOME/.gitignore_global"

    success "Git configuration completed."
}

teardown_git() {
    log "Removing git configuration..."

    unlink_file "$REPO_ROOT/gitignore_global" "$HOME/.gitignore_global"

    run_quiet "Removing global core.excludesfile config" git config --global --unset core.excludesfile || true

    success "Git configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_git "$@"
fi
