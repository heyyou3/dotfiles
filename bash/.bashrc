export HOMEBREW_CASK_OPTS="--appdir=/Applications"
# User specific aliases and functions
export PATH=$HOME/bin:/usr/local/bin:$PATH
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

source ~/dotfiles/bash/git-prompt.sh
GIT_PS1_SHOWUPSTREAM=true
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWDIRTYSTATE=true
export PS1='[\W\[\033[37m\]]\[\033[31m\]$(__git_ps1)\[\033[00m\]\$ '
# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
for env in $(ls $HOME/.anyenv/envs); do
  export PATH="$HOME/.anyenv/envs/$env/shims/:$PATH"
  export PATH="$HOME/.anyenv/envs/$env/bin:$PATH"
done
# eval "$(anyenv init -)"
# eval "$(goenv init -)"
eval "$(direnv hook bash)"
# Python
export PYENV_ROOT=$HOME/.anyenv/envs/pyenv

# Go
export GO_VERSION=1.11.2
export GO111MODULE=on
export GOROOT=$HOME/.anyenv/envs/goenv/versions/$GO_VERSION
export GOPATH=$HOME/go_work
export PATH=$GOROOT/bin:$PATH
export PATH=$GOPATH/bin:$PATH
alias gotest='(){go test -v -coverprofile=cover.out; go tool cover -html=cover.out}'
alias tf='terraform'
alias pvim='vim $(ls | peco)'
alias less='less -X'
alias tmux='TERM=screen-256color-bce tmux -u'
