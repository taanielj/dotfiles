# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### The following lines were added by compinstall
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' substitute 1
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit

export PATH="$PATH:/snap/bin"
### End of lines added by compinstall

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Oh My Zsh configuration

## Theme configuration
# ZSH_THEME="robbyrussell"
# Powerlevel10k configuration
ZSH_THEME="powerlevel10k/powerlevel10k"

## Plugin configuration
plugins=(
  git
  zsh-autosuggestions
)



## Autocomplete configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

## Update configuration
zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 13

## Source the Oh My Zsh script
source $ZSH/oh-my-zsh.sh

# Environment configuration

## Enable true color support - needed for tmux and nvim
export COLORTERM=truecolor

# Key bindings configuration

## ctrl up and down do nothing
bindkey -s "^[[1;5A" ""
bindkey -s "^[[1;5B" ""

## ctrl left and right: move to left or right word
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

## ctrl backspace: delete word before cursor, ctrl delete: delete word after cursor
bindkey "^H" backward-kill-word
bindkey "5~" kill-word

# Aliases configuration
alias vim=nvim
# on mac, the command is bat, on linux, it's batcat
# alias cat="batcat -p --paging=never"
# check if bat command exists, if not use batcat, if not use cat
if command -v bat &> /dev/null; then
  alias cat="bat --paging=never"
elif command -v batcat &> /dev/null; then
  alias cat="batcat --paging=never"
else
    alias cat="cat"
fi
alias fd="fdfind"
# exa is nolonger maintained, using eza instead, a maintained fork
alias ls="eza --git-ignore --group-directories-first --icons --color=always --git -h"
alias la="eza --git-ignore --group-directories-first --icons --color=always --git -h -la"
alias tree="eza --tree"


# Custom functions

## Find and set branch name var if in git repo
# Not needed with powerlevel10k, keeping here in case I stop using p10k
# function git_branch_name {
#   branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
#   if [[ $branch == "" ]]; then
#     :
#   else
#     echo '- ('$branch')'
#   fi
# }

# Prompt customization
# setopt prompt_subst
# export PS1="%F{#80c080}%n%f:%F{#8080ff}%~%f \$(git_branch_name)$ "


# Initialize zoxide
eval "$(zoxide init --cmd cd zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
