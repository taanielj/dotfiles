# Key bindings configuration
## Edit command line in $EDITOR (neovim)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

## Home and End
bindkey "^[OH" beginning-of-line    # Home (application mode)
bindkey "^[OF" end-of-line          # End (application mode)
bindkey "^[[H" beginning-of-line    # Home (normal mode)
bindkey "^[[F" end-of-line          # End (normal mode)

## ctrl up and down do nothing
bindkey "^[[1;5A" up-line-or-history
bindkey "^[[1;5B" down-line-or-history
## ctrl left and right: move to left or right word (these don't work on mac)
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

## option left and right: move to left or right word (these work on mac)
## ctrl backspace: delete word before cursor, ctrl delete: delete word after cursor
bindkey "^[[3;5~" kill-word # ctrl delete
bindkey "^H" backward-kill-word # ctrl backspace
