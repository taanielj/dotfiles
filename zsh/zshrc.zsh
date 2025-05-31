### ────────────────────────────────
###  Instant Prompt (Powerlevel10k)
### ────────────────────────────────

[[ -r ${p10k_prompt:="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"} ]] && source "$p10k_prompt"


### ────────────────────────────────
###  Completion System (compinstall)
### ────────────────────────────────
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' substitute 1
zstyle :compinstall filename '$HOME/.zshrc'

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

export CASE_SENSITIVE="true"

# Initialize the completion system
autoload -Uz compinit
compinit

# Set select-word-style to bash
autoload -U select-word-style
select-word-style bash

# Make zsh autocomplete with up arrow
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end


### ────────────────────────────────
###  Zinit Plugin Manager
### ────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
# Load zinit
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Check if zmodule is installed and built
# zmodload zdharma/zplugin 2>/dev/null || zinit module build

load=light

# or specify a delay in seconds 
zinit ice wait blockf lucid
zinit $load zsh-users/zsh-completions
zinit ice depth=1
zinit $load romkatv/powerlevel10k

# zinit ice wait lucid
zinit $load zsh-users/zsh-autosuggestions

# zinit ice wait lucid
zinit $load Aloxaf/fzf-tab

# Oh-my-zsh plugins with zinit, use zinit for faster loading
# OMZ:  shorthand for https://github.com/ohmyzsh/ohmyzsh/blob/master
# OMZL: shorthand for OMZ::lib/ 
# OMZP: shorthand for OMZ::plugins/ 
# OMZT: shorthand for OMZ::themes/
setopt promptsubst #required to support most themes

# git.zsh must be loaded
# zinit snippet OMZL::git.zsh
# zinit snippet OMZL::clipboard.zsh
# zinit snippet https:://github.com/ohmyzsh/ohmyzsh/blob/master/lib/clipboard.zsh
# zinit snippet OMZL::termsupport.zsh
# zinit snippet https:://github.com/ohmyzsh/ohmyzsh/blob/master/lib/termsupport.zsh 
zinit snippet OMZP::git
# zinit snippet OMZP::git-auto-fetch

### ────────────────────────────────
###  History Settings
### ────────────────────────────────
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS

### ────────────────────────────────
###  Environment / UI Settings
### ────────────────────────────────

# ----------------------------
# FZF Defaults (recommended)
# ----------------------------
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

# fzf
[[ -f $HOME/.fzf.zsh ]] && source "$HOME/.fzf.zsh"
# mise
[[ -x $HOME/.local/bin/mise ]] && eval "$($HOME/.local/bin/mise activate zsh)"
[[ -z "$MISE_STATUS_MESSAGE_MISSING_TOOLS" ]] && export MISE_STATUS_MESSAGE_MISSING_TOOLS="always"

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)" # zoxide
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)" # direnv
# command -v oh-my-posh >/dev/null 2>&1 && eval "$(oh-my-posh init zsh --config "$HOME/.oh-my-posh.omp.json")"

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
### Everything after this line is added by any automatic script, move them above to organize if you want
### ────────────────────────────────

