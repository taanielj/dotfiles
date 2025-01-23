#!/bin/bash
# Script to install Zsh (Oh-My-Zsh), Tmux, Neovim, and other utilities for macOS.
# Ensure script is not run with sudo, will invoke sudo as needed and prompt for password.

if [ "$(id -u)" -eq 0 ]; then
    if [ -z "$SUDO_USER" ]; then
        echo "Running as root without sudo, continuing..."
    else
        echo "This script should not be run with sudo. Please run it as your normal user; it will invoke sudo as needed."
        exit 1
    fi
fi

declare -A command_to_package=(
    #[command]="package"
    [curl]="curl"
    [wget]="wget"
    [cmake]="cmake"
    [gcc]="gcc"
    [g++]="gcc"  # macOS uses clang for C++ compilation, installed with Xcode Command Line Tools
    [tmux]="tmux"
    [zsh]="zsh"
    [batcat]="bat" # on macOS it's just called 'bat'
    [ripgrep]="rg"
    [fd]="fd"
    [fzf]="fzf"
    [npm]="node"
    [zoxide]="z"
    [eza]="exa"
    [fastfetch]="fastfetch"
)

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

display_warning() {
    echo "This script will install Zsh (Oh-My-Zsh), Tmux, Neovim, ripgrep, fd, fzf, and bat."
    echo "It will overwrite the current configuration files for Zsh, Tmux, and Neovim."
    echo "Old configuration files (if any) will be backed up to ~/config-backup."
    echo "Press Enter to continue or Ctrl+C to cancel."
    read -r
}

backup_config() {
    declare -A config_paths=(
        [oh-my-zsh]="$HOME/.oh-my-zsh"
        [zshrc]="$HOME/.zshrc"
        [p10k.zsh]="$HOME/.p10k.zsh"
        [tmux.conf]="$HOME/.tmux.conf"
        [tmux]="$HOME/.tmux"
        [nvim]="$HOME/.config/nvim"
    )

    local config_exists=false
    for config_path in "${config_paths[@]}"; do
        if [ -e "$config_path" ] && [ ! -L "$config_path" ]; then
            config_exists=true
            break
        fi
    done

    config_backup_dir="$HOME/config-backup-$(date +%Y%m%d%H%M%S)"

    if [ "$config_exists" = true ]; then
        echo "Creating backup directory..."
        mkdir -p "$config_backup_dir"

        for config in "${!config_paths[@]}"; do
            local path="${config_paths[$config]}"
            if [ -e "$path" ] && [ ! -L "$path" ]; then
                echo "Backing up existing $config configuration..."
                cp -r "$path" "$config_backup_dir"
                rm -rf "$path"
            else
                echo "$config is a symlink and will not be backed up."
            fi
        done
    else
        echo "No configurations found that require backup or all configs are symlinks."
    fi
}

install_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew is already installed."
    fi
}

check_required_packages() {
    local missing_packages=()
    for cmd in "${!command_to_package[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_packages+=("${command_to_package[$cmd]}")
        fi
    done
    if [ ${#missing_packages[@]} -ne 0 ]; then
        brew update
        brew install "${missing_packages[@]}"
    fi
}

configure_zsh() {
    echo "Configuring Zsh..."
    if ! command -v zsh &> /dev/null; then
        echo "Zsh is not installed. Please install it first."
        return
    fi
    rm -rf $HOME/.oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k   
    rm $HOME/.zshrc $HOME/.p10k.zsh
    ln -s $repo_dir/zshrc $HOME/.zshrc
    ln -s $repo_dir/p10k.zsh $HOME/.p10k.zsh
}

install_nvim() {
    echo "Installing Neovim..."
    brew install neovim
    rm -rf $HOME/.config/nvim
    ln -s $repo_dir/.config/nvim $HOME/.config/nvim
}

install_lazygit() {
    echo "Installing Lazygit..."
    brew install lazygit
}

install_rust_stuff() {
    curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y -q;
    $HOME/.cargo/bin/cargo install zoxide exa;
}

configure_tmux() {
    echo "Configuring tmux..."
    if ! command -v tmux &> /dev/null; then
        echo "Tmux is not installed. Please install it first."
        return
    fi
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    rm $HOME/.tmux.conf
    ln -s $repo_dir/tmux.conf $HOME/.tmux.conf
    tmux start-server
    tmux new-session -d
    bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    tmux kill-server
}

setup_git() {
    read -p "Enter your git user name: " git_user_name
    read -p "Enter your git email: " git_email
    git config --global user.name "$git_user_name"
    git config --global user.email "$git_email"
    ln -s $repo_dir/gitignore_global $HOME/.gitignore_global
    git config --global core.excludesfile ~/.gitignore_global
}

# Main script execution
display_warning
install_homebrew
check_required_packages
backup_config
configure_zsh
install_nvim
install_rust_stuff
install_lazygit
configure_tmux
setup_git

echo "Installation completed successfully."

