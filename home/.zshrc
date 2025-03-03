# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

# ZSH_THEME="skaro"

plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Catppuccin Mocha theme
source ~/.config/zsh/mocha.theme.zsh

source $ZSH/oh-my-zsh.sh
eval "$(starship init zsh)"

# Check archlinux plugin commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux

# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
#pokemon-colorscripts --no-title -s -r

# Set-up icons for files/folders in terminal
alias ls='eza -a --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=1 --icons'

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=10000
setopt appendhistory

# Aliases
alias discord="vesktop"

. "$HOME/.cargo/env"


autoload bashcompinit
bashcompinit
source "$HOME/.bash_completion"
autoload bashcompinit
bashcompinit
source "$HOME/.local/share/bash-completion/completions/am"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
