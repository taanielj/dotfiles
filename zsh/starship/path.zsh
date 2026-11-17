# zsh draws the OS icon and the path in front of starship's prompt, since
# starship's directory module can't shorten or colour the path the way p10k's
# dir segment does (zsh/p10k.zsh).

# Sets _starship_path. Parent folders shorten from the left to their shortest
# unique prefix, dimmed. Anchors (settings.zsh) and the last folder are bold.
_starship_render_path() {
    emulate -L zsh
    # The functions below share these: the text before the first folder, then
    # each folder's name, full path, shown name and kind (plain, short or anchor)
    local lead repo_root
    local -a names dirs shown kinds
    _starship_classify_folders
    _starship_shorten_plain_folders
    _starship_colour_path
}
precmd_functions+=(_starship_render_path)

# A resized window refits the path while a command is being typed, as p10k's does
TRAPWINCH() {
    _starship_render_path
    zle && zle reset-prompt
}

_starship_classify_folders() {
    local dir rest=$PWD
    local -a anchor_file
    local -i i
    if [[ $PWD == $HOME || $PWD == $HOME/* ]]; then
        lead='~' dir=$HOME rest=${PWD#$HOME}
    fi
    names=(${(s:/:)rest})
    for (( i = 1; i <= $#names; i++ )); do
        dir+=/$names[i]
        dirs[i]=$dir shown[i]=$names[i] kinds[i]=plain
        anchor_file=($dir/${~_starship_anchor_files}(N[1]))
        (( $#anchor_file )) && kinds[i]=anchor
        [[ -e $dir/.git ]] && repo_root=$dir
    done
    (( $#names )) && kinds[-1]=anchor
}

_starship_shorten_plain_folders() {
    local name REPLY
    local -a matches
    local -i i n length=${#lead} longest_unshortened_path=80
    for name in $names; do
        (( length += 1 + ${#name} ))
    done
    _starship_width_besides_path "$repo_root"
    local -i budget=$(( COLUMNS - REPLY ))
    (( budget > longest_unshortened_path )) && budget=longest_unshortened_path
    for (( i = 1; i <= $#names; i++ )); do
        (( length <= budget )) && break
        [[ $kinds[i] == plain ]] || continue
        for (( n = 1; n < ${#names[i]}; n++ )); do
            matches=(${dirs[i]:h}/${(b)names[i][1,n]}*(N/D))
            if (( $#matches == 1 )); then
                shown[i]=${names[i][1,n]} kinds[i]=short
                (( length -= ${#names[i]} - n ))
                break
            fi
        done
    done
}

# Sets REPLY to an estimate, since starship renders the rest after the path.
_starship_width_besides_path() {
    local repo_root=$1
    local -i os_and_folder_icons=6 segment_caps_and_padding=6 frame=3 time_and_status=14 room_to_type=20
    local -i width=os_and_folder_icons+time_and_status
    [[ $STARSHIP_LOOK == segments ]] && (( width += segment_caps_and_padding ))
    [[ $STARSHIP_LINES == frame ]] && (( width += frame ))
    [[ $STARSHIP_LINES == 1 ]] && (( width += room_to_type ))
    if [[ -n $repo_root ]]; then
        local git=$repo_root/.git head
        # A worktree's .git is a file naming its git dir
        [[ -f $git ]] && git=${${(f)"$(<$git)"}[1]#gitdir: }
        [[ -r $git/HEAD ]] && head=$(<$git/HEAD)
        local -i host_icon_and_status_counts=12
        (( width += host_icon_and_status_counts + ${#${head#ref: refs/heads/}} ))
    fi
    REPLY=$width
}

_starship_colour_path() {
    local plain=$_starship_colors[path] short=$_starship_colors[path_short] anchor=$_starship_colors[path_anchor]
    if [[ $STARSHIP_LOOK == segments ]]; then
        plain=${_starship_colors[path_fg]:-$_starship_colors[seg_fg]} short=$_starship_colors[path_dim] anchor=$plain
    fi
    local out name
    local -i i
    if (( $#names )); then
        out="%F{$plain}$lead"
    else
        out="%B%F{$anchor}${lead:-/}%b"
    fi
    for (( i = 1; i <= $#names; i++ )); do
        name=${shown[i]//\%/%%}
        case $kinds[i] in
            anchor) out+="%F{$plain}/%B%F{$anchor}$name%b" ;;
            short) out+="%F{$plain}/%F{$short}$name" ;;
            *) out+="%F{$plain}/$name" ;;
        esac
    done
    local folder_icon=$'\uF07C'
    if [[ $STARSHIP_LOOK == segments ]]; then
        # The background is set again because the OS icon's colour codes end in a reset
        typeset -g _starship_path="${_starship_segment_mark}path$_starship_segment_mark$_starship_os_icon%K{$_starship_colors[path_bg]}%F{$plain} $folder_icon $out"
    else
        typeset -g _starship_path="$_starship_os_icon%F{$plain}$folder_icon $out%f "
    fi
}

_starship_render_os_icon() {
    emulate -L zsh -o extended_glob
    typeset -g _starship_os_icon=$(starship module os)
    # `starship module` prints raw colour codes; %{ %} tells zsh they take no columns
    _starship_os_icon=${_starship_os_icon//(#m)$'\e'\[[0-9;]#m/"%{$MATCH%}"}
}
