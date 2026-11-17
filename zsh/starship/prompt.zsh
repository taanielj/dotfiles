# Wraps starship's two prompt commands into PROMPT and RPROMPT: the path in
# front, the segments joined, the frame, and the right side on the first line.

_starship_build_prompt() {
    local blank_line_above= frame_top=
    [[ $STARSHIP_SPACING == airy ]] && blank_line_above=$'\n'
    [[ $STARSHIP_LINES == frame ]] && frame_top="%F{$_starship_colors[frame]}╭─%f"
    local left right
    if [[ $STARSHIP_LOOK == segments ]]; then
        left=$frame_top'$(_starship_draw_segments "${_starship_path}$('$_starship_left_command')")'
        right='$(_starship_draw_segments "$('$_starship_right_command')")'
    else
        left=${frame_top:+$frame_top }'${_starship_path}$('$_starship_left_command')'
        right='$('$_starship_right_command')'
    fi
    if [[ $STARSHIP_LINES == 1 ]]; then
        PROMPT=$blank_line_above$left RPROMPT=$right
    else
        # zsh would put RPROMPT on the line the command is typed on
        PROMPT=$blank_line_above'$(_starship_right_align_on_first_line "'$left'" "'$right'")' RPROMPT=
    fi
    typeset -g _starship_full_prompt=$PROMPT _starship_full_right_prompt=$RPROMPT
    typeset -g _starship_blank_line_above=$blank_line_above
}

# Leaves the right side out when the first line has no room for it, as zsh does
# with RPROMPT.
_starship_right_align_on_first_line() {
    emulate -L zsh
    local left=$1 right=$2
    local first_line=${left%%$'\n'*} REPLY
    _starship_displayed_width $first_line
    local -i gap=$(( COLUMNS - 1 - REPLY ))
    _starship_displayed_width $right
    (( gap -= REPLY ))
    if (( gap < 1 || ! REPLY )); then
        print -rn -- "$left"
    else
        print -rn -- "$first_line${(l:gap:)}$right${left#$first_line}"
    fi
}

# Sets REPLY.
_starship_displayed_width() {
    emulate -L zsh -o extended_glob
    local prompt_text=$1
    local without_colour_codes=${${(%)prompt_text}//$'\e'\[[0-9;]#m}
    REPLY=${(m)#without_colour_codes}
}

# p10k's transient prompt. The char keeps the colour starship gave it.
_starship_collapse_finished_prompt() {
    [[ $STARSHIP_TRANSIENT == on ]] || return
    local color=$_starship_colors[git]
    (( ${STARSHIP_CMD_STATUS:-0} )) && color=$_starship_colors[error]
    PROMPT="$_starship_blank_line_above%F{$color}❯%f " RPROMPT=
    zle reset-prompt
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget zle-line-finish _starship_collapse_finished_prompt

_starship_restore_full_prompt() { PROMPT=$_starship_full_prompt RPROMPT=$_starship_full_right_prompt }
precmd_functions+=(_starship_restore_full_prompt)
