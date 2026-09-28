# Tools that only make sense at the prompt.
command -v zoxide &>/dev/null && eval "$(zoxide init --cmd cd zsh)"

# ^R/^T/alt-c widgets. Needs fzf >= 0.48; older installs shipped ~/.fzf.zsh
command -v fzf &>/dev/null && eval "$(fzf --zsh 2>/dev/null)"

command -v pay-respects &>/dev/null && eval "$(pay-respects zsh --alias)"

# Quitting with Q (superfile's cd-quit hotkey) leaves the shell in the directory superfile was showing
if command -v spf &>/dev/null; then
    spf() {
        local lastdir_file
        lastdir_file=$(command spf pl --lastdir-file)
        rm -f "$lastdir_file"
        # superfile picks kitty image previews by terminal name, and herdr panes pass kitty graphics under xterm-256color
        [[ -n $HERDR_ENV ]] && local -x TERM_PROGRAM=kitty
        command spf "$@"
        [[ -f $lastdir_file ]] || return 0
        source "$lastdir_file"
        rm -f "$lastdir_file"
    }

    # Runs as a command line, like fzf's alt-c, so precmd redraws the prompt in the new directory
    spf-widget() {
        zle push-line
        BUFFER=spf
        zle accept-line
    }
    zle -N spf-widget
    bindkey '^E' spf-widget
fi
