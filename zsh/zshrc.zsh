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

autoload -Uz compinit
compinit

export PATH="$PATH:/snap/bin"

### ────────────────────────────────
###  Oh My Zsh Setup
### ────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"

plugins=(
    git
    git-auto-fetch
)

## Autocomplete config
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
CASE_SENSITIVE="true"

## Update config
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

source $ZSH/oh-my-zsh.sh

### ────────────────────────────────
###  Zinit Plugin Manager
### ────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit light romkatv/powerlevel10k

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

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

### ────────────────────────────────
###  Optional Tools (zoxide, direnv, mise, fzf)
### ────────────────────────────────

# fzf
[[ -f $HOME/.fzf.zsh ]] && source "$HOME/.fzf.zsh"
# mise
[[ -x $HOME/.local/bin/mise ]] && eval "$($HOME/.local/bin/mise activate zsh)"
[[ -z "$MISE_STATUS_MESSAGE_MISSING_TOOLS" ]] && export MISE_STATUS_MESSAGE_MISSING_TOOLS="never"

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
for file in "$HOME"/.config/zsh/*.zsh "$HOME/.zshrc.local"; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "zshrc.zsh" ]] && continue
    source "$file"
done

[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local

### ────────────────────────────────
### Everything after this line is added by any automatic script, move them above to organize if you want
### ────────────────────────────────


