#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

# win32yank is the Windows clipboard tool behind pbcopy (clipboard/) and nvim
# on WSL. Lives in ~/.local/bin like lazygit, so both find it on PATH.
WIN32YANK_BIN="$HOME/.local/bin/win32yank.exe"

main_win32yank() {
    install_win32yank
}

install_win32yank() {
    if [[ -x "$WIN32YANK_BIN" ]]; then
        log "✅ win32yank is already installed at $WIN32YANK_BIN"
        return
    fi

    WIN32YANK_VERSION=$(
        curl -fsSL "https://api.github.com/repos/equalsraf/win32yank/releases/latest" |
            sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p'
    )
    [[ -z "$WIN32YANK_VERSION" ]] && error "Could not determine the latest win32yank version" && return 1

    mkdir -p "$HOME/.local/bin"

    log "📦 Installing win32yank v$WIN32YANK_VERSION"

    tmp_dir=$(mktemp -d)
    run_quiet "Downloading win32yank" curl -fsSL "https://github.com/equalsraf/win32yank/releases/download/v${WIN32YANK_VERSION}/win32yank-x64.zip" \
        -o "$tmp_dir/win32yank.zip"

    run_quiet "Extracting win32yank" unzip -q "$tmp_dir/win32yank.zip" win32yank.exe -d "$tmp_dir"
    install -m 755 "$tmp_dir/win32yank.exe" "$WIN32YANK_BIN" || return 1
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
