#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

PACKAGES=(
    # basic requirements, probably already installed, but just in case, for example bare docker image doesn't have even git or sudo, not to mention curl or wget
    "curl" # apt, brew, pre-installed in wsl ubuntu, not in docker
    "wget" # apt, brew, pre-installed in wsl ubuntu, not in docker
    "git"  # apt, brew, pre-installed in wsl ubuntu, not in docker
    #build tools, possibly xcode installs some of these..
    "cmake" # apt, brew
    "gcc"   # apt, brew
    "g++"   # apt, brew, possibly x
    # shell and multiplexer
    "zsh"  # apt, pre-installed on mac now-a-days,
    "tmux" # apt, brew
    # modern CLI tools
    "bat"       # apt, brew
    "ripgrep"   # apt, brew
    "fd-find"   # apt, brew
    "fzf"       # apt, brew
    "fastfetch" # available in brew, need to add ppa:zhangsongcui3371/fastfetch for ubuntu
    # general utilities
    "unzip" # apt, brew
    "zip"   # apt, brew
    "tar"   # apt, brew
)


main_system() {
    check_permissions
    detect_os
    setup_package_manager
    install_build_tools
    install_packages "${PACKAGES[@]}"
    install_lazygit
}

detect_os() {
    OS=$(uname -s)
    if [[ "$OS" == "Linux" ]]; then
        [[ -f /etc/os-release ]] && DISTRO=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)
    elif [[ "$OS" == "Darwin" ]]; then
        DISTRO="Darwin"
    else
        error "Unsupported OS: "$OS
        exit 1
    fi
    DISTRO=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')
}

check_permissions() {
    # Prevent running as root
    if [[ "$EUID" -eq 0 ]]; then
        error "❌ Do not run this script as root. Use a regular user with sudo."
        exit 1
    fi

    # Prevent using sudo to invoke the script
    if [[ -n "$SUDO_USER" ]]; then
        error "❌ Do not run this script with 'sudo'. Just run it normally."
        exit 1
    fi

    # Detect OS early for sudo check
    if [[ "$OS" != "darwin" ]]; then
        if ! command -v sudo &>/dev/null; then
            error "❌ 'sudo' is required but not found. Please install it and try again."
            exit 1
        fi
    fi
}

install_build_tools() {
    if [[ $OS == "Linux" ]]; then
        build_deps=(
            "build-essential" "libssl-dev" "zlib1g-dev" "libbz2-dev" "libreadline-dev" "libsqlite3-dev" "curl" "git"
            "libncursesw5-dev" "xz-utils" "tk-dev" "libxml2-dev" "libxmlsec1-dev" "libffi-dev" "liblzma-dev"
        )
        case "$DISTRO" in
        ubuntu | debian)
            run_quiet "Installing build dependencies" sudo apt-get install -y "${build_deps[@]}"
            ;;
        termux)
            run_quiet "Installing build dependencies" pkg install -y "${build_deps[@]}"
            ;;
        darwin)
            return
            ;;
        esac
    fi
}

setup_package_manager() {
    case "$DISTRO" in
    ubuntu | debian)
        setup_apt
        ;;
    termux)
        run_quiet "Updating pkg for termux" pkg update -y -qq
        ;;
    darwin)
        setup_brew
        ;;
    *)
        error "Unsupported OS: $DISTRO"
        exit 1
        ;;
    esac
}

setup_apt() {
    run_quiet "Setting up apt for $DISTRO" bash -c '
        export DEBIAN_FRONTEND=noninteractive
        sudo ln -sf /usr/share/zoneinfo/UTC /etc/localtime &&
        sudo apt-get -y update &&
        sudo apt-get -y install software-properties-common &&
        sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch &&
        sudo apt-get -y update
    '
}

setup_brew() {
    if ! command -v brew &>/dev/null; then
        run_quiet "Installing brew" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        run_quiet "Updating brew" brew update
    fi
}

get_uninstalled_packages() {
    local packages=("$@")
    local not_installed=()

    for package in "${packages[@]}"; do
        case "$DISTRO" in
        ubuntu | debian)
            dpkg -s "$package" &>/dev/null || not_installed+=("$package")
            ;;
        termux)
            pkg list-installed "$package" &>/dev/null || not_installed+=("$package")
            ;;
        darwin)
            [[ "$package" == "fd-find" ]] && package="fd"
            local skip_list=("g++" "tar")
            [[ " ${skip_list[@]} " =~ " ${package} " ]] && continue
            [[ -z $(brew ls --versions "$package") ]] && not_installed+=("$package")
            ;;
        esac
    done
    echo "${not_installed[@]}"
}

install_packages() {
    local packages=("$@")
    local not_installed=()
    not_installed=($(get_uninstalled_packages "${packages[@]}"))
    [[ ${#not_installed[@]} -eq 0 ]] && return
    case "$DISTRO" in
    ubuntu | debian)
        run_quiet "Installing packages" sudo apt-get install -y "${not_installed[@]}"
        ;;
    termux)
        run_quiet "Installing packages" pkg install -y "${not_installed[@]}"
        ;;
    darwin)
        run_quiet "Installing packages" brew install "${not_installed[@]}"
        ;;
    esac
}

install_lazygit() {
    if [[ "$OS" != "Linux" ]]; then
        return
    fi

    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"

    if command -v lazygit &>/dev/null; then
        current_version=$(lazygit -v | grep -Po -m 1 'version=\K[^,]*' | head -1)
        if [[ "$LAZYGIT_VERSION" == "$current_version" ]]; then
            log "Already have the latest version of lazygit: $LAZYGIT_VERSION"
            return
        fi
    fi

    tmp_dir=$(mktemp -d)

    run_quiet "Installing lazygit $LAZYGIT_VERSION" bash -c '
        set -e
        curl -Lo "$0/lazygit.tar.gz" "$1" &&
        tar -xzf "$0/lazygit.tar.gz" -C "$0" &&
        sudo install "$0/lazygit" -D -t /usr/local/bin
    ' "$tmp_dir" "$LAZYGIT_URL"

    'rm -rf "$tmp_dir"'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_system "$@"
fi
