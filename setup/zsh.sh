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

