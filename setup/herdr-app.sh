#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

APP_HOME="$HOME/.config/herdr-app"
# Files the app reads from its home; everything else there is the app's own state.
# The app's file events don't follow these links: after editing a mod in the
# repo, `touch -h` its link to reload it.
APP_FILES=(settings.json keys.json themes/ghostty.json layouts/dotfiles.json mods/keys mods/status mods/strip mods/files-icons bin)

main_herdr-app() {
    install_cask herdr-app || exit 1
    install_herdr_core
    configure_herdr_app
}

install_herdr_core() {
    if command -v hc &>/dev/null; then
        log "✅ herdr-core is already installed at $(command -v hc)"
        return
    fi
    local installer
    if ! installer=$(fetch_installer https://releases.herdr.dev/core/install.sh); then
        error "❌ Failed to download the herdr-core installer."
        return 1
    fi
    # The script installs to ~/.local/bin, which zprofile puts on PATH.
    run_quiet "Installing herdr-core" sh -c "$installer"
}

configure_herdr_app() {
    log "Configuring the Herdr app..."
    local file
    for file in "${APP_FILES[@]}"; do
        link_file "$REPO_ROOT/herdr-app/$file" "$APP_HOME/$file"
    done
    # The layout docks the keys mod; a running window switches to it now.
    herdr-app "do" layout.set --layout dotfiles &>/dev/null || true
    success "Herdr app configuration linked."
}

teardown_herdr-app() {
    log "Removing Herdr app configuration..."
    local file
    for file in "${APP_FILES[@]}"; do
        unlink_file "$REPO_ROOT/herdr-app/$file" "$APP_HOME/$file"
    done
    uninstall_cask herdr-app
    success "Herdr app configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_herdr-app "$@"
fi
