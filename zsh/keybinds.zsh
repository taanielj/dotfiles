# Key bindings configuration
bindkey -e

## Edit command line in $EDITOR (neovim)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

## Home and End
bindkey "^[OH" beginning-of-line    # Home (application mode / SS3)
bindkey "^[OF" end-of-line          # End (application mode / SS3)
bindkey "^[[H" beginning-of-line    # Home (xterm normal mode)
bindkey "^[[F" end-of-line          # End (xterm normal mode)
bindkey "^[[1~" beginning-of-line   # Home (vt / tmux-256color)
bindkey "^[[4~" end-of-line         # End (vt / tmux-256color)

## ctrl up and down do nothing
bindkey "^[[1;5A" up-line-or-history
bindkey "^[[1;5B" down-line-or-history
## ctrl left and right: move to left or right word (these don't work on mac)
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

## option left and right: move to left or right word (these work on mac)
## ctrl backspace: delete word before cursor, ctrl delete: delete word after cursor
bindkey "^[[3;5~" kill-word # ctrl delete - works in both mac and windows terminal
bindkey "^?" backward-kill-word # that didn't work, testing alternatives, currently to pass ctrl packspace:

# Prefix-based history search (type "git" then Up/Down)
bindkey "^[[A" history-search-backward
bindkey "^[OA" history-search-backward
bindkey "^[[B" history-search-forward
bindkey "^[OB" history-search-forward
