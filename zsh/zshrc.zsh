# zmodload zsh/zprof

### ────────────────────────────────
###  Powerlevel10k Setup
### ────────────────────────────────
# Pre-set SSH detection to skip expensive 'who' command in _p9k_init_ssh
typeset -gix P9K_SSH=0
typeset -gx _P9K_SSH_TTY=$TTY

### ────────────────────────────────
###  Zinit Plugin Manager
### ────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

source "${ZINIT_HOME}/zinit.zsh"

# Pure fpath plugin — must load before compinit; atpull clears the stale dump
zinit ice blockf atpull'zinit creinstall -q .; rm -f $ZSH_COMPDUMP{,.zwc}'
zinit light zsh-users/zsh-completions

### ────────────────────────────────
###  Completion System
### ────────────────────────────────
# compinit runs ONCE: re-running it wipes dynamic registrations (gcloud etc.)
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' substitute 1
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
mkdir -p "$(dirname "$ZSH_COMPDUMP")"
fpath+=~/.zfunc

# Smart compinit - rebuild cache when needed, skip security check when cached
autoload -Uz compinit
if [[ ! -s $ZSH_COMPDUMP.zwc || $ZSH_COMPDUMP.zwc -ot $ZSH_COMPDUMP ]]; then
    compinit -d "$ZSH_COMPDUMP"
    zcompile "$ZSH_COMPDUMP"
else
    compinit -C -d "$ZSH_COMPDUMP"
fi
autoload -Uz _zinit
((${+_comps})) && _comps[zinit]=_zinit
autoload -U select-word-style
select-word-style bash

### ────────────────────────────────
###  Plugins
### ────────────────────────────────
setopt promptsubst

# Powerlevel10k — eager load for stable prompt
zinit ice depth=1 lucid
zinit light romkatv/powerlevel10k
source "$HOME/.config/zsh/p10k.zsh"

# Core plugins — autosuggestions loads immediately for better UX
zinit ice lucid
zinit light zsh-users/zsh-autosuggestions

# Other core plugins — lazy load
zinit wait lucid for \
    Aloxaf/fzf-tab \
    zsh-users/zsh-syntax-highlighting

# Oh-My-Zsh git plugin (snippet form)
zinit ice wait'1' lucid
zinit snippet OMZP::git

# Precompile plugins once in a while (manual: `zinit compile`)
# zinit compile

### ────────────────────────────────
###  History Settings
### ────────────────────────────────
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS

### ────────────────────────────────
###  Environment / UI Settings
### ────────────────────────────────
export COLORTERM=truecolor

# Typo correction on command names. Exempt one with: alias foo='nocorrect foo'
setopt CORRECT

# User-local bins: zprofile sets these for login shells, but multiplexer panes
# (herdr, tmux) spawn non-login shells that never read it. -U keeps path deduped.
typeset -U path
path=("$HOME/.local/nvim/bin" "$HOME/.local/bin" $path)
command -v nvim >/dev/null 2>&1 && export EDITOR="nvim"

# Lazygit reads ~/Library/Application Support on macOS unless pointed elsewhere
[[ -f "$HOME/.config/lazygit/config.yml" ]] && export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"

if command -v fdfind >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
elif command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
else
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.*"'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

### ────────────────────────────────
###  Optional Tools
### ────────────────────────────────
[[ -z "$MISE_STATUS_MESSAGE_MISSING_TOOLS" ]] && export MISE_STATUS_MESSAGE_MISSING_TOOLS="always"

command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

### ────────────────────────────────
###  Google Cloud SDK Integration
### ────────────────────────────────
for _gcloud_sdk in "$HOMEBREW_PREFIX/share/google-cloud-sdk" "$HOME/google-cloud-sdk"; do
    if [[ -f "$_gcloud_sdk/path.zsh.inc" ]]; then
        source "$_gcloud_sdk/path.zsh.inc"
        [[ -f "$_gcloud_sdk/completion.zsh.inc" ]] && source "$_gcloud_sdk/completion.zsh.inc"
        break
    fi
done
unset _gcloud_sdk

### ────────────────────────────────
###  User Configuration Files
### ────────────────────────────────
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

### ──────────────
### Mise Config
### ──────────────
export MISE_POETRY_AUTO_INSTALL=1
export MISE_POETRY_VENV_AUTO=1

mise_bin=$(command -v mise || echo "$HOME/.local/bin/mise") && [ -x "$mise_bin" ] && eval "$("$mise_bin" activate zsh)"
# Added by dbt Fusion extension (ensure dbt binary dir on PATH)
if [[ ":$PATH:" != *":/Users/taaniel.jakobson/.local/bin:"* ]]; then
  export PATH=/Users/taaniel.jakobson/.local/bin:"$PATH"
fi
# Added by dbt Fusion extension
alias dbtf=/Users/taaniel.jakobson/.local/bin/dbt


# Added by Antigravity CLI installer
export PATH="/Users/taaniel.jakobson/.local/bin:$PATH"
