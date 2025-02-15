#!/usr/bin/env bash
# Unified installation script for Ubuntu/Debian/MacOS/Termux
# Do not run with sudo - script will invoke it when needed

####################
# Global variables #
####################

# Repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define packages that should be installed across all environments
PACKAGES=(
    # basic requirements
    "curl"
    "wget"
    "git"
    #build tools
    "cmake"
    "gcc"
    "g++"
    # shell and multiplexer
    "zsh"
    "tmux"
    # modern CLI tools
    "bat"
    "ripgrep"
    "fd-find"
    "fzf"
    "eza"
    "zoxide"
    "fastfetch"
    # development tools
    "nvim"
    "lazygit"
    # programming languages
    "python"
    "node"
    "go"
)

# Define custom installation methods for specific packages per OS
declare -A CUSTOM_INSTALL
CUSTOM_INSTALL["ubuntu:python"]="add-apt-repository -y ppa:deadsnakes/ppa && apt install -y python3.11"
CUSTOM_INSTALL["macos:python"]="quiet_brew install python@3.11"
CUSTOM_INSTALL["ubuntu:eza"]="install_eza"
CUSTOM_INSTALL["ubuntu:nvim"]="install_nvim"
CUSTOM_INSTALL["ubuntu:node"]="curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash"
CUSTOM_INSTALL["macos:go"]="install_go"
CUSTOM_INSTALL["macos:g++"]="true"
CUSTOM_INSTALL["macos:cmake"]="true"
CUSTOM_INSTALL["macos:fd-find"]="quiet_brew install fd"

#####################
# Utility functions #
#####################

display_warning() {
    echo "This script will install and configure:"
    echo "- Shell: Zsh with Oh-My-Zsh and Powerlevel10k"
    echo "- Terminal multiplexer: Tmux with plugins"
    echo "- Editor: Neovim with custom config"
    echo "- Modern CLI tools: bat, ripgrep, fd, fzf, eza, zoxide"
    echo "- Development tools: Python, Node.js, Git"
    echo
    echo "It will backup existing configurations to ~/config-backup-<timestamp>"
    echo
    if [ "$1" = "debian" ]; then
        echo "WARNING: Running on Debian. Some features might not work as expected."
        echo
    fi
    read -p "Press Enter to continue or Ctrl+C to cancel..."
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
        ubuntu)
            echo "ubuntu"
            return
            ;;
        debian)
            echo "debian"
            return
            ;;
        esac
    elif [ -f /data/data/com.termux/files/usr/bin/pkg ]; then
        echo "termux"
        return
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
        return
    fi
    echo "unsupported"
}

check_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        if [ -z "$SUDO_USER" ]; then
            echo "Running as root, continuing..."
            return 0
        else
            echo "This script should not be run with sudo. Please run as normal user."
            exit 1
        fi
    fi
}

##########################
# Installation functions #
##########################
quiet_brew() {
    grep_list="is already installed|To reinstall|brew reinstall|the latest version is already installed"
    brew install "$1" >/dev/null 2>&1 | grep -Ev "$grep_list"
}

install_eza() {
    mkdir -p /etc/apt/keyrings &&
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/eza.gpg &&
        echo 'deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main' | tee /etc/apt/sources.list.d/eza.list &&
        apt update && apt install -y eza
}

install_go() {
    quiet_brew install go
    echo 'export GOROOT=$(go env GOROOT)' >>~/.zprofile
    echo 'export GOPATH=$(go env GOPATH)' >>~/.zprofile
    echo 'export PATH=$GOPATH/bin:$PATH' >>~/.zprofile
    quiet_brew install direnv
    if ! grep -q 'eval "$(direnv hook zsh)"' ~/.zshrc; then
        echo 'eval "$(direnv hook zsh)"' >>~/.zshrc
    fi
    quiet_brew install golangci-lint # linter
    quiet_brew install clang-format  # protobuf formatter
}

install_nvim() {
    wget https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -O /usr/local/bin/nvim
    chmod +x /usr/local/bin/nvim
}

################################
# Package management functions #
################################
# Install brew, apt and pkg are pre-installed in Ubuntu/Debian and Termux respectively
install_brew() {
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for current session
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

setup_package_manager() {
    local os=$1
    case $os in
    ubuntu | debian)
        # if needed, run with sudo
        if [ "$(id -u)" -eq 0 ]; then
            sudo apt-get update -qq
        else
            apt-get update -qq
        fi
        ;;
    macos)
        install_brew
        brew update
        ;;
    termux)
        pkg update -y
        ;;
    esac
}

###########################
# Configuration functions #
###########################
backup_config() {
    local config_backup_dir="$HOME/config-backup-$(date +%Y%m%d%H%M%S)"

    # Define arrays for config names and paths separately
    CONFIG_NAMES=(
        "oh-my-zsh"
        "zshrc"
        "p10k.zsh"
        "tmux.conf"
        "tmux"
        "nvim"
        "gitignore_global"
        "karabiner"
    )

    CONFIG_PATHS=(
        "$HOME/.oh-my-zsh"
        "$HOME/.zshrc"
        "$HOME/.p10k.zsh"
        "$HOME/.tmux.conf"
        "$HOME/.tmux"
        "$HOME/.config/nvim"
        "$HOME/.gitignore_global"
        "$HOME/.config/karabiner"
    )

    local config_exists=false
    for path in "${CONFIG_PATHS[@]}"; do
        if [ -e "$path" ] && [ ! -L "$path" ]; then
            config_exists=true
            break
        fi
    done

    if [ "$config_exists" = true ]; then
        echo "Creating backup directory: $config_backup_dir"
        mkdir -p "$config_backup_dir"

        local i=0
        while [ $i -lt ${#CONFIG_PATHS[@]} ]; do
            local path="${CONFIG_PATHS[$i]}"
            local name="${CONFIG_NAMES[$i]}"
            if [ -e "$path" ] && [ ! -L "$path" ]; then
                echo "Backing up existing $name configuration..."
                cp -r "$path" "$config_backup_dir/"
                rm -rf "$path"
            fi
            i=$((i + 1))
        done
    fi
}

configure_zsh() {
    echo "Configuring Zsh..."
    if ! command -v zsh &>/dev/null; then
        echo "Zsh is not installed. Installation failed."
        return 1
    fi

    # Remove existing oh-my-zsh if present
    rm -rf "$HOME/.oh-my-zsh"

    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install plugins and theme
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab
    # Create symlinks
    ln -sf "$REPO_DIR/zshrc" "$HOME/.zshrc"
    ln -sf "$REPO_DIR/p10k.zsh" "$HOME/.p10k.zsh"
}

configure_tmux() {
    echo "Configuring tmux..."
    if ! command -v tmux &>/dev/null; then
        echo "Tmux is not installed. Installation failed."
        return 1
    fi

    if [ -n "$TMUX" ]; then
        echo "Re-run this script outside of tmux to update tmux configuration. Skipping."
        return 0
    fi
    # Install TPM
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ln -sf "$REPO_DIR/tmux.conf" "$HOME/.tmux.conf"

    # Install plugins
    tmux start-server
    tmux new-session -d
    "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    tmux kill-server
}

configure_nvim() {
    echo "Configuring Neovim..."
    if ! command -v nvim &>/dev/null; then
        echo "Neovim is not installed. Installation failed."
        return 1
    fi

    mkdir -p "$HOME/.config"
    ln -sfn "$REPO_DIR/nvim" "$HOME/.config/nvim"
}

setup_git() {
    echo "Configuring Git..."

    # Add global gitignore
    ln -sf "$REPO_DIR/gitignore_global" "$HOME/.gitignore_global"
    git config --global core.excludesfile ~/.gitignore_global

    # Check existing git config
    local git_user_name=$(git config --global user.name)
    local git_email=$(git config --global user.email)

    if [ -z "$git_user_name" ] || [ -z "$git_email" ]; then
        echo "Git user not configured."
        read -p "Enter your git user name: " git_user_name
        read -p "Enter your git email: " git_email
        git config --global user.name "$git_user_name"
        git config --global user.email "$git_email"
    else
        echo "Git already configured for user: $git_user_name"
    fi
}

install_packages() {
    local os=$1
    local to_install=()

    for package in "${PACKAGES[@]}"; do
        if ! [ -n "${CUSTOM_INSTALL["$os:$package"]}" ]; then
            to_install+=("$package")
        fi
    done

    # Batch install non-custom packages
    if [ "${#to_install[@]}" -gt 0 ]; then
        case $os in
        ubuntu | debian)
            echo "Installing batch packages with apt: ${to_install[*]}"
            if need_sudo; then
                sudo apt-get install -y "${to_install[@]}"
            else
                apt-get install -y "${to_install[@]}"
            fi
            ;;
        macos)
            echo "Installing batch packages with brew: ${to_install[*]}"
            quiet_brew install "${to_install[@]}"
            ;;
        termux)
            echo "Installing batch packages with pkg: ${to_install[*]}"
            pkg install -y "${to_install[@]}"
            ;;
        esac
    fi

    # Install custom packages separately
    for package in "${PACKAGES[@]}"; do
        if [ -n "${CUSTOM_INSTALL["$os:$package"]}" ]; then
            eval "${CUSTOM_INSTALL["$os:$package"]}"
        fi
    done
}

setup_macos() {
    # Install additional packages for MacOS and their configurations
    # kitty terminal
    quiet_brew install kitty 2>&1 | grep -Ev "the latest version is already installed"
    ln -sf "$REPO_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"

    # karabiner-elements
    # symlink karabiner dir to config=
    ln -sfn "$REPO_DIR/karabiner" "$HOME/.config/karabiner"
    quiet_brew install --cask karabiner-elements
}

main() {
    # Check if running with sudo
    check_sudo

    # Detect OS
    local os=$(detect_os)
    if [ "$os" = "unsupported" ]; then
        echo "Unsupported operating system"
        exit 1
    fi

    # Display warning and get confirmation
    display_warning "$os"

    # Setup package manager
    setup_package_manager "$os"

    # Backup existing configurations
    backup_config

    # Install all required packages
    install_packages "$os"

    # Configure everything
    configure_zsh
    configure_tmux
    configure_nvim
    setup_git
    if [ "$os" = "macos" ]; then
        setup_macos
    fi

    echo "Installation completed successfully!"
    echo "Please restart your terminal and run 'zsh' to complete the setup."
}

# Run main function
main
