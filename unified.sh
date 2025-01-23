#!/usr/bin/env bash
# Unified installation script for Ubuntu/Debian/MacOS/Termux
# Do not run with sudo - script will invoke it when needed

set -e  # Exit on error

# Detect OS
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

# Check if running with sudo
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

need_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        return 1  # root doesn't need sudo
    else
        return 0  # non-root needs sudo
    fi
}


# Basic requirements by OS

BASIC_REQUIREMENTS=(
    "ubuntu:apt-transport-https ca-certificates curl wget git sudo software-properties-common gnupg"
    "debian:apt-transport-https ca-certificates curl wget git sudo software-properties-common gnupg"
    "macos:"
    "termux:"
)


# Installation methods and packages
INSTALLATIONS=(
    "curl:ubuntu|apt|curl:debian|apt|curl:termux|pkg|curl:macos|brew|curl"
    "wget:ubuntu|apt|wget:debian|apt|wget:termux|pkg|wget:macos|brew|wget"
    "git:ubuntu|apt|git:debian|apt|git:termux|pkg|git:macos|brew|git"
    "cmake:ubuntu|apt|cmake:debian|apt|cmake:termux|pkg|cmake:macos|brew|cmake"
    "gcc:ubuntu|apt|gcc:debian|apt|gcc:macos|brew|gcc"
    "g++:ubuntu|apt|g++:debian|apt|g++"
    "zsh:ubuntu|apt|zsh:debian|apt|zsh:termux|pkg|zsh:macos|brew|zsh"
    "tmux:ubuntu|apt|tmux:debian|apt|tmux:termux|pkg|tmux:macos|brew|tmux"
    "bat:ubuntu|apt|bat:debian|apt|bat:termux|pkg|bat:macos|brew|bat"
    "ripgrep:ubuntu|apt|ripgrep:debian|apt|ripgrep:termux|pkg|ripgrep:macos|brew|ripgrep"
    "fd-find:ubuntu|apt|fd-find:debian|apt|fd-find:termux|pkg|fd:macos|brew|fd"
    "fzf:ubuntu|apt|fzf:debian|apt|fzf:termux|pkg|fzf:macos|brew|fzf"
    "eza:ubuntu|deb|https://github.com/eza-community/eza/releases/latest:macos|brew|eza"
    "zoxide:ubuntu|deb|https://github.com/ajeetdsouza/zoxide/releases/latest:macos|brew|zoxide"
    "python3.11:ubuntu|ppa|ppa:deadsnakes/ppa,python3.11:macos|brew|python@3.11"
    "node:ubuntu|custom|curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh:macos|brew|node:termux|pkg|nodejs"
    "nvim:ubuntu|appimage|https://github.com/neovim/neovim/releases/latest:macos|brew|neovim:termux|pkg|neovim"
    "lazygit:ubuntu|binary|https://github.com/jesseduffield/lazygit/releases/latest:macos|brew|lazygit:termux|pkg|lazygit"
    "fastfetch:ubuntu|ppa|ppa:zhangsongcui3371/fastfetch,fastfetch:macos|brew|fastfetch"
)

# Repository directory
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Display initial warning
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
# Package management functions
install_brew() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for current session
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

get_basic_requirements() {
    local os=$1
    for req in "${BASIC_REQUIREMENTS[@]}"; do
        if [[ $req == ${os}:* ]]; then
            echo "${req#*:}"
            return 0
        fi
    done
    return 1
}

get_package_info() {
    local package=$1
    local os=$2
    for p in "${INSTALLATIONS[@]}"; do
        if [[ $p == ${package}:* ]]; then
            echo "$p" | tr ':' '\n' | grep "^${os}|" | cut -d'|' -f2,3
            return 0
        fi
    done
    return 1
}


nstall_basic_requirements() {
    local os=$1
    local requirements=$(get_basic_requirements "$os")
    
    if [ -n "$requirements" ]; then
        echo "Installing basic requirements for $os..."
        case $os in
            ubuntu|debian)
                if need_sudo; then
                    sudo apt-get update -qq
                    sudo apt-get install -qq -y $requirements
                else
                    apt-get update -qq
                    apt-get install -qq -y $requirements
                fi
                ;;
        esac
    fi
}


setup_package_manager() {
    local os=$1
    case $os in
        ubuntu|debian)
            if need_sudo; then
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

install_package() {
    local os=$1
    local method=$2
    local package=$3
    local dependencies=$4

    echo "Installing $package..."
    
    case $method in
        apt)
            if need_sudo; then
                sudo apt-get install -y $package
            else
                apt-get install -y $package
            fi
            ;;
        brew)
            brew install $package
            ;;
        pkg)
            pkg install -y $package
            ;;
        ppa)
            # Format: ppa:user/ppa,package
            IFS=',' read -r ppa_name package_name <<< "$package"
            if need_sudo; then
                sudo add-apt-repository -y "$ppa_name"
                sudo apt-get update -qq
                sudo apt-get install -y "$package_name"
            else
                add-apt-repository -y "$ppa_name"
                apt-get update -qq
                apt-get install -y "$package_name"
            fi
            ;;
        deb)
            local tmp_dir=$(mktemp -d)
            wget -qO "$tmp_dir/${package##*/}.deb" "$package"
            if need_sudo; then
                sudo dpkg -i "$tmp_dir/${package##*/}.deb"
            else
                dpkg -i "$tmp_dir/${package##*/}.deb"
            fi
            rm -rf "$tmp_dir"
            ;;
        appimage)
            local tmp_dir=$(mktemp -d)
            wget -P "$tmp_dir" "$package/nvim.appimage"
            chmod +x "$tmp_dir/nvim.appimage"
            (cd "$tmp_dir" && ./nvim.appimage --appimage-extract > /dev/null)
            if need_sudo; then
                sudo rm -rf /opt/nvim
                sudo mv "$tmp_dir/squashfs-root" /opt/nvim
                sudo ln -sf /opt/nvim/AppRun /usr/bin/nvim
            else
                rm -rf /opt/nvim
                mv "$tmp_dir/squashfs-root" /opt/nvim
                ln -sf /opt/nvim/AppRun /usr/bin/nvim
            fi
            rm -rf "$tmp_dir"
            ;;
        binary)
            local tmp_dir=$(mktemp -d)
            local version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -Lo "$tmp_dir/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"
            tar xf "$tmp_dir/lazygit.tar.gz" -C "$tmp_dir" lazygit
            if need_sudo; then
                sudo install "$tmp_dir/lazygit" /usr/local/bin
            else
                install "$tmp_dir/lazygit" /usr/local/bin
            fi
            rm -rf "$tmp_dir"
            ;;
        custom)
            eval "$package"
            ;;
    esac
}

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
    )
    
    CONFIG_PATHS=(
        "$HOME/.oh-my-zsh"
        "$HOME/.zshrc"
        "$HOME/.p10k.zsh"
        "$HOME/.tmux.conf"
        "$HOME/.tmux"
        "$HOME/.config/nvim"
        "$HOME/.gitignore_global"
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
    if ! command -v zsh &> /dev/null; then
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

    # Create symlinks
    ln -sf "$repo_dir/zshrc" "$HOME/.zshrc"
    ln -sf "$repo_dir/p10k.zsh" "$HOME/.p10k.zsh"
}

configure_tmux() {
    echo "Configuring tmux..."
    if ! command -v tmux &> /dev/null; then
        echo "Tmux is not installed. Installation failed."
        return 1
    fi

    # Install TPM
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ln -sf "$repo_dir/tmux.conf" "$HOME/.tmux.conf"

    # Install plugins
    tmux start-server
    tmux new-session -d
    "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    tmux kill-server
}

configure_nvim() {
    echo "Configuring Neovim..."
    if ! command -v nvim &> /dev/null; then
        echo "Neovim is not installed. Installation failed."
        return 1
    fi

    mkdir -p "$HOME/.config"
    ln -sf "$repo_dir/nvim" "$HOME/.config/nvim"
}

setup_git() {
    echo "Configuring Git..."
    
    # Add global gitignore
    ln -sf "$repo_dir/gitignore_global" "$HOME/.gitignore_global"
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
    
    for p in "${INSTALLATIONS[@]}"; do
        local package=${p%%:*}
        local info=$(get_package_info "$package" "$os")
        if [ -n "$info" ]; then
            local method=$(echo "$info" | cut -d'|' -f1)
            local package_info=$(echo "$info" | cut -d'|' -f2)
            
            echo "Installing $package using $method..."
            install_package "$os" "$method" "$package_info"
        fi
    done
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

    # Setup package manager and install basic requirements
    setup_package_manager "$os"
    install_basic_requirements "$os"

    # Backup existing configurations
    backup_config

    # Install all required packages
    install_packages "$os"

    # Configure everything
    configure_zsh
    configure_tmux
    configure_nvim
    setup_git

    echo "Installation completed successfully!"
    echo "Please restart your terminal and run 'zsh' to complete the setup."
}

# Run main function
main

