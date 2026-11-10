#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

main_clipboard() {
    link_file "$REPO_ROOT/clipboard/pbcopy" "$HOME/.local/bin/pbcopy"
    link_file "$REPO_ROOT/clipboard/pbpaste" "$HOME/.local/bin/pbpaste"
    [[ -n "$WSL_DISTRO_NAME" ]] && link_file "$REPO_ROOT/clipboard/wslview" "$HOME/.local/bin/wslview"
    return 0
}

teardown_clipboard() {
    unlink_file "$REPO_ROOT/clipboard/pbcopy" "$HOME/.local/bin/pbcopy"
    unlink_file "$REPO_ROOT/clipboard/pbpaste" "$HOME/.local/bin/pbpaste"
    unlink_file "$REPO_ROOT/clipboard/wslview" "$HOME/.local/bin/wslview"
    success "Clipboard shims removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -e
    main_clipboard "$@"
fi
