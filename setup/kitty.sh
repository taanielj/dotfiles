#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

main_kitty() {
    install_cask kitty || exit 1

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

    uninstall_cask kitty

    success "Kitty configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_kitty "$@"
fi
