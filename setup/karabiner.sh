#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_karabiner() {
    configure_karabiner
}

configure_karabiner() {
    log "Configuring Karabiner-Elements..."

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
