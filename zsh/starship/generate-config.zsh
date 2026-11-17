# Generates the config starship reads: base.toml with the keys the STARSHIP_*
# options decide replaced or added. zsh reads base.toml's palette too, for what
# it draws itself.
typeset -g _starship_base_config=$_starship_dir/base.toml
typeset -gA _starship_colors

_starship_use_fresh_config() {
    local config="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/starship/$STARSHIP_LOOK-$STARSHIP_COLORS-$STARSHIP_LINES-$STARSHIP_ALIGN.toml"
    local -a changed_since=($_starship_dir/*(Ne:'[[ $REPLY -nt $config ]]':))
    [[ -e $config ]] && (( ! $#changed_since )) || _starship_generate_config $config
    export STARSHIP_CONFIG=$config
}

_starship_generate_config() {
    emulate -L zsh -o extended_glob
    local config=$1
    # "<table>/<key>" to a TOML value; the functions called here fill and read it
    local -A overrides
    _starship_override_layout
    [[ $STARSHIP_LOOK == segments ]] && _starship_override_modules_as_segments
    mkdir -p ${config:h}
    _starship_print_base_config_with_overrides >| $config.$$ && mv -f $config.$$ $config
}

_starship_override_layout() {
    local -A reply
    _starship_read_base_table ''
    local left=${reply[format]%'$line_break$character'} right=$reply[right_format] chain_end= command_line
    [[ $STARSHIP_ALIGN == left ]] && left+=$right right=
    if [[ $STARSHIP_LOOK == segments ]]; then
        chain_end=$_starship_segment_mark_in_toml$_starship_segment_mark_in_toml
        [[ -n $right ]] && right+=$chain_end
    fi
    case $STARSHIP_LINES in
        1)
            command_line='$character'
            # Lean modules end in a space, except time; a chain doesn't
            [[ -n $chain_end || $STARSHIP_ALIGN == left ]] && command_line=" $command_line"
            ;;
        2) command_line='$line_break$character' ;;
        frame) command_line='$line_break[╰─](fg:frame)$character' ;;
    esac
    overrides[/palette]=\"$STARSHIP_COLORS\"
    overrides[/format]=\"$left$chain_end$command_line\"
    overrides[/right_format]=\"$right\"
}

_starship_print_base_config_with_overrides() {
    emulate -L zsh -o extended_glob
    local line table= key added
    local -A replaced
    # The empty header at the end adds the last table's new keys
    for line in "${(@f)"$(<$_starship_base_config)"}" '[]'; do
        if [[ $line == \[* ]]; then
            for added in ${(k)overrides}; do
                [[ $added == $table/* && -z $replaced[$added] ]] && print -r -- "${added#*/} = $overrides[$added]"
            done
            table=${${${line#\[}#\[}%%\]*}
        elif [[ $line == (#b)([A-Za-z_]##)[[:space:]]#=* ]]; then
            key=$table/$match[1]
            if (( ${+overrides[$key]} )); then
                line="$match[1] = $overrides[$key]" replaced[$key]=1
            fi
        fi
        [[ $line == '[]' ]] || print -r -- "$line"
    done
}

_starship_load_palette() {
    local -A reply
    _starship_read_base_table palettes.$STARSHIP_COLORS
    _starship_colors=("${(@kv)reply}")
}

# Sets the caller's associative array `reply` to the string values of one of
# base.toml's tables; '' is the top level.
_starship_read_base_table() {
    emulate -L zsh -o extended_glob
    local wanted=$1 line table=
    reply=()
    for line in "${(@f)$(<$_starship_base_config)}"; do
        if [[ $line == \[(#b)(*)\] ]]; then
            table=$match[1]
        elif [[ $table == $wanted && $line == (#b)([a-z_]##)[[:space:]]#=[[:space:]]#\"([^\"]#)\"* ]]; then
            reply[$match[1]]=$match[2]
        fi
    done
}
