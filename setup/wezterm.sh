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

    mkdir -p "$HOME/.config"

    if [[ -e "$HOME/.config/wezterm" && ! -L "$HOME/.config/wezterm" ]]; then
        warn "Backing up existing WezTerm config..."
        mv "$HOME/.config/wezterm" "$HOME/.config/wezterm.backup.$(date +%s)"
    fi

    ln -sfn "$REPO_ROOT/wezterm" "$HOME/.config/wezterm"
    success "WezTerm configuration linked."
}

teardown_wezterm() {
    log "Removing WezTerm configuration..."

    if [[ -L "$HOME/.config/wezterm" ]]; then
        rm -f "$HOME/.config/wezterm"
        success "WezTerm configuration removed."
    else
        warn "No WezTerm symlink found, nothing to remove."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_wezterm "$@"
fi
