#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_zellij() {
    configure_zellij
}

configure_zellij() {
    log "Configuring zellij..."
    if ! command -v zellij &>/dev/null; then
        warn "Zellij is not installed. Installation failed."
        return 1
    fi

    mkdir -p "$HOME/.config/zellij"
    rm -f "$HOME/.config/zellij/config.kdl"
    ln -sf "$REPO_ROOT/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"

    success "Zellij configuration completed."
}

teardown_zellij() {
    log "Removing zellij configuration..."

    if [[ -L "$HOME/.config/zellij/config.kdl" && "$(readlink "$HOME/.config/zellij/config.kdl")" == "$REPO_ROOT/zellij/config.kdl" ]]; then
        rm -f "$HOME/.config/zellij/config.kdl"
    fi

    success "Zellij configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_zellij "$@"
fi
