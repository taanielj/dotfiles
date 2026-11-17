# Builds PROMPT and RPROMPT from starship's output: the path in front, the
# segments joined, the frame, and the right side on the first line.
#
# starship runs once per prompt and the prompts are drawn from what it printed:
# a redraw, as on a resize, costs no run. A redraw that should show fresh data
# runs it first.
_starship_run_starship() {
    typeset -g _starship_left_output=$(eval $_starship_left_command) _starship_right_output=
    [[ $STARSHIP_ALIGN == justify ]] && _starship_right_output=$(eval $_starship_right_command)
}
precmd_functions+=(_starship_run_starship)

_starship_clear_screen_with_fresh_prompt() {
    _starship_run_starship
    zle .clear-screen
}
zle -N clear-screen _starship_clear_screen_with_fresh_prompt

_starship_build_prompt() {
    local blank_line_above= frame_top=
    [[ $STARSHIP_SPACING == airy ]] && blank_line_above=$'\n'
    [[ $STARSHIP_LINES == frame ]] && frame_top="%F{$_starship_colors[frame]}╭─%f"
    local left right
    if [[ $STARSHIP_LOOK == segments ]]; then
        left=$frame_top'$(_starship_draw_segments "${_starship_path}${_starship_left_output}")'
        right='$(_starship_draw_segments "${_starship_right_output}")'
    else
        left=${frame_top:+$frame_top }'${_starship_path}${_starship_left_output}'
        right='${_starship_right_output}'
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

# zsh redraws the prompt on a resize before this runs, from the row its first
# line was on before the terminal re-wrapped it. The rows the wrap added stay
# above as leftovers; this erases them and draws the prompt again from the first.
TRAPWINCH() {
    if zle; then
        local -a reply
        _starship_measure_rewrapped_prompt
        local -i leftover_rows=$reply[1] cursor_row=$reply[2]
        _starship_render_path
        if (( leftover_rows > 0 )); then
            local to_first_leftover=$'\e['$(( cursor_row + leftover_rows ))$'A\r' erase_below=$'\e[J' back_down=
            (( cursor_row )) && back_down=$'\e['$cursor_row'B'
            print -rn -- "$to_first_leftover$erase_below$back_down" >/dev/tty
        fi
        zle reset-prompt
    fi
    _starship_note_drawn_width
}
_starship_note_drawn_width() { typeset -g _starship_drawn_columns=$COLUMNS }
precmd_functions+=(_starship_note_drawn_width)

# Sets reply to the rows that re-wrapping added above the cursor, and the row
# the cursor is on in the prompt zsh has redrawn, counted from 0.
_starship_measure_rewrapped_prompt() {
    emulate -L zsh -o extended_glob -o prompt_subst
    local -i old_columns=$_starship_drawn_columns new_columns=$COLUMNS added_rows=0 width
    local as_drawn=$(COLUMNS=$old_columns; print -rP -- "$PROMPT") line
    local -a lines=("${(@f)as_drawn}")
    for line in "${(@)lines[1,-2]}"; do
        width=${(m)#${line//$'\e'\[[0-9;]#m}}
        (( width > new_columns )) && (( added_rows += (width - 1) / new_columns ))
    done
    width=$(( ${(m)#${lines[-1]//$'\e'\[[0-9;]#m}} + ${(m)#LBUFFER} ))
    local -i typing_row_before=width/old_columns typing_row_now=width/new_columns
    reply=($(( added_rows + typing_row_now - typing_row_before )) $(( $#lines - 1 + typing_row_now )))
}
