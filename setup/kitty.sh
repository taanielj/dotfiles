#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_kitty() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi

    run_quiet "Installing Kitty" brew install --cask kitty

    link_file "$REPO_ROOT/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    # Must be named kitty.app.icns for kitty to pick it up at startup
    link_file "$REPO_ROOT/kitty/kitty-dark.icns" "$HOME/.config/kitty/kitty.app.icns"

    rm /var/folders/*/*/*/com.apple.dock.iconcache 2>/dev/null || true
    killall Dock 2>/dev/null || true
}

teardown_kitty() {
    log "Removing Kitty configuration..."

    unlink_file "$REPO_ROOT/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    unlink_file "$REPO_ROOT/kitty/kitty-dark.icns" "$HOME/.config/kitty/kitty.app.icns"

    if command -v brew >/dev/null 2>&1 && brew list --cask | grep -q "^kitty$"; then
        log "Uninstalling Kitty via Homebrew"
        brew uninstall --cask kitty
    fi

    success "Kitty configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_kitty "$@"
fi
