#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
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

    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        git -C "$HOME/.tmux/plugins/tpm" pull &>/dev/null || warn "Could not update tpm."
    else
        run_quiet "Cloning tpm" git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi

    link_file "$REPO_ROOT/tmux.conf" "$HOME/.tmux.conf"

    # tpm's installer needs a running server.
    local started_server=0
    if ! tmux list-sessions &>/dev/null; then
        tmux start-server
        tmux new-session -d
        started_server=1
    fi

    run_quiet "Installing tmux plugins" "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    tmux source-file ~/.tmux.conf || warn "tmux reported errors in ~/.tmux.conf."
    # Only our own session is on this server, so killing it takes nothing else down.
    if [[ "$started_server" -eq 1 ]]; then
        tmux kill-server
    fi
    success "Tmux configuration completed."
}

teardown_tmux() {
    log "Removing tmux configuration..."

    unlink_file "$REPO_ROOT/tmux.conf" "$HOME/.tmux.conf"

    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        log "Removing tmux plugin manager and plugins"
        rm -rf "$HOME/.tmux/plugins"
    fi

    success "Tmux configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_tmux "$@"
fi
