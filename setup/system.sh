#!/usr/bin/env bash

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$REPO_ROOT/setup/utils.sh"

COMMON_PACKAGES=(
    "curl" "wget" "git"
    "zsh" "tmux" "fzf" "jq"
    "unzip" "zip"
    "direnv"
)
# The debian/ubuntu list is long because this also supports minimal installs.
DEBIAN_PACKAGES=(
    "${COMMON_PACKAGES[@]}"
    "build-essential" "gcc" "g++" "make" "cmake"
    "zlib1g-dev" "libbz2-dev" "liblzma-dev" "xz-utils" "tar"      # Compression and archiving
    "libreadline-dev" "libsqlite3-dev" "libffi-dev" "libyaml-dev" # Language runtime dependencies
    "libncursesw5-dev" "tk-dev"                                   # Terminal and UI libraries
    "libssl-dev" "libxml2-dev" "libxmlsec1-dev"                   # Networking and XML libraries
    "clang" "libclang-dev"
    "imagemagick" # snacks.nvim image converts non-PNG formats with magick
)

UBUNTU_PACKAGES=(
    "${DEBIAN_PACKAGES[@]}"
    "software-properties-common" # for add-apt-repository
    "fastfetch"
)
# package:ppa pairs for packages that some Ubuntu releases lack
UBUNTU_PPA_FALLBACKS=(
    "fastfetch:ppa:zhangsongcui3371/fastfetch" # in Ubuntu from 25.04 on
)

TERMUX_PACKAGES=(
    "${COMMON_PACKAGES[@]}"
    "fastfetch"
    "clang" "make" "openssl" "libffi" "zlib" "libbz2" "readline" "sqlite" "ncurses" "libcrypt"
)

MACOS_PACKAGES=(
    "${COMMON_PACKAGES[@]}"
    "lazygit"
    "superfile"
    "herdr"
    "fastfetch"
    "mise"
    "tmux-mem-cpu-load" # tmux.conf status line calls the bare binary; no apt package exists
    "imagemagick"       # snacks.nvim image converts non-PNG formats with magick
    # Homebrew installs the Xcode Command Line Tools, which provide the build toolchain
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

    [[ "$DISTRO" == "ubuntu" ]] && add_fallback_ppas
    install_packages "${PACKAGES[@]}"
    link_apt_names
}

# apt ships bat and fd as batcat and fdfind, and the zsh config calls bat and fd
link_apt_names() {
    local pair apt_name upstream
    for pair in batcat:bat fdfind:fd; do
        apt_name=${pair%%:*}
        upstream=${pair##*:}
        command -v "$upstream" &>/dev/null && continue
        command -v "$apt_name" &>/dev/null || continue
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v "$apt_name")" "$HOME/.local/bin/$upstream"
        log "Linked $upstream -> $apt_name"
    done
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
    if [[ "$EUID" -eq 0 ]]; then
        error "❌ Do not run as root. It will prompt you for sudo when needed."
        exit 1
    fi

    # SUDO_USER is set even when EUID != 0 if invoked via `sudo -u $USER`
    if [[ -n "$SUDO_USER" ]]; then
        error "❌ Do not run this script with 'sudo'"
        exit 1
    fi

    if [[ "$DISTRO" != "darwin" ]]; then
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

    if [[ ! -e /etc/localtime ]]; then
        run_quiet "Setting timezone to UTC" sudo ln -s /usr/share/zoneinfo/UTC /etc/localtime
    fi
    run_quiet "Updating apt" sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    if [[ "$update_requested" == true ]]; then
        run_quiet "Upgrading apt packages" sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
    fi
}

# Adds the UBUNTU_PPA_FALLBACKS PPA of each package in PACKAGES that apt can't install as is.
# A package whose PPA doesn't publish this release either is dropped from PACKAGES.
add_fallback_ppas() {
    local pair pkg ppa codename ppas=()
    codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
    for pair in "${UBUNTU_PPA_FALLBACKS[@]}"; do
        pkg=${pair%%:*}
        ppa=${pair#*:}
        [[ " ${PACKAGES[*]} " == *" $pkg "* ]] || continue
        apt-cache policy "$pkg" 2>/dev/null | grep -q 'Candidate: [^(]' && continue
        if curl -fsI "https://ppa.launchpadcontent.net/${ppa#ppa:}/ubuntu/dists/$codename/Release" &>/dev/null; then
            ppas+=("$ppa")
        else
            warn "Skipping $pkg: neither apt nor $ppa has it for $codename"
            local p kept=()
            for p in "${PACKAGES[@]}"; do [[ "$p" != "$pkg" ]] && kept+=("$p"); done
            PACKAGES=("${kept[@]}")
        fi
    done
    [[ ${#ppas[@]} -eq 0 ]] && return
    if ! command -v add-apt-repository &>/dev/null; then
        run_quiet "Installing add-apt-repository" sudo DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
    fi
    add_apt_repositories "${ppas[@]}"
}

add_apt_repositories() {
    local repos=("$@")
    for repo in "${repos[@]}"; do
        run_quiet "Adding PPA: $repo" sudo add-apt-repository -y "$repo"
    done
    if [[ "${#repos[@]}" -gt 0 ]]; then
        run_quiet "Refreshing apt after adding PPAs" sudo DEBIAN_FRONTEND=noninteractive apt-get -y update
    fi
}

setup_brew() {
    if ! command -v brew &>/dev/null; then
        local installer
        if ! installer=$(fetch_installer https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh); then
            error "❌ Failed to download the Homebrew installer."
            return 1
        fi
        sudo -v
        run_quiet "Installing Homebrew" env NONINTERACTIVE=1 /bin/bash -c "$installer"
        load_brew
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
        run_quiet "Installing apt packages" sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
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
    set -e
    main_system "$@"
fi
