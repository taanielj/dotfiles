# Sets the variables base.toml's modules read: the git host's icon on cd, and
# the ones kube and gcloud wait for while a command of theirs is being typed
# (settings.zsh lists the icons and the commands).

_starship_export_git_host_icon() {
    local url pattern
    url=$(git config --local --get remote.origin.url 2>/dev/null)
    # 128 outside a repo; 1 in a repo without an origin remote
    if (( $? == 128 )); then
        unset STARSHIP_GIT_HOST_ICON
        return
    fi
    for pattern in ${(k)starship_git_host_icons}; do
        if [[ $url == ${~pattern} ]]; then
            export STARSHIP_GIT_HOST_ICON=$starship_git_host_icons[$pattern]
            return
        fi
    done
    case $url in
        # GITLAB_HOST (glab's) marks a self-hosted GitLab
        *github*) export STARSHIP_GIT_HOST_ICON=$'\uF113' ;;
        *gitlab* | *${GITLAB_HOST:-gitlab.com}*) export STARSHIP_GIT_HOST_ICON=$'\uF296' ;;
        *bitbucket*) export STARSHIP_GIT_HOST_ICON=$'\uE703' ;;
        *) export STARSHIP_GIT_HOST_ICON=$'\uF1D3' ;;
    esac
}
# Runs on cd to avoid starting sh and git on every prompt.
chpwd_functions+=(_starship_export_git_host_icon)
_starship_export_git_host_icon

# The leading _ keeps zsh-autosuggestions from wrapping it as an editing widget
_starship_show_on_command() {
    local line=${BUFFER#"${BUFFER%%[^[:space:]]*}"} var start
    local -i typed changed=0
    for var in ${(k)_starship_show_on}; do
        typed=0
        for start in ${(P)_starship_show_on[$var]}; do
            [[ $line == ${(b)start}* ]] && typed=1 && break
        done
        if (( typed )) && [[ ! -v $var ]]; then
            export $var=1
            changed=1
        elif (( ! typed )) && [[ -v $var ]]; then
            unset $var
            changed=1
        fi
    done
    (( changed )) && zle reset-prompt
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget zle-line-pre-redraw _starship_show_on_command

_starship_show_on_clear() { unset ${(k)_starship_show_on} }
precmd_functions+=(_starship_show_on_clear)
