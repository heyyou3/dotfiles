export PATH=$HOME/bin:/usr/local/bin:$PATH
export LC_ALL=ja_JP.UTF-8
export LANG=ja_JP.UTF-8
export STARSHIP_CONFIG=~/dotfiles/.starship/starship.toml

if [ "$(uname)" = 'Darwin' ]; then
  export HOMEBREW_CASK_OPTS="--appdir=/Applications"
fi

if [ -d "$HOME/.anyenv" ]; then
  export PATH=$HOME/.anyenv/bin:$PATH
  eval "$(anyenv init - --no-rehash)"

  export PYENV_ROOT=$HOME/.anyenv/envs/pyenv

  export GO_VERSION=1.12.5
  export GO111MODULE=on
  export GOROOT=$HOME/.anyenv/envs/goenv/versions/$GO_VERSION
  export GOPATH=$HOME/go_work
  export PATH=$GOROOT/bin:$PATH
  export PATH=$GOPATH/bin:$PATH
fi

if [ -d "$HOME/.cargo" ]; then
  export PATH=$HOME/.cargo/bin:$PATH
  export RUSTC_WRAPPER=$(which sccache)
fi

if [ "$(hostname)" = 'heyyou-MiniBook' ]; then
  # Xmodmap を読み込み
  xmodmap ~/.Xmodmap
fi

DOT_FILES_PATH="$HOME/dotfiles"
source "$DOT_FILES_PATH/bash/git-prompt.sh"
source "$DOT_FILES_PATH/bash/git-completion"
source "$DOT_FILES_PATH/common_sh/aliases"
source "$DOT_FILES_PATH/common_sh/functions"

[ -f "$DOT_FILES_PATH/bash/.fzf.bash" ] && source "$DOT_FILES_PATH/bash/.fzf.bash"

eval "$(starship init bash)"

