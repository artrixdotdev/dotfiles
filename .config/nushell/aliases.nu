alias l = ls --all
alias c = clear
alias ll = ls -l

# List tree
alias lt = eza --tree --level=2 --long --icons --git

# Pretty git logs
alias glog = git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit

def --env cx [arg] {
    cd $arg
    ls -l
}

def --wrapped v [...args] {
    nvim ...$args
}

def --wrapped fleet [...args] {
    ^~/dotfiles/scripts/zellij-fleet.nu ...$args
}
