# The starship prompt, which zshrc loads instead of p10k when ~/.zshrc.local
# sets ZSH_PROMPT=starship. settings.zsh lists what the STARSHIP_* options change.
eval "$(starship init zsh)"
# init sets each prompt to $(<command>)
typeset -g _starship_left_command=${${PROMPT#\$\(}%\)} _starship_right_command=${${RPROMPT#\$\(}%\)}

typeset -g _starship_dir=${${(%):-%x}:h}
() {
    local part
    local -a parts=(
        settings          # the options, and the lists the other files read
        options           # checks the options; prompt-style sets and saves them
        generate-config   # base.toml and the options make the config starship reads
        segments          # the segments look
        path              # the OS icon and the path, which zsh draws
        module-variables  # what base.toml's modules wait for: git host, kube, gcloud
        prompt            # PROMPT and RPROMPT, the transient prompt
    )
    for part in $parts; do
        source $_starship_dir/$part.zsh
    done
}

_starship_apply_options() {
    emulate -L zsh
    _starship_default_unset_and_invalid_options
    _starship_load_palette
    _starship_use_fresh_config
    _starship_render_os_icon
    _starship_build_prompt
    _starship_render_path
}
_starship_apply_options
