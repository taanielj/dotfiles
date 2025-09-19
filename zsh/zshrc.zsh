### ────────────────────────────────
###  Instant Prompt (Powerlevel10k)
### ────────────────────────────────
# This slows down shell startup by... it runs as fast as p10k itself, no benefit
# [[ -r ${p10k_prompt:="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"} ]] && source "$p10k_prompt"


### ────────────────────────────────
###  Completion System
### ────────────────────────────────
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' substitute 1
zstyle :compinstall filename '$HOME/.zshrc'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export CASE_SENSITIVE="true"

# Use a cache dir (adjust path as you like)
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
mkdir -p "$(dirname "$ZSH_COMPDUMP")"
# Autoload compinit if not compiled yet
autoload -Uz compinit

# Compile if needed
if [[ ! -s $ZSH_COMPDUMP.zwc || $ZSH_COMPDUMP -ot $ZSH_COMPDUMP ]]; then
  compinit -d "$ZSH_COMPDUMP"
  zcompile "$ZSH_COMPDUMP"
else
  compinit -C -d "$ZSH_COMPDUMP"
fi
autoload -U select-word-style
select-word-style bash

autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end


### ────────────────────────────────
###  Zinit Plugin Manager
### ────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

setopt promptsubst

# Powerlevel10k — eager load for stable prompt
zinit ice depth=1 lucid
zinit light romkatv/powerlevel10k

# Core plugins — lazy load
zinit wait lucid for \
  zsh-users/zsh-autosuggestions \
  Aloxaf/fzf-tab \
  zsh-users/zsh-syntax-highlighting

# Completions — reload after plugin is added
zinit ice wait'1' blockf lucid atload'compinit -u'
zinit light zsh-users/zsh-completions

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

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
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
export PATH=$HOME/.local/nvim/bin:$PATH

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
###  Optional Tools (zoxide, direnv, mise, fzf)
### ────────────────────────────────
[[ -f $HOME/.fzf.zsh ]] && source "$HOME/.fzf.zsh"
[[ -z "$MISE_STATUS_MESSAGE_MISSING_TOOLS" ]] && export MISE_STATUS_MESSAGE_MISSING_TOOLS="always"

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"


### ────────────────────────────────
###  Google Cloud SDK Integration
### ────────────────────────────────
[[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"
[[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"


### ────────────────────────────────
###  User Configuration Files
### ────────────────────────────────
for file in "$HOME"/.config/zsh/*.zsh; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "zshrc.zsh" ]] && continue
    source "$file"
done

[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local


### ────────────────────────────────
### Everything after this line is added by any automatic script
### ────────────────────────────────
{ command -v /opt/homebrew/bin/mise >/dev/null 2>&1 && eval "$(/opt/homebrew/bin/mise activate zsh)"; } || \
{ command -v ~/.local/bin/mise  >/dev/null 2>&1 && eval "$(~/.local/bin/mise activate zsh)"; } || \
echo "mise not found"


