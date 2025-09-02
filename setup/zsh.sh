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
    if [[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$REPO_ROOT/zsh/zshrc.zsh" ]]; then
        log ".zshrc is already linked to the repository. Skipping."
        return 0
    elif [[ -f "$HOME/.zshrc" && ! -f !"$HOME/.zshrc.pre-taaniel-dotfiles" ]]; then
        log "Backing up existing .zshrc to .zshrc.pre-taaniel-dotfiles"
        mv "$HOME/.zshrc" "$HOME/.zshrc.pre-taaniel-dotfiles"
    elif [[ -f "$HOME/.zshrc" && -f "$HOME/.zshrc.pre-taaniel-dotfiles" ]]; then
        log "Both .zshrc and .zshrc.pre-taaniel-dotfiles exist. Please resolve this manually."
        return 1
    fi

    ln -sf "$REPO_ROOT/zsh/zshrc.zsh" "$HOME/.zshrc"

    # Link config dir
    rm -rf "$HOME/.config/zsh"
    mkdir -p "$HOME/.config"
    ln -sf "$REPO_ROOT/zsh" "$HOME/.config/zsh"

    success "Zsh configuration completed."
}

teardown_zsh() {
    log "Removing Zsh configuration..."

    # Restore original .zshrc if it exists
    if [[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$REPO_ROOT/zsh/zshrc.zsh" ]]; then
        rm -f "$HOME/.zshrc"
        if [[ -f "$HOME/.zshrc.pre-taaniel-dotfiles" ]]; then
            log "Restoring original .zshrc from .zshrc.pre-taaniel-dotfiles"
            mv "$HOME/.zshrc.pre-taaniel-dotfiles" "$HOME/.zshrc"
        else
            log "No backup .zshrc found"
        fi
    fi

    # Remove symlinked config directory
    if [[ -L "$HOME/.config/zsh" && "$(readlink "$HOME/.config/zsh")" == "$REPO_ROOT/zsh" ]]; then
        rm -f "$HOME/.config/zsh"
    fi

    # Remove zinit installation and plugins
    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"
    if [[ -d "$ZINIT_HOME" ]]; then
        log "Removing zinit and all plugins from $ZINIT_HOME"
        rm -rf "$ZINIT_HOME"
    fi

    # Remove powerlevel10k cache/prompt
    P10K_PROMPT="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
    if [[ -f "$P10K_PROMPT" ]]; then
        log "Removing powerlevel10k instant prompt cache"
        rm -f "$P10K_PROMPT"
    fi

    # Remove any p10k configuration
    if [[ -f "$HOME/.p10k.zsh" ]]; then
        log "Removing powerlevel10k config file"
        rm -f "$HOME/.p10k.zsh"
    fi

    success "Zsh configuration and zinit components removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_zsh "$@"
fi
