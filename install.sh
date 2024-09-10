#!/bin/bash
# Script to install Zsh (Oh-My-Zsh), Tmux, Neovim, and other utilities.
# Designed to work with Ubuntu 22.04 LTS. 
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
    [curl]="curl"
    [wget]="wget"
    [cmake]="cmake"
    [gcc]="gcc"
    [g++]="g++"
    [tmux]="tmux"
    [zsh]="zsh"
    [batcat]="bat"
    [rg]="ripgrep"
    [fdfind]="fd-find"
    [fzf]="fzf"
    [npm]="nodejs npm"
#     [neofetch]="neofetch" use fastfetch
)

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

display_warning() {
	echo "This script will install Zsh (Oh-My-Zsh), Tmux, Neovim, ripgrep, fd-find, fzf, and bat."
	echo "It will overwrite the current configuration files for Zsh, Tmux, and Neovim."
	echo "Old configuration files (if any) will be backed up to ~/config-backup."
	echo "Press Enter to continue or Ctrl+C to cancel."
	read -r
}

install_python() {
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt-get install python3.11 python3.11-dev python3.11-venv
    # symlink python to python3
    sudo ln -s /usr/bin/python3.11 /usr/bin/python
}

install_node(){
    wget -q -O- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    . ~/.bashrc
    nvm install node
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
        [gitignore_global]="$HOME/.gitignore_global"
    )

    # Flag to track if any config exists that is not a symlink
    local config_exists=false

    # Check if any configuration files or directories exist and are not symlinks
    for config_path in "${config_paths[@]}"; do
        if [ -e "$config_path" ] && [ ! -L "$config_path" ]; then
            config_exists=true
            break # Exit the loop early as we found at least one config that is not a symlink
        fi
    done
    
    # append timestamp to backup directory
    config_backup_dir="$HOME/config-backup-$(date +%Y%m%d%H%M%S)"

    # Proceed to backup if any config exists that is not a symlink
    if [ "$config_exists" = true ]; then
        echo "Creating backup directory..."
        mkdir -p "$config_backup_dir"

        # Loop through the configurations and backup if not a symlink
        for config in "${!config_paths[@]}"; do
            local path="${config_paths[$config]}"
            if [ -e "$path" ] && [ ! -L "$path" ]; then # Check if file or directory exists and is not a symlink
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


# Function to check and install required packages
check_required_packages() {
    local missing_packages=()
    for cmd in "${!command_to_package[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_packages+=("${command_to_package[$cmd]}")
        fi
    done
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "Missing required packages: ${missing_packages[*]}. Installing..."
        sudo apt-get update -qq && sudo apt-get install -qq -y "${missing_packages[@]}"
    fi
}

# Function to install Zsh and Oh-My-Zsh
configure_zsh() {    
    echo "Configuring Zsh..."
    echo $HOME
    if ! command -v zsh &> /dev/null; then
        echo "Zsh is not installed. Please install it first."
        return
    fi
    rm -rf $HOME/.oh-my-zsh
    sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k   
    rm $HOME/.zshrc
    ln -s $repo_dir/.zshrc $HOME/.zshrc
    ln -s $repo_dir/.p10k.zsh $HOME/.p10k.zsh
}


# Function to install Neovim
install_nvim() {
    echo "Installing Neovim..."
    tmp_dir=$(mktemp -d /tmp/nvim-XXXXXX)
    
    wget -P $tmp_dir https://github.com/neovim/neovim/releases/download/v0.10.1/nvim.appimage
    chmod +x $tmp_dir/nvim.appimage
    (cd $tmp_dir && ./nvim.appimage --appimage-extract > /dev/null)
    
    # Remove /opt/nvim if it exists
    sudo rm -rf /opt/nvim
    sudo mv $tmp_dir/squashfs-root /opt/nvim
    sudo ln -sf /opt/nvim/AppRun /usr/bin/nvim
    
    rm -rf $tmp_dir $HOME/.config/nvim
    ln -s $repo_dir/.config/nvim $HOME/.config/nvim
}

install_lazygit() {
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
}

install_fastfetch(){
    sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
    sudo apt-get update
    sudo apt-get install fastfetch
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
    ln -s $repo_dir/.tmux.conf $HOME/.tmux.conf
    tmux start-server
    tmux new-session -d
    bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    tmux kill-server
}



setup_git() {

    # Add global gitignore file
    ln -s $repo_dir/.gitignore_global $HOME/.gitignore_global
    git config --global core.excludesfile ~/.gitignore_global

    # Get the current Git username and email
    git_user_name=$(git config --global user.name)
    git_email=$(git config --global user.email)

    # Check if both username and email are already set
    if [ -n "$git_user_name" ] && [ -n "$git_email" ]; then
        echo "Git user name and email already set."
        return
    fi

    # If not set, prompt the user to enter the details
    read -p "Enter your git user name: " git_user_name
    read -p "Enter your git email: " git_email

    # Set the new git username and email
    git config --global user.name "$git_user_name"
    git config --global user.email "$git_email"
}

# Main script execution
display_warning
check_required_packages
backup_config
configure_zsh
install_nvim
install_fastfetch
install_rust_stuff
install_lazygit
configure_tmux
setup_git

echo "Installation completed successfully."
