# Key bindings configuration
## ctrl up and down do nothing
bindkey -s "^[[1;5A" ""
bindkey -s "^[[1;5B" ""

## ctrl left and right: move to left or right word (these don't work on mac)
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

## option left and right: move to left or right word (these work on mac)
## ctrl backspace: delete word before cursor, ctrl delete: delete word after cursor
bindkey "^H" backward-kill-word # ctrl backspace
bindkey "^[[3;5~" kill-word # ctrl delete


