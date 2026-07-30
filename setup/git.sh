#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_git() {
    configure_git
}

configure_git() {
    log "Configuring git..."

    # Link the global gitignore (link_file handles backups automatically!)
    link_file "$REPO_ROOT/gitignore_global" "$HOME/.gitignore_global"

    # Tell git to use the symlinked ignore file globally
    run_quiet "Configuring global core.excludesfile" git config --global core.excludesfile "$HOME/.gitignore_global"

    success "Git configuration completed."
}

teardown_git() {
    log "Removing git configuration..."

    # Unlink the file (unlink_file restores the backup automatically!)
    unlink_file "$REPO_ROOT/gitignore_global" "$HOME/.gitignore_global"

    # Unset the git config
    run_quiet "Removing global core.excludesfile config" git config --global --unset core.excludesfile || true

    success "Git configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_git "$@"
fi
