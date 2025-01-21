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

## ctrl left and right: move to left or right word (these don't work on mac)
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

## option left and right: move to left or right word (these work on mac)
bindkey "^[[1;3D" backward-word # option left ⌥ + ←
bindkey "^[[1;3C" forward-word # option right ⌥ + →
## ctrl backspace: delete word before cursor, ctrl delete: delete word after cursor
bindkey "^H" backward-kill-word
bindkey "^[[3;3~" kill-word # mac delete
bindkey "^[[3;5~" kill-word # pc delete

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
#on mac the command is fd, on linux, it's fdfind
#alias fd="fdfind"
if command -v fd &> /dev/null; then
  alias fd="fd"
elif command -v fdfind &> /dev/null; then
  alias fd="fdfind"
else
    alias fd="find"
fi

# exa is nolonger maintained, using eza instead, a maintained fork
alias l=ls
alias ls="eza --git-ignore --group-directories-first --icons --color=always --git -h"
alias la="eza --git-ignore --group-directories-first --icons --color=always --git -h -la"
alias tree="eza --tree"


# Custom functions

# Initialize zoxide
eval "$(zoxide init --cmd cd zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
export FZF_DEFAULT_COMMAND='fd --hidden'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#alias nvimf="fd --type f --hidden | fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}' | xargs nvim"
nvimf() {
    if [[ "$1" != "" && -d -$1 ]];
    then
        nvim $(fd . $1 | fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}')]
    else
        nvim $(fd --type f --hidden | fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}')
    fi
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# set alias for python=python3.11
alias python=python3.11

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/taaniel.jakobson/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/taaniel.jakobson/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/taaniel.jakobson/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/taaniel.jakobson/google-cloud-sdk/completion.zsh.inc'; fi

reset_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        source "$VIRTUAL_ENV/bin/activate"
        deactivate
    fi
    rm -rf .venv
    python3.11 -m venv .venv
    source .venv/bin/activate
    python -m pip install --upgrade pip
}


update_reqs() {
    # Step 1: Strip version numbers from requirements.txt in-place
    sed -i '' 's/==.*//g' requirements.txt

    # Step 2: Install all packages from requirements.txt
    python -m pip install --upgrade -r requirements.txt

    # Step 3: Get the installed package versions from pip freeze
    frozen_reqs=$(pip freeze)

    # Step 4: Add version numbers back in-place, preserving comments and blank lines
    while IFS= read -r line; do
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            # Preserve empty lines and comments as is
            echo "$line"
        else
            base_req=$(echo "$line" | sed 's/\[.*\]//')  # Strip extras to match pip freeze
            # Perform a case-insensitive match against pip freeze
            frozen_line=$(echo "$frozen_reqs" | grep -i -m 1 "^${base_req}==")
            if [[ -n $frozen_line ]]; then
                # Append the version to the existing line
                echo "${line}==${frozen_line##*==}"  # Extract and append version
            else
                # If no version is found, keep the line unchanged
                echo "$line"
            fi
        fi
    done < requirements.txt > requirements.tmp

    # Replace the old requirements.txt with the updated file
    mv requirements.tmp requirements.txt
}

# docker compose aliases
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcdv="docker compose down -v"
alias dcr="docker compose run --rm"
alias dcrs="docker compose down && docker compose up -d"



[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
