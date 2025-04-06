#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)
source "$REPO_ROOT/setup/utils.sh"

main_zsh() {
    configure_zsh
}

configure_zsh() {
    log "Configuring Zsh..."

    if ! command -v zsh &>/dev/null; then
        warn "Zsh is not installed. Installation failed."
        return 1
    fi

    # Remove existing oh-my-zsh if present
    rm -rf "$HOME/.oh-my-zsh"

    # Install oh-my-zsh
    run_quiet "Installing oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Remove oh-my-zsh backup (no need — we have git)
    rm -f "$HOME/.zshrc.pre-oh-my-zsh"

    # Install powerlevel10k theme
    run_quiet "Installing powerlevel10k" \
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    # Symlink .zshrc
    [[ -f "$HOME/.zshrc" ]] && mv "$HOME/.zshrc" "$HOME/.zshrc.pre-oh-my-zsh"
    ln -sf "$REPO_ROOT/zsh/zshrc.zsh" "$HOME/.zshrc"

    # Link config dir
    rm -rf "$HOME/.config/zsh"
    mkdir -p "$HOME/.config"
    ln -sf "$REPO_ROOT/zsh" "$HOME/.config/zsh"

    success "Zsh configuration completed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_zsh "$@"
fi

