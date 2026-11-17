# The segments look. Each module's output starts with a marker, \x1f<role>\x1f,
# and an empty role ends the chain; zsh then joins the chain: the separators need
# the colours on both sides, and starship can't know which module came before.
typeset -g _starship_segment_mark=$'\x1f' _starship_segment_mark_in_toml='\u001f'

# Fills generate-config.zsh's overrides from settings.zsh's segment modules
_starship_override_modules_as_segments() {
    local mark=$_starship_segment_mark_in_toml module table role text count symbol
    for module in $_starship_segment_modules; do
        table=${module%% *} role=${${module#* }%% *} text=${module#* * }
        overrides[$table/style]=\"$(_starship_segment_style $role)\"
        overrides[$table/format]="\"$mark$role${mark}[$text](\$style)\""
    done
    overrides[username/style_user]=$overrides[username/style]
    overrides[username/style_root]="\"bold ${overrides[username/style]//\"}\""
    unset 'overrides[username/style]'
    overrides[status/pipestatus_format]='"'$mark'status'$mark'[ ✘$pipestatus]($style)"'

    # path.zsh puts the OS icon in the path's segment
    overrides[os/style]=\"$(_starship_segment_style path)\"
    overrides[os/format]='"[ $symbol]($style)"'

    local git_style=$(_starship_segment_style git)
    # The group hides the marker while there's nothing to count
    overrides[git_status/format]='"('$mark'git'$mark'$ahead_behind$stashed$conflicted$staged$modified$renamed$deleted$untracked)"'
    for count symbol in $_starship_git_status_counts; do
        overrides[git_status/$count]="\"[ $symbol]($git_style)\""
    done
}

_starship_segment_style() {
    local role=$1 text_colour=seg_fg
    (( ${+_starship_colors[${role}_fg]} )) && text_colour=${role}_fg
    print -r -- "fg:$text_colour bg:${role}_bg"
}

_starship_draw_segments() {
    emulate -L zsh
    local marked_text=$1
    local -a parts=("${(@ps.\x1f.)marked_text}")
    local out=$parts[1] open_role= role REPLY
    local -i i
    for (( i = 2; i <= $#parts; i += 2 )); do
        role=$parts[i]
        if [[ $role != $open_role ]]; then
            _starship_segment_boundary "$open_role" "$role"
            out+=$REPLY
            open_role=$role
        fi
        out+=$parts[i+1]
    done
    _starship_segment_boundary "$open_role" ''
    print -rn -- "$out$REPLY"
}

# Sets REPLY. An empty role is outside the chain.
_starship_segment_boundary() {
    local role_before=$1 role_after=$2
    local before=$_starship_colors[${role_before}_bg] after=$_starship_colors[${role_after}_bg] pad=
    [[ $STARSHIP_SPACING == airy ]] && pad=' '
    local end_text="%K{$before} $pad" start_text="%K{$after}$pad"
    local round_end="%k%F{$before}"$'\uE0B4'"%f" round_start="%k%F{$after}"$'\uE0B6'
    if [[ -z $role_before && -z $role_after ]]; then
        REPLY=
    elif [[ -z $role_before ]]; then
        REPLY=$round_start$start_text
    elif [[ -z $role_after ]]; then
        REPLY=$end_text$round_end
    else
        case $STARSHIP_SEP in
            pill) REPLY="$end_text$round_end $round_start$start_text" ;;
            round) REPLY="$end_text%F{$before}%K{$after}"$'\uE0B4'"$start_text" ;;
            arrow) REPLY="$end_text%F{$before}%K{$after}"$'\uE0B0'"$start_text" ;;
        esac
    fi
}
