#!/bin/bash
# Script to install Zsh (Oh-My-Zsh), Tmux, Neovim, and other utilities in Termux.
# Note: Termux does not use sudo, adjustments are made accordingly.

# Mapping commands to packages, considering Termux package names and availability
declare -A command_to_package=(
    [curl]="curl"
    [wget]="wget"
    [cmake]="cmake"
    [clang]="clang" # Termux uses clang instead of gcc/g++
    [tmux]="tmux"
    [zsh]="zsh"
    [bat]="bat" # batcat is known as bat in Termux
    [rg]="ripgrep"
    [fd]="fd" # fd-find is known as fd in Termux
    [fzf]="fzf"
)

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

display_warning() {
    echo "This script will install Zsh (Oh-My-Zsh), Tmux, Neovim, ripgrep, fd, fzf, and bat."
    echo "It will overwrite current configuration files for Zsh, Tmux, and Neovim."
    echo "Old configuration files (if any) will be backed up to ~/config-backup."
    echo "Press Enter to continue or Ctrl+C to cancel."
    read -r
}

backup_config() {
    # Define a list of configurations to backup
    declare -A config_paths=(
        [oh-my-zsh]="$HOME/.oh-my-zsh"
        [zshrc]="$HOME/.zshrc"
        [p10k.zsh]="$HOME/.p10k.zsh"
        [tmux.conf]="$HOME/.tmux.conf"
        [tmux]="$HOME/.tmux"
        [nvim]="$HOME/.config/nvim"
    )
    
    # Append timestamp to backup directory
    config_backup_dir="$HOME/config-backup-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$config_backup_dir"
    
    # Loop through configurations and backup
    for config in "${!config_paths[@]}"; do
        local path="${config_paths[$config]}"
        if [ -e "$path" ]; then # Check if file or directory exists
            echo "Backing up existing $config configuration..."
            cp -r "$path" "$config_backup_dir/"
            rm -rf "$path"
        else
            echo "$config does not exist or is a symlink and will not be backed up."
        fi
    done
}

# Check and install required packages
check_required_packages() {
    local missing_packages=()
    for cmd in "${!command_to_package[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_packages+=("${command_to_package[$cmd]}")
        fi
    done
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "Missing required packages: ${missing_packages[*]}. Installing..."
        pkg update -y && pkg install -y "${missing_packages[@]}"
    fi
}

# Installing Zsh and Oh-My-Zsh
configure_zsh() {
    echo "Configuring Zsh..."
    if ! command -v zsh &> /dev/null; then
        echo "Zsh is not installed. Installing..."
        pkg install zsh -y
    fi
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    ln -sf $repo_dir/.zshrc $HOME/.zshrc
    ln -sf $repo_dir/.p10k.zsh $HOME/.p10k.zsh
}

# Function to install Neovim, adjusted for Termux specifics
install_nvim() {
    echo "Installing Neovim..."
    pkg install neovim -y
    ln -sf $repo_dir/.config/nvim $HOME/.config/nvim
}

install_lazygit() {
    echo "Installing lazygit..."
    pkg install lazygit -y
}

install_rust_stuff() {
    echo "Installing Rust and related utilities..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    cargo install zoxide
}

configure_tmux() {
    echo "Configuring tmux..."
    if ! command -v tmux &> /dev/null; then
        echo "Tmux is not installed. Installing..."
        pkg install tmux -y
    fi
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ln -sf $repo_dir/.tmux.conf $HOME/.tmux.conf
    tmux start-server
    tmux new-session -d
    bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    tmux kill-server
}

# Main script execution flow
display_warning
check_required_packages
backup_config
configure_zsh
install_nvim
install_rust_stuff
install_lazygit
configure_tmux

echo "Installation completed successfully."
