#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

main_ghostty() {
    install_cask ghostty || exit 1
    link_file "$REPO_ROOT/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
}

teardown_ghostty() {
    log "Removing Ghostty configuration..."
    unlink_file "$REPO_ROOT/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
    uninstall_cask ghostty
    success "Ghostty configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_ghostty "$@"
fi
