#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

RUST_TOOLS=("eza" "zoxide")
declare -A ASDF_PLUGINS

main_rust() {
    install_rust
    install_rust_cli_tools "${RUST_TOOLS[@]}"
}

install_rust() {
    # Use rustup to install rust
    if ! command -v rustup &>/dev/null; then
        run_quiet "Installing rust" bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
        # add sourceing to bashrc and zshrc if not already there for "$HOME/.cargo/env"
        for rc in ~/.bashrc ~/.zshrc; do
            grep -q '.cargo/env' "$rc" 2>/dev/null || echo 'source "$HOME/.cargo/env"' >>"$rc"
        done
    else
        log "rust already installed"
    fi
    source "$HOME/.cargo/env"
}

install_rust_cli_tools() {
    # takes list of tools to install, installs with cargo
    if ! command -v cargo &>/dev/null; then
        error "cargo not found. Aborting."
        exit 1
    fi
    local tools=("$@")
    log -n "Installing rust tools ${tools[@]}..."
    for tool in "${tools[@]}"; do
        run_quiet "Installing $tool" cargo install "$tool"
    done
    success " Done"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_rust "$@"
fi
