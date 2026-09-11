#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

main_wezterm() {
    install_cask wezterm || exit 1

    configure_wezterm
}

configure_wezterm() {
    log "Configuring WezTerm..."

    link_file "$REPO_ROOT/wezterm" "$HOME/.config/wezterm"
    success "WezTerm configuration linked."
}

teardown_wezterm() {
    log "Removing WezTerm configuration..."

    unlink_file "$REPO_ROOT/wezterm" "$HOME/.config/wezterm"

    uninstall_cask wezterm

    success "WezTerm configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_wezterm "$@"
fi
