#!/usr/bin/env bash
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
    "bat"     # apt, brew
    "ripgrep" # apt, brew
    "fd-find" # apt, brew
    "fzf"     # apt, brew
    "fastfetch" # available in brew, need to add ppa:zhangsongcui3371/fastfetch for ubuntu
)

set -e
source logging.sh
echo "WIP, do not use"
#exit 1


main_system() {
    log "Welcome to my .dotfiles setup script, installing system packages..."
    detect_os
    setup_package_manager
    install_packages "${PACKAGES[@]}"
    install_lazygit
    source wip-setup-userland.sh
    main_userland "$@"
}

detect_os() {
    os=$(uname -s)
    if [[ "$os" == "Linux" ]]; then
        [[ -f /etc/os-release ]] && distro=$(awk -F= '/^ID=/{print $2}' /etc/os-release)
    elif [[ "$os" == "Darwin" ]]; then
        distro="Darwin"
    else
        error "Unsupported OS: "$os
        exit 1
    fi
    distro=$(echo "$distro" | tr '[:upper:]' '[:lower:]')
}

prompt() {
    echo -ne "${YELLOW}$1 ${RESET}"
    read -r _response
    echo "$_response" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

setup_package_manager() {
    case "$distro" in
    ubuntu | debian)
        log "Updating apt..."
        sudo apt-get update -qq >/dev/null
        if [[ ! -f /etc/timezone ]]; then
            [[ -z $(command -v curl) ]] && sudo apt-get install curl -y -qq >/dev/null
        fi
        sudo apt-get install software-properties-common -y -qq >/dev/null
        sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch >/dev/null
        sudo apt-get update -qq >/dev/null
        log " Done"
        ;;
    termux)
        log -n "Updating pkg..."
        pkg update -y -q
        log " Done"
        ;;
    Darwin)
        if ! command -v brew &>/dev/null; then
            if [[ "$(prompt "brew is not installed. Install it? (y/n)")" == "y" ]]; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            else
                error "brew is required for macOS, exiting"
                exit 1
            fi
        fi
        brew update
        ;;
    *)
        error "Unsupported OS: $distro"
        exit 1
        ;;
    esac
}
install_packages() {
    local packages=("$@")
    local not_installed=()

    for package in "${packages[@]}"; do
        case "$distro" in
        ubuntu | debian)
            [[ "$package" == "lazygit" ]] && continue
            dpkg -s "$package" &>/dev/null || not_installed+=("$package")
            ;;
        termux)
            [[ "$package" == "lazygit" ]] && continue
            pkg list-installed "$package" &>/dev/null || not_installed+=("$package")
            ;;
        Darwin)
            [[ "$package" == "fd-find" ]] && package="fd" # name fix for mac
            [[ -z $(brew ls --versions "$package") ]] && not_installed+=("$package")
            ;;
        esac
    done

    log "Installing ${#not_installed[@]} packages..."

    if [[ ${#not_installed[@]} -gt 0 ]]; then
        case "$distro" in
        ubuntu | debian)
            sudo apt-get install -y "${not_installed[@]}" >/dev/null || { error "failed to install packages" && exit 1; } 
            ;;
        termux)

            pkg install -y "${not_installed[@]}" || { error "failed to install packages" && exit 1; }
            ;;
        Darwin)
            grep_list="is already installed|To reinstall|brew reinstall|the latest version is already installed"
            brew install "${not_installed[@]}" 2>&1 | grep -vE "$grep_list" || { error "failed to install packages" && exit 1; }
            ;;
        esac
    fi
}

install_lazygit() {
    if [[ "$os" != "Linux" ]]; then
        return
    fi
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    if command -v lazygit &>/dev/null; then
        current_version=$(lazygit -v | grep -Po -m 1 'version=\K[^,]*' | head -1)
    fi
    if [[ "$LAZYGIT_VERSION" == "$current_version" ]]; then
        log "Already have the latest version of lazygit: $LAZYGIT_VERSION"
        return
    else
        log -n "Installing lazygit $LAZYGIT_VERSION..."
        tmp_dir=$(mktemp -d)
        curl -Lo $tmp_dir/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf $tmp_dir/lazygit.tar.gz -C $tmp_dir
        sudo install $tmp_dir/lazygit -D -t /usr/local/bin/
        rm -rf $tmp_dir
        log " Done"
    fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_system "$@"
fi
