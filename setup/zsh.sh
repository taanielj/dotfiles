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

    stub_file "$REPO_ROOT/zsh/zshrc.zsh" "$HOME/.zshrc"

    stub_file "$REPO_ROOT/zsh/zprofile.zsh" "$HOME/.zprofile"

    link_file "$REPO_ROOT/zsh" "$HOME/.config/zsh"

    set_dotfiles_root

    success "Zsh configuration completed."
}

set_dotfiles_root() {
    local zshrc_local="$HOME/.zshrc.local"
    local dotfiles_line="export DOTFILES_ROOT=\"$REPO_ROOT\""

    touch "$zshrc_local"

    if grep -Fxq "$dotfiles_line" "$zshrc_local" 2>/dev/null; then
        return 0
    fi

    # loose match so a stale path or a bare assignment is upgraded in place
    if grep -Eq "^(export )?DOTFILES_ROOT=" "$zshrc_local" 2>/dev/null; then
        log "Updating DOTFILES_ROOT in .zshrc.local"
        # macOS sed -i takes a backup suffix argument; GNU sed takes none
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -E -i '' "s|^(export )?DOTFILES_ROOT=.*|$dotfiles_line|" "$zshrc_local"
        else
            sed -E -i "s|^(export )?DOTFILES_ROOT=.*|$dotfiles_line|" "$zshrc_local"
        fi
    else
        log "Adding DOTFILES_ROOT to .zshrc.local"
        echo "$dotfiles_line" >>"$zshrc_local"
    fi
}

teardown_zsh() {
    log "Removing Zsh configuration..."

    # A dest may be a stub or a symlink, so try both removal paths.
    unstub_file "$REPO_ROOT/zsh/zshrc.zsh" "$HOME/.zshrc"
    unlink_file "$REPO_ROOT/zsh/zshrc.zsh" "$HOME/.zshrc"

    unstub_file "$REPO_ROOT/zsh/zprofile.zsh" "$HOME/.zprofile"
    unlink_file "$REPO_ROOT/zsh/zprofile.zsh" "$HOME/.zprofile"

    unlink_file "$REPO_ROOT/zsh" "$HOME/.config/zsh"

    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"
    if [[ -d "$ZINIT_HOME" ]]; then
        log "Removing zinit and all plugins from $ZINIT_HOME"
        rm -rf "$ZINIT_HOME"
    fi

    success "Zsh configuration and zinit components removed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_zsh "$@"
fi
