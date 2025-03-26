if [[ -r "$XDG_CONFIG_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "$XDG_CONFIG_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### The following lines were added by compinstall
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' substitute 1
zstyle :compinstall filename '$HOME/.zshrc'

autoload -Uz compinit
compinit

export PATH="$PATH:/snap/bin"
### End of lines added by compinstall

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://Github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
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
# eval "$(oh-my-posh init zsh --config $HOME/.oh-my-posh.omp.json)"

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
if [ -f '$HOME/google-cloud-sdk/path.zsh.inc' ]; then . '$HOME/google-cloud-sdk/path.zsh.inc'; fi
# The next line enables shell command completion for gcloud.
if [ -f '$HOME/google-cloud-sdk/completion.zsh.inc' ]; then . '$HOME/google-cloud-sdk/completion.zsh.inc'; fi


if [ -d $HOME/.config/zsh ]; then
    for file in $HOME/.config/zsh/*.zsh; do
        # skip current file (zshrc.zsh is symlinked to $HOME/.zshrc)
        if [ $(basename $file) = "zshrc.zsh" ]; then
        continue
        fi
        source $file
    done
fi
[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local
[[ -f $HOME/.fzf.zsh ]] && source $HOME/.fzf.zsh
# asdf:
[[ -f $HOME/.asdf/asdf.sh ]] && source $HOME/.asdf/asdf.sh
[[ -d $HOME/.asdf/completions ]] && fpath=($HOME/.asdf/completions $fpath)

eval "$(direnv hook zsh)"
# BEGIN ZDI
# So what the hell, ZDI actually installed this to my .zshrc?? not cool, didn't even use -f flag to check if it exists 
# And to top it all of, used absolute path to my home directory, not even $HOME smh, clown-shoes, expected better from
# a company like Zendesk
export DOCKER_FOR_MAC_ENABLED=true # WTF is this doing here??? thanks zendesk, very cool, tbf, I should have checked what files were changed before commiting this to my dotfiles, fair play
[[ -f $HOME/.zdi/zdi.sh ]] && source $HOME/.zdi/zdi.sh # should really be in $HOME/.zshrc.local... leaving here for now 
