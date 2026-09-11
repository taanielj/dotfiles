#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

main_karabiner() {
    configure_karabiner
}

configure_karabiner() {
    log "Configuring Karabiner-Elements..."

    # Without brew the config is still linked for a hand-installed Karabiner.
    if command -v brew >/dev/null 2>&1; then
        install_cask karabiner-elements
    fi
    link_file "$REPO_ROOT/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
    success "Karabiner-Elements configuration linked."
}

teardown_karabiner() {
    log "Removing Karabiner-Elements configuration..."

    unlink_file "$REPO_ROOT/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
    success "Karabiner-Elements configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_karabiner "$@"
fi
