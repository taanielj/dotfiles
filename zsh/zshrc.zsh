if [[ -r "$XDG_CONFIG_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "$XDG_CONFIG_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
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

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit light romkatv/powerlevel10k


## Plugin configuration
plugins=(
    git
    git-auto-fetch
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

## Enable true color support - needed for tmux and nvim
export COLORTERM=truecolor

# Initialize zoxide
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init --cmd cd zsh)"
fi
# eval "$(oh-my-posh init zsh --config ~/.oh-my-posh.omp.json)"

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
export FZF_DEFAULT_COMMAND='fd --hidden'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/taaniel.jakobson/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/taaniel.jakobson/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/taaniel.jakobson/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/taaniel.jakobson/google-cloud-sdk/completion.zsh.inc'; fi


if [ -d ~/.config/zsh ]; then
    for file in ~/.config/zsh/*.zsh; do
        # skip current file (zshrc.zsh is symlinked to ~/.zshrc)
        if [ $(basename $file) = "zshrc.zsh" ]; then
        continue
        fi
        source $file
    done
fi
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
eval "$(direnv hook zsh)"
# BEGIN ZDI
export DOCKER_FOR_MAC_ENABLED=true
source /Users/taaniel.jakobson/git/Zendesk/zdi/dockmaster/zdi.sh
# END ZDI
