#!/usr/bin/env bash

source logging.sh
set -e

main_userland() {
    install_asdf
    install_asdf_plugins "nodejs" "python" "golang" "java" # "ruby" (not needed for now, check on work laptop when needed)
    install_asdf_tools
    install_rust
    install_rust_cli_tools "eza" "zoxide"
}

install_asdf() {
    local version="v0.16.0"
    local dir="$HOME/.asdf"
    local legacy_bin="$dir/bin/asdf"
    local go_asdf="$dir/asdf"  # this is the Go-built binary

    log -n "Installing asdf $version..."

    if [[ -x "$go_asdf" && "$($go_asdf --version)" == "$version" ]]; then
        success " already installed"
        return
    fi

    if [[ -d "$dir" && ! -d "$dir/.git" ]]; then
        error "$dir exists but is not a git repo. Remove or fix manually."
        exit 1
    elif [[ -d "$dir" ]]; then
        git -C "$dir" fetch --quiet
        git -C "$dir" checkout "$version" --quiet
    else
        git clone https://github.com/asdf-vm/asdf.git --branch "$version" "$dir" >/dev/null
    fi

    # Use the legacy Bash asdf to install Go (needed for make build)
    export PATH="$dir/bin:$PATH"
    "$legacy_bin" plugin add golang >/dev/null 2>&1 || true
    "$legacy_bin" install golang 1.24.1 >/dev/null
    "$legacy_bin" global golang 1.24.1

    # Add Go to path for this shell
    export PATH="$dir/shims:$PATH"

    # Build the Go-native version of asdf
    log -n "Building asdf with Go..."
    PATH="$HOME/.asdf/installs/golang/1.24.1/bin:$PATH" make -C "$dir" build >/dev/null
    success " done"

    # Update ~/.zshrc and ~/.bashrc
    for rc in ~/.zshrc ~/.bashrc; do
        grep -q '.asdf/shims' "$rc" 2>/dev/null || echo 'export PATH="$HOME/.asdf:$HOME/.asdf/shims:$PATH"' >> "$rc"
    done
}


install_asdf_plugins() {
    local plugins=("$@")
    log "Installing asdf plugins..."
    for plugin in "${plugins[@]}"; do
        log -n "    Installing $plugin..."
        ~/.asdf/bin/asdf plugin add $plugin >/dev/null 2>&1 || true
        success " done"
    done
    success "All plugins installed"
}

install_asdf_tool() {
    local plugin=$1
    local version=$2

    log "Checking "$plugin $version"..."

    if ! asdf list $plugin | grep -q $version; then
        log  "    Installing $plugin $version..."
        asdf install $plugin $version >/dev/null || { error "Failed to install $plugin $version" && exit 1; }
    else
        success "   $plugin $version already installed"
    fi

    log "    setting $plugin $version as global..."
    asdf global $plugin $version >/dev/null || { error "Failed to set $plugin $version as global" && exit 1; }
}

install_asdf_tools() {
    install_asdf_tool "golang" "1.24.1"
    install_asdf_tool "nodejs" "22.1.0"
    install_asdf_tool "python" "3.12.9"
    install_asdf_tool "java" "21.0.6-zulu"
}

install_rust() {
    # Use rustup to install rust
    if ! command -v rustup &>/dev/null; then
        log -n "Installing rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null
        success " done"
        # add sourceing to bashrc and zshrc if not already there for "$HOME/.cargo/env"
        for rc in ~/.bashrc ~/.zshrc; do
            grep -q '.cargo/env' "$rc" 2>/dev/null || echo 'source "$HOME/.cargo/env"' >> "$rc"
        done
        
    else
        log "rust already installed"
    fi
}

install_rust_cli_tools() {
    # takes list of tools to install, installs with cargo
    local tools=("$@")
    log -n "Installing rust tools..."
    for tool in "${tools[@]}"; do
        log -n "    Installing $tool..."
        cargo install $tool >/dev/null || { error "Failed to install $tool" && exit 1; }
        success " done"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_userland "$@"
fi
