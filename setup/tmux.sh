#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_tmux() {
    configure_tmux
}

configure_tmux() {
    log "Configuring tmux..."
    if ! command -v tmux &>/dev/null; then
        warn "Tmux is not installed. Installation failed."
        return 1
    fi

    # Install TPM
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        git -C "$HOME/.tmux/plugins/tpm" pull &>/dev/null
    else
        run_quiet "Cloning tpm" git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi

    rm -f "$HOME/.tmux.conf"
    ln -sf "$REPO_ROOT/tmux.conf" "$HOME/.tmux.conf"

    # Ensure tmux is running before installing plugins
    if ! tmux list-sessions &>/dev/null; then
        tmux start-server
        tmux new-session -d
    fi

    run_quiet "Installing tmux plugins" "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    # Source new configuration
    tmux source-file ~/.tmux.conf
    # Cleanup: If we started tmux, kill it (but only if no real sessions exist)
    if ! tmux list-sessions &>/dev/null; then
        tmux kill-server
    fi
    success "Tmux configuration completed."
}

teardown_tmux() {
    log "Removing tmux configuration..."

    # Remove tmux.conf symlink
    if [[ -L "$HOME/.tmux.conf" && "$(readlink "$HOME/.tmux.conf")" == "$REPO_ROOT/tmux.conf" ]]; then
        rm -f "$HOME/.tmux.conf"
    fi

    # Remove TPM and plugins
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        log "Removing tmux plugin manager and plugins"
        rm -rf "$HOME/.tmux/plugins"
    fi

    success "Tmux configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_tmux "$@"
fi
