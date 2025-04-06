#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_lazygit() {
    install_lazygit
}

install_lazygit() {
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" |
        grep -Po '"tag_name": *"v\K[^"]*')
    LAZYGIT_BIN="$HOME/.local/bin/lazygit"

    mkdir -p "$HOME/.local/bin"

    if command -v lazygit &>/dev/null; then
        current_version=$("$LAZYGIT_BIN" -v 2>/dev/null | grep -Po 'version=\K[^, ]+')
        if [[ "$current_version" == "$LAZYGIT_VERSION" ]]; then
            log "✅ lazygit is already up to date (v$current_version)"
            return
        else
            log "⏫ lazygit is outdated (v$current_version), updating to v$LAZYGIT_VERSION"
        fi
    else
        log "📦 Installing lazygit v$LAZYGIT_VERSION"
    fi

    tmp_dir=$(mktemp -d)
    curl -sSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
        -o "$tmp_dir/lazygit.tar.gz"

    tar -xzf "$tmp_dir/lazygit.tar.gz" -C "$tmp_dir"
    install -m 755 "$tmp_dir/lazygit" "$LAZYGIT_BIN"
    rm -rf "$tmp_dir"

    log "✅ lazygit v$LAZYGIT_VERSION installed to $LAZYGIT_BIN"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_lazygit "$@"
fi

