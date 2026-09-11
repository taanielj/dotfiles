# Tools that only make sense at the prompt.
command -v zoxide &>/dev/null && eval "$(zoxide init --cmd cd zsh)"

# ^R/^T/alt-c widgets. Needs fzf >= 0.48; older installs shipped ~/.fzf.zsh
command -v fzf &>/dev/null && eval "$(fzf --zsh 2>/dev/null)"

command -v pay-respects &>/dev/null && eval "$(pay-respects zsh --alias)"
