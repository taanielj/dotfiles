#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
OS=$(uname -s)
source "$REPO_ROOT/setup/utils.sh"

main_nvim() {
    install_nvim
    configure_nvim
}

install_nvim() {
    local github_url="https://github.com/neovim/neovim/releases/latest/download/"
    local archive_name=""
    if [[ "$OS" == "Darwin" ]]; then
        [[ "$(uname -m)" == "arm64" ]] && archive_name="nvim-macos-arm64.tar.gz"
        [[ "$(uname -m)" == "x86_64" ]] && archive_name="nvim-macos-x86_64.tar.gz"
    elif [[ "$OS" == "Linux" ]]; then
        archive_name="nvim-linux-x86_64.tar.gz"
    fi
    [[ "$archive_name" == "" ]] && echo "Unsupported architecture: $(uname -m)" && return 1
    tmp_dir=$(mktemp -d)
    curl -Lo "$tmp_dir/nvim.tar.gz" "$github_url$archive_name"
    mkdir -p $HOME/.local
    tar -C $HOME/.local -xzf "$tmp_dir/nvim.tar.gz"
    rm -rf "$tmp_dir"
    local nvim_path=$(find $HOME/.local -type d -name "nvim-*")
    mv "$nvim_path" "$HOME/.local/nvim"
    for rc in $HOME/.bashrc $HOME/.zshrc; do
        grep -q "/.local/nvim/bin" "$rc" || echo "export PATH=\$HOME/.local/nvim/bin:\$PATH" >>"$rc"
    done
    export PATH=$HOME/.local/nvim/bin:$PATH
}

configure_nvim() {
    echo "Installing Neovim configuration to $HOME/.config/nvim..."
    if ! command -v nvim &>/dev/null; then
        echo "Neovim is not installed. Installation failed."
        return 1
    fi
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share/nvim/databases" # Needed by telescope history to store SQLite database file
    ln -sfn "$REPO_ROOT/nvim" "$HOME/.config/nvim"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_nvim "$@"
fi
