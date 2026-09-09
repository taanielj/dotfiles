#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_wezterm() {
    if ! command -v brew >/dev/null 2>&1; then
        error "Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi

    run_quiet "Installing WezTerm" brew install --cask wezterm

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

    if command -v brew >/dev/null 2>&1 && brew list --cask | grep -q "^wezterm$"; then
        log "Uninstalling WezTerm via Homebrew"
        brew uninstall --cask wezterm
    fi

    success "WezTerm configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_wezterm "$@"
fi
