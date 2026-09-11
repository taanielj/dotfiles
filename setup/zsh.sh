#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

main_zsh() {
    configure_zsh
}

configure_zsh() {
    log "Configuring Zsh..."

    if ! command -v zsh &>/dev/null; then
        warn "Zsh is not installed. Installation failed."
        return 1
    fi

    stub_file "$REPO_ROOT/zsh/zshrc.zsh" "$HOME/.zshrc"

    stub_file "$REPO_ROOT/zsh/zprofile.zsh" "$HOME/.zprofile"

    link_file "$REPO_ROOT/zsh" "$HOME/.config/zsh"

    success "Zsh configuration completed."
}

teardown_zsh() {
    log "Removing Zsh configuration..."

    # A dest may be a stub or a symlink, so try both removal paths.
    unstub_file "$REPO_ROOT/zsh/zshrc.zsh" "$HOME/.zshrc"
    unlink_file "$REPO_ROOT/zsh/zshrc.zsh" "$HOME/.zshrc"

    unstub_file "$REPO_ROOT/zsh/zprofile.zsh" "$HOME/.zprofile"
    unlink_file "$REPO_ROOT/zsh/zprofile.zsh" "$HOME/.zprofile"

    unlink_file "$REPO_ROOT/zsh" "$HOME/.config/zsh"

    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"
    if [[ -d "$ZINIT_HOME" ]]; then
        log "Removing zinit and all plugins from $ZINIT_HOME"
        rm -rf "$ZINIT_HOME"
    fi

    success "Zsh configuration and zinit components removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_zsh "$@"
fi
