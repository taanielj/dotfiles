#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

main_bat() {
    link_file "$REPO_ROOT/bat" "$HOME/.config/bat"

    if ! command -v bat &>/dev/null; then
        warn "bat is not installed, the theme cache builds on the next setup run"
        return 0
    fi
    # Custom themes load only from the cache; the vendored one covers bat releases without bundled Catppuccin
    run_quiet "Building bat theme cache" bat cache --build
}

teardown_bat() {
    unlink_file "$REPO_ROOT/bat" "$HOME/.config/bat"

    command -v bat &>/dev/null && run_quiet "Clearing bat theme cache" bat cache --clear
    success "bat configuration removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_bat "$@"
fi
