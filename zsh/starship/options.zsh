# Checks the STARSHIP_* options (settings.zsh) and defines prompt-style, which
# sets them in this shell and saves them for new ones, e.g.
# `prompt-style look=segments lines=frame`; without arguments it prints them.
typeset -g _starship_saved_options_file=$HOME/.zshrc.local

_starship_default_unset_and_invalid_options() {
    local name var
    for name in $_starship_option_names; do
        var=STARSHIP_${(U)name}
        _starship_is_valid_option $name "${(P)var}" && continue
        [[ -v $var ]] && print -u2 "starship: $var=${(P)var} isn't one of: $_starship_option_values[$name]"
        typeset -g $var=${_starship_option_values[$name]%% *}
    done
}

_starship_is_valid_option() {
    local name=$1 value=$2
    [[ " $_starship_option_values[$name] " == *" $value "* ]]
}

prompt-style() {
    local arg name var
    for arg; do
        if [[ $arg != *=* ]] || ! _starship_is_valid_option "${arg%%=*}" "${arg#*=}"; then
            print -u2 'usage: prompt-style [<option>=<value>]...'
            for name in $_starship_option_names; do
                print -u2 "  $name=${_starship_option_values[$name]// /|}"
            done
            return 1
        fi
    done
    for arg; do
        var=STARSHIP_${(U)arg%%=*}
        typeset -g $var=${arg#*=}
        _starship_save_option $var ${arg#*=}
    done
    (( $# )) && _starship_apply_options
    for name in $_starship_option_names; do
        var=STARSHIP_${(U)name}
        print -r -- "$name=${(P)var}"
    done
}

# The saved line gives way to a value the shell starts with, so that
# `STARSHIP_LOOK=lean exec zsh` still tries one out.
_starship_save_option() {
    emulate -L zsh -o extended_glob
    local var=$1 value=$2 file=$_starship_saved_options_file
    local assignment="$var=\${$var:-$value}"
    local -a lines mentions
    [[ -s $file ]] && lines=("${(@f)"$(<$file)"}")
    mentions=(${(M)lines:#*$var=*})
    mentions=(${mentions:#[[:space:]]#\#*})
    if (( ! $#mentions )); then
        lines+=($assignment)
    elif (( $#mentions == 1 )) && [[ $mentions[1] == $var=* ]]; then
        lines[${lines[(i)$var=*]}]=$assignment
    else
        print -u2 "prompt-style: not saved, $file sets $var in a way prompt-style doesn't edit:"
        print -u2 -rl -- "  "$^mentions
        return 1
    fi
    print -rl -- "${lines[@]}" >| $file
}

_starship_complete_style() {
    if compset -P '*='; then
        compadd -- ${=_starship_option_values[${IPREFIX%=}]}
    else
        compadd -S = -- $_starship_option_names
    fi
}

_starship_complete_option_value() {
    compadd -- ${=_starship_option_values[${(L)compstate[parameter]#STARSHIP_}]}
}

if (( $+functions[compdef] )); then
    compdef _starship_complete_style prompt-style
    compdef _starship_complete_option_value -value-,STARSHIP_${(U)^_starship_option_names},-default-
fi
