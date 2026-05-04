#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_kitty() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi

    run_quiet "Installing Kitty" brew install --cask kitty

    ln -sf "$REPO_ROOT/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    ln -sf "$REPO_ROOT/kitty/kitty-dark.icns" "$HOME/.config/kitty/kitty-dark.icns"

    # Replacing in the bundle avoids the grey box that cocoa_set_app_icon produces
    local kitty_app="/Applications/kitty.app"
    local icon_dest="$kitty_app/Contents/Resources/kitty.icns"
    if [[ -d "$kitty_app" ]]; then
        cp "$REPO_ROOT/kitty/kitty-dark.icns" "$icon_dest"
        touch "$kitty_app"  # force Finder to refresh the icon cache
        killall Dock 2>/dev/null || true
    fi
}

teardown_kitty() {
    log "Removing Kitty configuration..."

    if [[ -L "$HOME/.config/kitty/kitty.conf" ]]; then
        rm -f "$HOME/.config/kitty/kitty.conf"
    fi

    if [[ -L "$HOME/.config/kitty/kitty-dark.icns" ]]; then
        rm -f "$HOME/.config/kitty/kitty-dark.icns"
    fi

    if command -v brew >/dev/null 2>&1 && brew list --cask | grep -q "^kitty$"; then
        log "Uninstalling Kitty via Homebrew"
        brew uninstall --cask kitty
    fi

    success "Kitty configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_kitty "$@"
fi
