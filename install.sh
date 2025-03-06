#!/usr/bin/env bash
# Unified installation script for Ubuntu/Debian/MacOS/Termux
# Do not run with sudo - script will invoke it when needed

####################
# Global variables #
####################

# Repository directory
REPO_DIR="$(git rev-parse --show-toplevel)"

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
    #   "go"
)

need_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "sudo"
    else
        echo ""
    fi
}

# Define custom installation methods for specific packages per OS
declare -A CUSTOM_INSTALL
CUSTOM_INSTALL["ubuntu:lazygit"]="install_lazygit"
CUSTOM_INSTALL["ubuntu:eza"]="install_eza"
CUSTOM_INSTALL["ubuntu:nvim"]="install_nvim"
CUSTOM_INSTALL["ubuntu:zoxide"]="install_zoxide"
CUSTOM_INSTALL["ubuntu:python"]="install_python"
CUSTOM_INSTALL["ubuntu:go"]="install_go_ubuntu"
CUSTOM_INSTALL["ubuntu:node"]="curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash"
CUSTOM_INSTALL["macos:g++"]="true"   # installed with Xcode when brew was installed
CUSTOM_INSTALL["macos:cmake"]="true" # installed with Xcode when brew was installed
CUSTOM_INSTALL["macos:fd-find"]="quiet_brew install fd"
CUSTOM_INSTALL["macos:python"]="quiet_brew install python@3.11"
CUSTOM_INSTALL["macos:go"]="install_go"

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
    $(need_sudo) mkdir -p /etc/apt/keyrings
    $(need_sudo) wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | $(need_sudo) gpg --dearmor -o /etc/apt/keyrings/eza. >/dev/null 2>&1
    $(need_sudo) echo 'deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main' | $(need_sudo) tee /etc/apt/sources.list.d/eza.list >/dev/null 2>&1
    $(need_sudo) apt update && $(need_sudo) apt install -y eza >/dev/null 2>&1
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

install_go_ubuntu() {
    GO_VERSION="1.23.6"
    GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TARBALL}"
    GO_INSTALL_DIR="/usr/local/go"

    # Download and install Go only if not already installed or version differs
    if [ ! -x "${GO_INSTALL_DIR}/bin/go" ] || [ "$(${GO_INSTALL_DIR}/bin/go version | awk '{print $3}')" != "go${GO_VERSION}" ]; then
        wget -q "${GO_URL}" -O "/tmp/${GO_TARBALL}"
        $(need_sudo) rm -rf "${GO_INSTALL_DIR}"
        $(need_sudo) tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
        rm "/tmp/${GO_TARBALL}"
    fi

    # Ensure Go environment variables are correctly set without duplication
    ZPROFILE=~/.zprofile
    grep -qxF 'export PATH=$PATH:/usr/local/go' "$ZPROFILE" || echo 'export PATH=$PATH:/usr/local/go' >>"$ZPROFILE"
    grep -qxF 'export GOROOT=$(go env GOROOT)' "$ZPROFILE" || echo 'export GOROOT=$(go env GOROOT)' >>"$ZPROFILE"
    grep -qxF 'export GOPATH=$(go env GOPATH)' "$ZPROFILE" || echo 'export GOPATH=$(go env GOPATH)' >>"$ZPROFILE"
    grep -qxF 'export PATH=$GOPATH/bin:$PATH' "$ZPROFILE" || echo 'export PATH=$GOPATH/bin:$PATH' >>"$ZPROFILE"

    # Install required packages only if not installed
    $(need_sudo) apt update -y
    $(need_sudo) apt install -y --no-install-recommends direnv golangci-lint clang-format

    # Ensure direnv is added to ~/.zshrc without duplication
    ZSHRC=~/.zshrc
    grep -qxF 'eval "$(direnv hook zsh)"' "$ZSHRC" || echo 'eval "$(direnv hook zsh)"' >>"$ZSHRC"
}

install_nvim() {
    wget https://github.com/neovim/neovim-releases/releases/latest/download/nvim-linux-x86_64.appimage -O /tmp/nvim
    $(need_sudo) mv /tmp/nvim /usr/local/bin/nvim
    $(need_sudo) chmod +x /usr/local/bin/nvim
}

install_lazygit() {
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    $(need_sudo) install lazygit -D -t /usr/local/bin
    rm lazygit.tar.gz lazygit
}

install_python() {
    $(need_sudo) add-apt-repository -y ppa:deadsnakes/ppa
    $(need_sudo) apt install -y python3.11
}

install_zoxide() {
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
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
        $(need_sudo) apt-get update -qq
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
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null
    rm ~$HOME/.zshrc.pre-oh-my-zsh # no need for backup, we have git
        # Install plugins and theme
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    # Create symlinks
    ln -sf "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"
    ln -sf "$REPO_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"
    ln -sf "$REPO_DIR/zsh/oh-my-posh-taaniel.omp.json" "$HOME/.oh-my-posh.omp.json"
    # Modules
    ln -sf "$REPO_DIR/zsh/python.zsh" "$HOME/.zshrc.python"
}

configure_tmux() {
    echo "Configuring tmux..."
    if ! command -v tmux &>/dev/null; then
        echo "Tmux is not installed. Installation failed."
        return 1
    fi

    # Install TPM
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

    rm -f "$HOME/.tmux.conf"
    ln -sf "$REPO_DIR/tmux.conf" "$HOME/.tmux.conf"

    # Ensure tmux is running before installing plugins
    if ! tmux list-sessions &>/dev/null; then
        tmux start-server
        tmux new-session -d
    fi

    # Install plugins
    "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" >/dev/null

    # Source new configuration
    tmux source-file ~/.tmux.conf
    echo "Tmux configuration updated."

    # Cleanup: If we started tmux, kill it (but only if no real sessions exist)
    if ! tmux list-sessions &>/dev/null; then
        tmux kill-server
    fi
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
            $(need_sudo) apt-get install -y "${to_install[@]}" -qq
            ;;
        macos)
            echo "Installing batch packages with brew: ${to_install[*]}"
            quiet_brew install "${to_install[@]}" >/dev/null
            ;;
        termux)
            echo "Installing batch packages with pkg: ${to_install[*]}"
            pkg install -y "${to_install[@]}" >/dev/null
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
    echo "Please restart your terminal or run exec zsh to apply all changes."
}

# Run main function
main
