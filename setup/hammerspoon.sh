#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

main_hammerspoon() {
    install_cask hammerspoon || exit 1
    link_file "$REPO_ROOT/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
    # A restart loads the config even when the running one predates it and so
    # has no hs.ipc to take a reload through
    if pgrep -xq Hammerspoon; then
        pkill -x Hammerspoon
        while pgrep -xq Hammerspoon; do sleep 0.1; done
    fi
    open -g -a Hammerspoon
}

teardown_hammerspoon() {
    log "Removing Hammerspoon configuration..."
    unlink_file "$REPO_ROOT/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
    uninstall_cask hammerspoon
    success "Hammerspoon configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_hammerspoon "$@"
fi
