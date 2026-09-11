#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OS=$(uname -s)
source "$REPO_ROOT/setup/utils.sh"

main_nvim() {
    install_nvim
    configure_nvim
}

install_nvim() {
    log "Installing Neovim (latest stable release)..."

    local github_url="https://github.com/neovim/neovim/releases/latest/download/"
    local os="" arch
    [[ "$OS" == "Darwin" ]] && os="macos"
    [[ "$OS" == "Linux" ]] && os="linux"
    arch=$(release_arch)
    [[ -z "$os" || -z "$arch" ]] && error "Unsupported architecture: $(uname -m)" && return 1
    local archive_name="nvim-$os-$arch.tar.gz"

    local tmp_dir
    tmp_dir=$(mktemp -d)
    run_quiet "Downloading Neovim" curl -fsSL -o "$tmp_dir/nvim.tar.gz" "$github_url$archive_name"

    run_quiet "Extracting Neovim" tar -C "$tmp_dir" -xzf "$tmp_dir/nvim.tar.gz"
    local nvim_path
    nvim_path=$(find "$tmp_dir" -type d -name "nvim-*")

    mkdir -p "$HOME/.local"
    rm -rf "$HOME/.local/nvim"
    mv "$nvim_path" "$HOME/.local/nvim"
    rm -rf "$tmp_dir"

    # zsh/zshrc.zsh already prepends this, so only bash needs the line
    rc_append_line 'export PATH=$HOME/.local/nvim/bin:$PATH' "$HOME/.bashrc"
    export PATH="$HOME/.local/nvim/bin:$PATH"
    local nvim_version
    nvim_version=$(nvim --version | head -n1)
    success "Installed Neovim: $nvim_version"
}

configure_nvim() {
    log "Configuring Neovim..."

    if ! command -v nvim &>/dev/null; then
        error "❌ Neovim is not installed. Configuration failed."
        return 1
    fi

    link_file "$REPO_ROOT/nvim" "$HOME/.config/nvim"
    run_quiet "Syncing Lazy.nvim plugins" nvim --headless "+Lazy! sync" +qa

    success "Neovim configuration completed."
}

teardown_nvim() {
    log "Removing Neovim configuration..."

    unlink_file "$REPO_ROOT/nvim" "$HOME/.config/nvim"

    if [[ -d "$HOME/.local/nvim" ]]; then
        log "Removing Neovim installation from ~/.local/nvim"
        rm -rf "$HOME/.local/nvim"
    fi

    rc_remove_lines ".local/nvim/bin"

    success "Neovim configuration and installation removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_nvim "$@"
fi
