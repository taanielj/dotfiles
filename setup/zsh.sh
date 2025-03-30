#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_zsh() {
    configure_zsh
}

configure_zsh() {
    echo "Configuring Zsh..."
    if ! command -v zsh &>/dev/null; then
        echo "zsh is not installed. Installation failed."
        return 1
    fi

    # Remove existing oh-my-zsh if present
    rm -rf "$HOME/.oh-my-zsh"

    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null
    rm -rf ~$HOME/.zshrc.pre-oh-my-zsh # no need for backup, we have git
    # Install plugins and theme
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    # Create symlinks
    if [[ -f "$HOME/.zshrc" ]]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.pre-oh-my-zsh"
    fi
    ln -sf "$REPO_ROOT/zsh/zshrc.zsh" "$HOME/.zshrc"
    rm -rf "$HOME/.config/zsh"
    ln -sf "$REPO_ROOT/zsh" "$HOME/.config/zsh"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_zsh "$@"
fi
