#!/bin/bash
# Script to install Zsh (Oh-My-Zsh), Tmux, Neovim, and other utilities.

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo to run this script."
    exit 1
fi



display_warning() {
	echo "This script will install Zsh (Oh-My-Zsh), Tmux, Neovim, ripgrep, fd-find, fzf, and bat."
	echo "It will overwrite the current configuration files for Zsh, Tmux, and Neovim."
	echo "Old configuration files (if any) will be backed up to ~/config-backup."
	echo "Press Enter to continue or Ctrl+C to cancel."
	read -r
}

backup_config() {
    # Define a list of configurations to backup
    declare -A config_paths=(
        [oh-my-zsh]="$USER_HOME/.oh-my-zsh"
        [zshrc]="$USER_HOME/.zshrc"
        [tmux.conf]="$USER_HOME/.tmux.conf"
        [tmux]="$USER_HOME/.tmux"
        [nvim]="$USER_HOME/.config/nvim"
    )

    # Flag to track if any config exists
    local config_exists=false

    # Check if any configuration files or directories exist
    for config_path in "${config_paths[@]}"; do
        if [ -e "$config_path" ]; then
            config_exists=true
            break # Exit the loop early as we found at least one config
        fi
    done

    # Proceed to backup if any config exists
    if [ "$config_exists" = true ]; then
        echo "Creating backup directory..."
        mkdir -p "$USER_HOME/config-backup"

        # Loop through the configurations and backup
        for config in "${!config_paths[@]}"; do
            local path="${config_paths[$config]}"
            if [ -e "$path" ]; then # Check if file or directory exists
                echo "Backing up existing $config configuration..."
                mv "$path" "$USER_HOME/config-backup/"
            fi
        done
    else
        echo "No configurations found that require backup."
    fi
}

# Define required packages and the user's environment variables
required_packages=(curl wget git)
USER_HOME=$(getent passwd "${SUDO_USER:-$(whoami)}" | cut -d: -f6)
repo_dir=$(dirname "$(realpath "$0")")

# Function to check and install required packages
check_required_packages() {
    missing_packages=()
    for package in "${required_packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            missing_packages+=("$package")
        fi
    done
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "Missing required packages: ${missing_packages[*]}. Installing..."
        apt-get update -qq && apt-get install -qq -y "${missing_packages[@]}"
    fi
}

# Function to install Zsh and Oh-My-Zsh
install_zsh() {
    echo "Installing Zsh..."


    apt-get install -qq -y zsh
    rm -rf $USER_HOME/.oh-my-zsh
    sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	# zsh install script will install oh-my-zsh in /root/.oh-my-zsh, so we need to move it to the user's home directory
	mv /root/.oh-my-zsh $USER_HOME
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    cp "$repo_dir/.zshrc" "$USER_HOME/.zshrc"
}

# Function to install Tmux
install_tmux() {
    echo "Installing Tmux..."

    apt-get install -qq -y tmux
    git clone https://github.com/tmux-plugins/tpm "$USER_HOME/.tmux/plugins/tpm"
    cp "$repo_dir/.tmux.conf" "$USER_HOME/.tmux.conf"
    tmux start-server
    tmux new-session -d
    bash "$USER_HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    tmux kill-server
}

# Function to install Neovim
install_nvim() {
    echo "Installing Neovim..."
    wget https://github.com/neovim/neovim/releases/download/v0.9.5/nvim.appimage
    chmod u+x nvim.appimage
    ./nvim.appimage --appimage-extract %> /dev/null
    mv ./squashfs-root /opt/nvim
    ln -sf /opt/nvim/AppRun /usr/bin/nvim
    rm nvim.appimage

    mkdir -p "$USER_HOME/.config/nvim"
    cp -r $repo_dir/nvim/* $USER_HOME/.config/nvim
	sleep 5
}

# Function to set correct permissions
set_permissions() {
    echo "Setting permissions..."
    chown -R "${SUDO_USER:-$(whoami)}":"${SUDO_USER:-$(whoami)}" $USER_HOME
}

# Function to install additional utilities
install_utilities() {
    echo "Installing additional utilities..."
    apt-get install -qq -y bat ripgrep fd-find fzf
	echo "Installed bat, ripgrep, fd-find, and fzf."
}

# Main script execution
display_warning
check_required_packages
backup_config
apt-get update -qq -y || { echo "Failed to update package list"; exit 1; }
install_zsh
install_tmux
install_nvim
install_utilities
set_permissions

echo "Installation completed successfully."