#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

# win32yank is the Windows clipboard tool behind pbcopy (clipboard/) and nvim
# on WSL. Lives in ~/.local/bin like lazygit, so both find it on PATH.
WIN32YANK_BIN="$HOME/.local/bin/win32yank.exe"

main_win32yank() {
    install_win32yank
}

install_win32yank() {
    WIN32YANK_VERSION=$(
        curl -s "https://api.github.com/repos/equalsraf/win32yank/releases/latest" |
            sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p'
    )

    mkdir -p "$HOME/.local/bin"

    if [[ -x "$WIN32YANK_BIN" ]]; then
        log "✅ win32yank is already installed at $WIN32YANK_BIN"
        return
    fi

    log "📦 Installing win32yank v$WIN32YANK_VERSION"

    tmp_dir=$(mktemp -d)
    curl -sSL "https://github.com/equalsraf/win32yank/releases/download/v${WIN32YANK_VERSION}/win32yank-x64.zip" \
        -o "$tmp_dir/win32yank.zip"

    unzip -q "$tmp_dir/win32yank.zip" win32yank.exe -d "$tmp_dir"
    install -m 755 "$tmp_dir/win32yank.exe" "$WIN32YANK_BIN"
    rm -rf "$tmp_dir"

    log "✅ win32yank v$WIN32YANK_VERSION installed to $WIN32YANK_BIN"
}

teardown_win32yank() {
    if [[ -f "$WIN32YANK_BIN" ]]; then
        log "Removing win32yank installation from $WIN32YANK_BIN"
        rm -f "$WIN32YANK_BIN"
        success "win32yank uninstalled."
    else
        log "win32yank is not installed at $WIN32YANK_BIN. Nothing to do."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_win32yank "$@"
fi
