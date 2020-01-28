export HOMEBREW_CASK_OPTS="--appdir=/Applications"
export PATH=$HOME/bin:/usr/local/bin:$PATH
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
# vi mode on
set -o vi

# display vi mode
bind 'set show-mode-in-prompt on'

source ~/dotfiles/bash/git-prompt.sh
GIT_PS1_SHOWUPSTREAM=true
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWDIRTYSTATE=true
export PS1='$ '
# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
for env in $(ls $HOME/.anyenv/envs); do
  export PATH="$HOME/.anyenv/envs/$env/shims/:$PATH"
  export PATH="$HOME/.anyenv/envs/$env/bin:$PATH"
done
eval "$(anyenv init -)"
eval "$(goenv init -)"
eval "$(pyenv init -)"
eval "$(direnv hook bash)"
# Python
export PYENV_ROOT=$HOME/.anyenv/envs/pyenv

source ~/.phpbrew/bashrc

# Go
export GO_VERSION=1.12.5
export GO111MODULE=on
export GOROOT=$HOME/.anyenv/envs/goenv/versions/$GO_VERSION
export GOPATH=$HOME/go_work
export PATH=$GOROOT/bin:$PATH
export PATH=$GOPATH/bin:$PATH

# Rust
export PATH=$HOME/.cargo/bin:$PATH

# reading dotfiles
DOT_FILES_PATH="$HOME/dotfiles/"

# aliases
source "$DOT_FILES_PATH/bash/.bash_aliases"
# functions
source "$DOT_FILES_PATH/bash/.bash_functions"
