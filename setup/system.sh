#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

COMMON_PACKAGES=(
    "curl" "wget" "git"     # General tools
    "zsh" "tmux" "fzf" "jq" # Shell and tools
    "unzip" "zip"           # Compression and archiving
    "direnv"
)
# Note, debian/ubuntu packages are pretty thorough,
# mainly due to this script also supporting minimal debian/ubuntu installs
DEBIAN_PACKAGES=(
    "${COMMON_PACKAGES[@]}"
    "build-essential" "gcc" "g++" "make" "cmake"                  # General compilation tools
    "zlib1g-dev" "libbz2-dev" "liblzma-dev" "xz-utils" "tar"      # Compression and archiving
    "libreadline-dev" "libsqlite3-dev" "libffi-dev" "libyaml-dev" # Language runtime dependencies
    "libncursesw5-dev" "tk-dev"                                   # Terminal and UI libraries
    "libssl-dev" "libxml2-dev" "libxmlsec1-dev"                   # Networking and XML libraries
)

UBUNTU_PACKAGES=(
    "${DEBIAN_PACKAGES[@]}"
    "software-properties-common" # for add-apt-repository
    "fastfetch"                  # requires PPA
)
UBUNTU_PPA_REPOSITORIES=(
    "ppa:zhangsongcui3371/fastfetch"
)

TERMUX_PACKAGES=(
    "${COMMON_PACKAGES[@]}"
    "fastfetch" # available in pkg
    "clang" "make" "openssl" "libffi" "zlib" "libbz2" "readline" "sqlite" "ncurses" "libcrypt"
)

MACOS_PACKAGES=(
    "${COMMON_PACKAGES[@]}"
    "lazygit"   # available in brew
    "fastfetch" # available in brew
    "mise"      # available in brew
    # General Build dependencies are already installed with Xcode which is a prerequisite for Homebrew
)

main_system() {
    local update=false

    for arg in "$@"; do
        case "$arg" in
        --update) update=true ;;
        esac
    done

    detect_os
    check_permissions
    setup_package_manager "$update"

    case "$DISTRO" in
    ubuntu) PACKAGES=("${UBUNTU_PACKAGES[@]}") ;;
    debian) PACKAGES=("${DEBIAN_PACKAGES[@]}") ;;
    termux) PACKAGES=("${TERMUX_PACKAGES[@]}") ;;
    darwin) PACKAGES=("${MACOS_PACKAGES[@]}") ;;
    *)
        error "Unsupported distro: $DISTRO"
        exit 1
        ;;
    esac

    install_packages "${PACKAGES[@]}"
}

detect_os() {
    OS=$(uname -s)
    if [[ "$PREFIX" == *com.termux* ]]; then
        DISTRO="termux"
        return
    fi
    if [[ "$OS" == "Linux" ]]; then
        [[ -f /etc/os-release ]] && DISTRO=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)
    elif [[ "$OS" == "Darwin" ]]; then
        DISTRO="darwin"
    else
        error "Unsupported OS: $OS"
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
        error "❌ Do not run this script with 'sudo'"
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

setup_package_manager() {
    local update_requested="$1"

    case "$DISTRO" in
    ubuntu)
        setup_apt "$update_requested"
        add_apt_repositories "${UBUNTU_PPA_REPOSITORIES[@]}"
        ;;
    debian)
        setup_apt "$update_requested"
        ;;
    termux)
        run_quiet "Updating pkg" pkg update -y -qq
        if [[ "$update_requested" == true ]]; then
            run_quiet "Upgrading pkg packages" pkg upgrade -y
        fi
        ;;
    darwin)
        setup_brew "$update_requested"
        ;;
    *)
        error "Unsupported OS: $DISTRO"
        exit 1
        ;;
    esac
}

setup_apt() {
    local update_requested="$1"

    run_quiet "Preparing apt" bash -c '
        export DEBIAN_FRONTEND=noninteractive
        sudo ln -sf /usr/share/zoneinfo/UTC /etc/localtime
        sudo apt-get update -y
    '
    if [[ "$update_requested" == true ]]; then
        run_quiet "Upgrading apt packages" sudo apt-get -y upgrade
    fi
}

add_apt_repositories() {
    local repos=("$@")
    for repo in "${repos[@]}"; do
        run_quiet "Adding PPA: $repo" sudo add-apt-repository -y "$repo"
    done
    [[ "${#repos[@]}" -gt 0 ]] && run_quiet "Refreshing apt after adding PPAs" sudo apt-get -y update
}

setup_brew() {
    if ! command -v brew &>/dev/null; then
        run_quiet "Installing Homebrew" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if [[ "$1" == true ]]; then
        run_quiet "Updating & upgrading Homebrew" bash -c "brew update && brew upgrade"
    else
        run_quiet "Updating Homebrew" brew update
    fi
}

install_packages() {
    local packages=("$@")
    [[ ${#packages[@]} -eq 0 ]] && return

    case "$DISTRO" in
    ubuntu | debian)
        run_quiet "Installing apt packages" sudo apt-get install -y "${packages[@]}"
        ;;
    termux)
        run_quiet "Installing pkg packages" pkg install -y "${packages[@]}"
        ;;
    darwin)
        run_quiet "Installing brew packages" brew install "${packages[@]}"
        ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_system "$@"
fi
