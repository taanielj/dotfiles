#!/usr/bin/env bash
# the most universal shebang, works on most systems, including macos, linux, and wsl, not old bsd systems, but who uses those anyway
# install script for "system" packages
# used for both ubuntu (docker, with non-root user, wsl2, and ubuntu from iso), and macos for now
# i'll have a second script for stuff in user-land
# ideally i want most stuff in user land
# but stuff that is easily available in package managers should be installed here, no need to build like tmux from source
# or whatever.
# this script should be idempotent
# also termux, for nerd cred, i run neovim on my android, btw
# old packages list, i'll keep it here for reference and add as comment if it's available in brew or apt, optionally, if it needs a ppa or tap, i'll add that as well
# to check if package is managed by brew, do:

# WIP DO NOT USE
echo "WIP, do not use"
#exit 1

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
    # "eza"       # annoying... on mac it's just brew install, on ubuntu, you'd need to add a keyring and a ppa, maybe add install this in userland without package manager... hmm, it's also available to install via cargo, it'll take forever to compile but rustc is in userland...
    # "zoxide"    # similar to eza, on mac new version is in brew, but on ubuntu, the version is apt is super old and doesn't work out of the box... cargo it is
    "fastfetch" # available in brew, need to add ppa:zhangsongcui3371/fastfetch for ubuntu
    # development tools
    # "nvim" # install in userland for both from either stable or nightly, but not this script
    # "lazygit" # available in brew, but recommended to tap jesseduffield/lazygit for latest version
    # programming languages
    # sigh, on linux:
    # LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    # curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    # tar xf lazygit.tar.gz lazygit
    # sudo install lazygit -D -t /usr/local/bin/
    # super annoying, no good option to install in user land... why???
    # "python" # available in apt, brew with different names, but probably just use pyenv
    # "node" # install in userland, probably have to keep version fixed to 22 LTS, or use nvm
    # "go" # go.dev recommends to install to /usr/local, but is it possible to install in userland?
    # "java" # userland, using sdkman
    # "rust" # userland, using rustup
)

# script starts here
source logging.sh

os=$(uname -s)

prompt() {
    echo -ne "${YELLOW}$1 ${RESET}"
    read -r _response
    echo "$_response" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

setup_package_manager() {
    # update apt for ubuntu and debian
    if [[ "$os" == "Linux" && -f /etc/os-release ]]; then
        distro=$(awk -F= '/^ID=/{print $2}' /etc/os-release)
        if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
            log -n "Updating apt..."
            sudo apt-get update -qq > /dev/null
            sudo apt-get install software-properties-common -y -qq 
            sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
            sudo apt-get update
            log " Done"
        # maybe add support for other distros later, keep it simple for now
        # elif [[ "$distro" == "arch" || "$distro" == "manjaro" ]]; then
        #     sudo pacman -Syu
        else
            error "Unsupported distro: $distro"
            exit 1
        fi
    elif [[ "$os" == "Darwin" ]]; then
        # install brew if not installed
        if ! command -v brew &>/dev/null; then
            prompt "brew is not installed, would you like to install it? (y/n)"
            if [[ "$(prompt "Install brew? (y/n)")" == "y" ]]; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            else
                error "brew is required for macos, exiting"
                exit 1
            fi
        fi
        brew update
    fi
}

install_packages() {
    local packages=("$@")
    local not_installed=()
    for package in "${packages[@]}"; do
        if [[ "$os" == "Linux" ]]; then
            if ! dpkg -s $package &>/dev/null; then
                not_installed+=($package)
            fi
        elif [[ "$os" == "Darwin" ]]; then
            # handle fd-find and fd
            if [[ "$package" == "fd" ]]; then
                package="fd-find"
            fi
            if ! brew list $package &>/dev/null; then
                not_installed+=($package)
            fi
        fi
    done
    log "Installing ${#not_installed[@]} packages..."
    if [[ ${#not_installed[@]} -gt 0 ]]; then
        if [[ "$os" == "Linux" ]]; then
            sudo apt-get install -y -qq ${not_installed[@]} >/dev/null || { error "failed to install packages" && exit 1; }
        elif [[ "$os" == "Darwin" ]]; then
            grep_list="is already installed|To reinstall|brew reinstall|the latest version is already installed"
            brew install "${not_installed[@]}" 2>&1 | grep -vE "$grep_list" || { error "failed to install packages" && exit 1; }
        fi
    fi
}

install_lazygit() {
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tmp_dir=$(mktemp -d)
    tar xf lazygit.tar.gz -C $tmp_dir
    sudo install $tmp_dir/lazygit -D -t /usr/local/bin/
    rm -rf $tmp_dir
}
setup_package_manager
install_packages "${PACKAGES[@]}"
install_lazygit

source wip-setup-userland.sh
