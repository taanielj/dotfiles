bindkey -e

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

bindkey "^[OH" beginning-of-line    # Home (application mode / SS3)
bindkey "^[OF" end-of-line          # End (application mode / SS3)
bindkey "^[[H" beginning-of-line    # Home (xterm normal mode)
bindkey "^[[F" end-of-line          # End (xterm normal mode)
bindkey "^[[1~" beginning-of-line   # Home (vt / tmux-256color)
bindkey "^[[4~" end-of-line         # End (vt / tmux-256color)

## ctrl up and down: previous/next history line
bindkey "^[[1;5A" up-line-or-history
bindkey "^[[1;5B" down-line-or-history
## ctrl left and right: back/forward one word (on mac the terminal sends these for option+arrows)
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

bindkey "^[[3;5~" kill-word         # ctrl delete
bindkey "^?" backward-delete-char   # backspace

# Prefix-based history search (type "git" then Up/Down)
bindkey "^[[A" history-search-backward
bindkey "^[OA" history-search-backward
bindkey "^[[B" history-search-forward
bindkey "^[OB" history-search-forward

