#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_kitty() {
    # Install Kitty on macOS
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi

    run_quiet brew install --cask kitty

    ln -sf "$REPO_ROOT/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    ln -sf "$REPO_ROOT/kitty/kitty-dark.icns" "$HOME/.config/kitty/kitty-dark.icns"

    # Set custom app icon for Kitty
    kitty +runpy \
        'from kitty.fast_data_types import cocoa_set_app_icon; import sys; \
        cocoa_set_app_icon(*sys.argv[1:]); print("OK")' \
        "$HOME/.config/kitty/kitty-dark.icns"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_kitty "$@"
fi
