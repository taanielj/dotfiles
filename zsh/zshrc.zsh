source "$HOME/.config/zsh/source-cached.zsh"

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[[ ! -d "$ZINIT_HOME" ]] && mkdir -p "$(dirname "$ZINIT_HOME")"
[[ ! -d "$ZINIT_HOME/.git" ]] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

source "${ZINIT_HOME}/zinit.zsh"

# zsh-completions only adds fpath entries and must load before compinit. atpull
# deletes the completion dump that an update makes stale.
zinit ice blockf atpull'zinit creinstall -q .; rm -f $ZSH_COMPDUMP{,.zwc}'
zinit light zsh-users/zsh-completions

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' substitute 1
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Space-led lines skip history (HIST_IGNORE_SPACE), so only completion would answer
export ZSH_AUTOSUGGEST_COMPLETION_IGNORE=' *'

ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
mkdir -p "$(dirname "$ZSH_COMPDUMP")"
fpath+="$HOME/.zfunc"

# compinit runs once. Running it again wipes completions registered at runtime,
# such as gcloud's.
# Adding or removing a completion file bumps its fpath dir's mtime. The dump is
# removed first because compinit reuses one whose fpath file count still matches.
autoload -Uz compinit
newer_fpath_dirs=( ${^fpath}(N-/e:'[[ $REPLY -nt $ZSH_COMPDUMP.zwc ]]':) )
if [[ ! -s $ZSH_COMPDUMP.zwc || $ZSH_COMPDUMP.zwc -ot $ZSH_COMPDUMP || -n $newer_fpath_dirs ]]; then
    rm -f "$ZSH_COMPDUMP"
    compinit -d "$ZSH_COMPDUMP"
    zcompile "$ZSH_COMPDUMP"
else
    compinit -C -d "$ZSH_COMPDUMP"
fi
unset newer_fpath_dirs
autoload -Uz _zinit
((${+_comps})) && _comps[zinit]=_zinit
autoload -U select-word-style
select-word-style bash

# Autosuggestions loads eagerly to show suggestions from the first prompt.
# With manual rebind, it wraps zle widgets once at the first prompt instead of
# at every prompt. The atload on zsh-syntax-highlighting wraps the widgets again
# after the turbo plugins add their own. A plugin that defines widgets must load
# before that atload.
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
zinit ice lucid
zinit light zsh-users/zsh-autosuggestions

zinit wait lucid for \
    Aloxaf/fzf-tab \
    atload'_zsh_autosuggest_bind_widgets' zsh-users/zsh-syntax-highlighting

# Turbo mode loads OMZ's git plugin after interactive/*.zsh. Its grm alias would
# shadow the grm function in interactive/aliases.zsh, and atload removes the alias.
zinit ice wait'1' lucid atload'unalias grm'
zinit snippet OMZP::git

HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE="$HOME/.zsh_history"

setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS

export MISE_POETRY_AUTO_INSTALL=1
export MISE_POETRY_VENV_AUTO=1

# Activated before the command -v guards below (zoxide, fd, direnv, nvim), which
# need mise-managed bins like ~/.cargo/bin on PATH. activate sets PATH right away.
mise_bin=$(command -v mise || echo "$HOME/.local/bin/mise") && [[ -x "$mise_bin" ]] && eval "$("$mise_bin" activate zsh)"
unset mise_bin

export COLORTERM=truecolor

# kitty's shell integration sets a bar cursor itself; other terminals need this
_prompt_cursor_bar() { printf '\e[5 q' }
precmd_functions+=(_prompt_cursor_bar)

# Exempt a command from CORRECT with: alias foo='nocorrect foo'
setopt CORRECT

# zprofile sets these for login shells, and multiplexer panes (herdr, tmux) start
# non-login shells, which don't read zprofile. -U drops duplicate entries.
typeset -U path
path=("$HOME/.local/nvim/bin" "$HOME/.local/bin" $path)
command -v nvim &>/dev/null && export EDITOR="nvim"

# Lazygit reads ~/Library/Application Support on macOS unless pointed elsewhere
[[ -f "$HOME/.config/lazygit/config.yml" ]] && export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
# Machine-local settings (e.g. work git hosts); lazygit exits on a missing listed file
[[ -n $LG_CONFIG_FILE && -f "$HOME/.config/lazygit/config.local.yml" ]] && LG_CONFIG_FILE+=",$HOME/.config/lazygit/config.local.yml"

# setup/system.sh links apt's batcat and fdfind to these names
if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
else
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.*"'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
command -v bat &>/dev/null && export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=header,numbers --line-range :500 {}'"

[[ -z "$MISE_STATUS_MESSAGE_MISSING_TOOLS" ]] && export MISE_STATUS_MESSAGE_MISSING_TOOLS="always"

command -v direnv &>/dev/null && source_cached direnv hook zsh

# HOMEBREW_PREFIX comes from zprofile, which only login shells read. The first
# two entries are zprofile's two brew prefixes. apt's SDK has gcloud on PATH
# already and ships only the completion.
for _gcloud_sdk in "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk" \
    "/home/linuxbrew/.linuxbrew/share/google-cloud-sdk" \
    "$HOME/google-cloud-sdk" \
    "/usr/share/google-cloud-sdk"; do
    [[ -f "$_gcloud_sdk/completion.zsh.inc" ]] || continue
    [[ -f "$_gcloud_sdk/path.zsh.inc" ]] && source "$_gcloud_sdk/path.zsh.inc"
    source "$_gcloud_sdk/completion.zsh.inc"
    break
done
unset _gcloud_sdk

for file in "$HOME"/.config/zsh/lib/*.zsh(N) "$HOME"/.config/zsh/modules/*.zsh(N); do
    source "$file"
done

if [[ -o interactive ]]; then
    for file in "$HOME"/.config/zsh/interactive/*.zsh(N); do
        source "$file"
    done
fi

# Machine-local config, not in VCS. Sourced after the interactive files so it
# can use helpers like register_tmux_session.
[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local

# The prompt loads after ~/.zshrc.local, where ZSH_PROMPT=starship picks
# starship over Powerlevel10k. Either renders before the lazy plugins load.
if [[ $ZSH_PROMPT == starship ]] && command -v starship &>/dev/null; then
    source "$HOME/.config/zsh/starship.zsh"
else
    # Pre-set SSH detection to skip expensive 'who' command in _p9k_init_ssh
    typeset -gix P9K_SSH=0
    typeset -gx _P9K_SSH_TTY=$TTY
    setopt promptsubst
    zinit ice depth=1 lucid
    zinit light romkatv/powerlevel10k
    source "$HOME/.config/zsh/p10k.zsh"
fi
