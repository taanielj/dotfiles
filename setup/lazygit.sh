#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_lazygit() {
    # macOS gets lazygit from brew (setup/system.sh); elsewhere from the release tarball.
    if [[ "$(uname -s)" != "Darwin" ]]; then
        install_lazygit
    fi

    # macOS lazygit defaults to ~/Library/Application Support; LG_CONFIG_FILE
    # (exported in zshrc.zsh) points it at this link instead.
    link_file "$REPO_ROOT/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
}

install_lazygit() {
    LAZYGIT_VERSION=$(
        curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" |
            sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p'
    )
    LAZYGIT_BIN="$HOME/.local/bin/lazygit"

    local arch=""
    [[ "$(uname -m)" == "aarch64" ]] && arch="arm64"
    [[ "$(uname -m)" == "x86_64" ]] && arch="x86_64"
    [[ -z "$arch" ]] && error "Unsupported architecture: $(uname -m)" && return 1

    mkdir -p "$HOME/.local/bin"

    if [[ -x "$LAZYGIT_BIN" ]]; then
        current_version=$("$LAZYGIT_BIN" -v 2>/dev/null | grep -oE 'version=[^,]+' | cut -d= -f2 | head -n 1)
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
    curl -sSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${arch}.tar.gz" \
        -o "$tmp_dir/lazygit.tar.gz"

    tar -xzf "$tmp_dir/lazygit.tar.gz" -C "$tmp_dir"
    install -m 755 "$tmp_dir/lazygit" "$LAZYGIT_BIN"
    rm -rf "$tmp_dir"

    log "✅ lazygit v$LAZYGIT_VERSION installed to $LAZYGIT_BIN"
}

teardown_lazygit() {
    LAZYGIT_BIN="$HOME/.local/bin/lazygit"

    unlink_file "$REPO_ROOT/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

    if [[ -f "$LAZYGIT_BIN" ]]; then
        log "Removing lazygit installation from $LAZYGIT_BIN"
        rm -f "$LAZYGIT_BIN"
        success "Lazygit uninstalled."
    else
        log "Lazygit is not installed at $LAZYGIT_BIN. Nothing to do."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_lazygit "$@"
fi
