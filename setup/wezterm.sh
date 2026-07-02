#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_wezterm() {
    configure_wezterm
}

configure_wezterm() {
    log "Configuring WezTerm..."

    if ! command -v wezterm &>/dev/null; then
        warn "WezTerm is not installed, skipping configuration."
        return 1
    fi

    link_file "$REPO_ROOT/wezterm" "$HOME/.config/wezterm"
    success "WezTerm configuration linked."
}

teardown_wezterm() {
    log "Removing WezTerm configuration..."

    unlink_file "$REPO_ROOT/wezterm" "$HOME/.config/wezterm"
    success "WezTerm configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_wezterm "$@"
fi
