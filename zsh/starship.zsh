# The starship prompt, which zshrc loads instead of p10k when ~/.zshrc.local
# sets ZSH_PROMPT=starship.
export STARSHIP_CONFIG="$HOME/.config/zsh/starship.toml"
eval "$(starship init zsh)"

# zsh draws the OS icon and the path in front of starship's prompt, since
# starship's directory module can't shorten or colour the path the way p10k's
# dir segment does (zsh/p10k.zsh). The OS icon renders once, here.
typeset -g _prompt_os=$(starship module os)
PROMPT='${_prompt_os}${_prompt_dir}'$PROMPT

# Folders holding one of these are anchors: never shortened, and bold. The
# same list as anchor_files in zsh/p10k.zsh.
typeset -g _prompt_dir_markers='(.bzr|.citc|.git|.hg|.node-version|.python-version|.go-version|.ruby-version|.lua-version|.java-version|.perl-version|.php-version|.tool-versions|.shorten_folder_marker|.svn|.terraform|CVS|Cargo.toml|composer.json|go.mod|package.json|stack.yaml)'

# Sets REPLY to roughly how many columns the prompt takes besides the path: the OS
# and folder icons, the prompt char, the clock, and in a repo its host icon,
# branch and a few status counts. Starship renders them after this runs.
# Usage: _prompt_rest_width <repo root or "">
_prompt_rest_width() {
    local width=20 git=$1/.git head
    [[ -n $DIRENV_DIR ]] && (( width += 2 ))
    [[ -n $1 ]] || { REPLY=$width; return }
    # A worktree's .git is a file naming its git dir
    [[ -f $git ]] && git=${${(f)"$(<$git)"}[1]#gitdir: }
    [[ -r $git/HEAD ]] && head=$(<$git/HEAD)
    REPLY=$(( width + 12 + ${#${head#ref: refs/heads/}} ))
}

# Sets _prompt_dir to the path as p10k's dir segment shows it: the parent
# folders shorten from the left to their shortest unique prefix (grey) only
# while the prompt would leave under 40 columns for typing, or the path runs
# past 80; anchors and the last folder show bold.
_prompt_dir() {
    emulate -L zsh
    local lead dir rest=$PWD root i n name
    if [[ $PWD == $HOME || $PWD == $HOME/* ]]; then
        lead='~' dir=$HOME rest=${PWD#$HOME}
    fi
    local -a names=(${(s:/:)rest}) dirs shown kinds marker matches
    local -i len=${#lead}
    for (( i = 1; i <= $#names; i++ )); do
        dir+=/$names[i]
        dirs[i]=$dir shown[i]=$names[i] kinds[i]=plain
        (( len += 1 + ${#names[i]} ))
        marker=($dir/${~_prompt_dir_markers}(N[1]))
        (( $#marker )) && kinds[i]=anchor
        [[ -e $dir/.git ]] && root=$dir
    done
    (( $#names )) && kinds[-1]=anchor
    local REPLY
    _prompt_rest_width "$root"
    local -i budget=$(( COLUMNS - 40 - REPLY ))
    (( budget > 80 )) && budget=80
    for (( i = 1; i <= $#names; i++ )); do
        (( len <= budget )) && break
        [[ $kinds[i] == plain ]] || continue
        for (( n = 1; n < ${#names[i]}; n++ )); do
            matches=(${dirs[i]:h}/${(b)names[i][1,n]}*(N/D))
            if (( $#matches == 1 )); then
                shown[i]=${names[i][1,n]} kinds[i]=short
                (( len -= ${#names[i]} - n ))
                break
            fi
        done
    done
    local out
    if (( $#names )); then
        out="%F{31}$lead"
    elif [[ -n $lead ]]; then
        out="%B%F{39}$lead%b"
    else
        out="%B%F{39}/%b"
    fi
    for (( i = 1; i <= $#names; i++ )); do
        name=${shown[i]//\%/%%}
        case $kinds[i] in
            anchor) out+="%F{31}/%B%F{39}$name%b" ;;
            short) out+="%F{31}/%F{103}$name" ;;
            *) out+="%F{31}/$name" ;;
        esac
    done
    typeset -g _prompt_dir="%F{31}"$'\uF07C'" $out%f "
}
precmd_functions+=(_prompt_dir)

# A resized window refits the path while a command is being typed, as p10k's does
TRAPWINCH() {
    _prompt_dir
    zle && zle reset-prompt
}

# Icons for origin remotes by URL pattern, e.g. prompt_git_host_icons[*host.example*]=$'\U100000';
# ~/.zshrc.local or an overlay it sources can add some before this file loads.
typeset -gA prompt_git_host_icons

# p10k's VCS icon for the origin remote's host, unless prompt_git_host_icons
# names one; GITLAB_HOST (glab's) marks a self-hosted GitLab. Worked out on cd,
# where a starship custom module would start sh and git on every prompt.
# `config --local` fails with 128 outside a repo and with 1 in a repo without
# that remote.
_prompt_git_host() {
    local url pattern
    url=$(git config --local --get remote.origin.url 2>/dev/null)
    if (( $? == 128 )); then
        unset STARSHIP_GIT_HOST
        return
    fi
    for pattern in ${(k)prompt_git_host_icons}; do
        if [[ $url == ${~pattern} ]]; then
            export STARSHIP_GIT_HOST=$prompt_git_host_icons[$pattern]
            return
        fi
    done
    case $url in
        *github*) export STARSHIP_GIT_HOST=$'\uF113' ;;
        *gitlab* | *${GITLAB_HOST:-gitlab.com}*) export STARSHIP_GIT_HOST=$'\uF296' ;;
        *bitbucket*) export STARSHIP_GIT_HOST=$'\uE703' ;;
        *) export STARSHIP_GIT_HOST=$'\uF1D3' ;;
    esac
}
chpwd_functions+=(_prompt_git_host)
_prompt_git_host

# Kube context and gcloud project show only while the typed command's first
# word matches; starship.toml gates those modules on these variables.
typeset -gA _prompt_show_on=(
    STARSHIP_KUBE 'kubectl|k|ka|kl|kc|kn|kcn|kcnp|kp|kd|ke|helm|kubens|kubectx|oc|istioctl|kogito|k9s|helmfile|flux|fluxctl|stern|s|sj|sg|sd|sc|kubeseal|skaffold|kubent|kubecolor|cmctl|sparkctl'
    STARSHIP_GCLOUD 'gcloud|gcs|gsutil|bq'
)

# The leading _ keeps zsh-autosuggestions from wrapping it as an editing widget
_prompt_show_on_command() {
    local cmd=${${(z)BUFFER}[1]} var changed=0
    for var in ${(k)_prompt_show_on}; do
        if [[ $cmd == (${~_prompt_show_on[$var]}) ]]; then
            [[ -v $var ]] || { export $var=1; changed=1 }
        elif [[ -v $var ]]; then
            unset $var
            changed=1
        fi
    done
    (( changed )) && zle reset-prompt
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget zle-line-pre-redraw _prompt_show_on_command

_prompt_show_on_clear() { unset ${(k)_prompt_show_on} }
precmd_functions+=(_prompt_show_on_clear)
