#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_tmux() {
    configure_tmux
}

configure_tmux() {
    echo "Configuring tmux..."
    if ! command -v tmux &>/dev/null; then
        echo "Tmux is not installed. Installation failed."
        return 1
    fi

    # Install TPM
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        git -C "$HOME/.tmux/plugins/tpm" pull &>/dev/null
    else
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi

    rm -f "$HOME/.tmux.conf"
    ln -sf "$REPO_ROOT/tmux.conf" "$HOME/.tmux.conf"

    # Ensure tmux is running before installing plugins
    if ! tmux list-sessions &>/dev/null; then
        tmux start-server
        tmux new-session -d
    fi

    # Install plugins
    "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" >/dev/null

    # Source new configuration
    tmux source-file ~/.tmux.conf
    echo "Tmux configuration updated."

    # Cleanup: If we started tmux, kill it (but only if no real sessions exist)
    if ! tmux list-sessions &>/dev/null; then
        tmux kill-server
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_tmux "$@"
fi
