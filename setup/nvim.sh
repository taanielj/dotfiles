#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
OS=$(uname -s)
source "$REPO_ROOT/setup/utils.sh"

main_nvim() {
    install_nvim
    configure_nvim
}

install_nvim() {
    log "Installing Neovim nightly..."

    local github_url="https://github.com/neovim/neovim/releases/latest/download/"
    local archive_name=""
    if [[ "$OS" == "Darwin" ]]; then
        [[ "$(uname -m)" == "arm64" ]] && archive_name="nvim-macos-arm64.tar.gz"
        [[ "$(uname -m)" == "x86_64" ]] && archive_name="nvim-macos-x86_64.tar.gz"
    elif [[ "$OS" == "Linux" ]]; then
        archive_name="nvim-linux-x86_64.tar.gz"
    fi
    [[ -z "$archive_name" ]] && error "Unsupported architecture: $(uname -m)" && return 1

    local tmp_dir
    tmp_dir=$(mktemp -d)
    run_quiet "Downloading Neovim" curl -Lo "$tmp_dir/nvim.tar.gz" "$github_url$archive_name"

    run_quiet "Extracting Neovim" tar -C "$tmp_dir" -xzf "$tmp_dir/nvim.tar.gz"
    local nvim_path
    nvim_path=$(find "$tmp_dir" -type d -name "nvim-*")

    mkdir -p "$HOME/.local"
    rm -rf "$HOME/.local/nvim"
    mv "$nvim_path" "$HOME/.local/nvim"
    rm -rf "$tmp_dir"

    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        grep -q "/.local/nvim/bin" "$rc" || echo 'export PATH=$HOME/.local/nvim/bin:$PATH' >> "$rc"
    done
    export PATH="$HOME/.local/nvim/bin:$PATH"

    success "Neovim installed to ~/.local/nvim"
}

configure_nvim() {
    log "Configuring Neovim..."

    if ! command -v nvim &>/dev/null; then
        error "❌ Neovim is not installed. Configuration failed."
        return 1
    fi

    mkdir -p "$HOME/.config"
    local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
    mkdir -p "$data_home/nvim/databases"

    if [[ -e "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
        warn "⚠️ Backing up existing Neovim config..."
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
    fi

    ln -sfn "$REPO_ROOT/nvim" "$HOME/.config/nvim"
    run_quiet "Syncing Lazy.nvim plugins" nvim --headless "+Lazy! sync" +qa

    success "Neovim configuration completed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_nvim "$@"
fi

