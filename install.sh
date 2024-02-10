#!/bin/bash
# Script to install zsh (oh-my-zsh), tmux and nvim.

# Supports only debian-based systems for now, add macOS support later if I switch to mac.

# ZSH

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

check_apt() {
    if [ -x "$(command -v apt-get)" ]; then
        echo "apt-get found"
    else
        echo "apt-get not found"
        exit 1
    fi
}

check git() {
    if [ -x "$(command -v git)" ]; then
        echo "git found"
    else
        echo "git not found"
        exit 1
    fi
}

change_shell() {
    echo "Would you like to change your shell to zsh? (y/n)"
    read answer
    if [ "$answer" == "y" ]; then
        chsh -s $(which zsh)
        echo "Shell changed to zsh"
    else
        echo "Shell not changed"
    fi
    zsh
}


install_zsh() {
    echo "Installing zsh"
    apt-get install -y zsh
    # get_oh_my_zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    # get auto-suggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    cp .zshrc ~/.zshrc
    source ~/.zshrc
}
source ~/.zshrc

install_tmux() {
    echo "Installing tmux"
    apt-get install -y tmux
    cp .tmux.conf ~/.tmux.conf
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    # start tmux and install plugins
    tmux start-server
    tmux new-session -d
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    tmux kill-server
}

install_nvim() {
    echo "Installing neovim"
    wget https://github.com/neovim/neovim/releases/download/v0.9.5/nvim.appimage
    chmod u+x nvim.appimage
    mv nvim.appimage /usr/local/bin/nvim
    mv nvim/ ~/.config/nvim
}

check_root
check_apt
check_git
apt-get update || { echo "apt-get update failed"; exit 1;}
install_zsh
install_tmux
install_nvim
change_shell
