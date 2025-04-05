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

HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
export FZF_DEFAULT_COMMAND='fd --hidden'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# The next lines update PATH for the Google Cloud SDK and enable shell command completion for gcloud.
[[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"
[[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"

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
# mise
[[ -f $HOME/.local/bin/mise ]] && eval "$($HOME/.local/bin/mise activate zsh)"
[[ -z "$MISE_STATUS_MESSAGE_MISSING_TOOLS" ]] && export MISE_STATUS_MESSAGE_MISSING_TOOLS="never"

eval "$(direnv hook zsh)"
export PATH=$HOME/.local/nvim/bin:$PATH
