# Tools that only make sense at the prompt.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"

# ^R/^T/alt-c widgets. Needs fzf >= 0.48; older installs shipped ~/.fzf.zsh
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh 2>/dev/null)"

command -v pay-respects >/dev/null 2>&1 && eval "$(pay-respects zsh --alias)"
