#!/bin/bash
set -eux

apt update -y && \
apt install software-properties-common -y && \
add-apt-repository ppa:git-core/ppa && \
add-apt-repository ppa:x4121/ripgrep && \
add-apt-repository ppa:neovim-ppa/stable && \
apt update -y && \
apt install -y \
  build-essential \
  libtool \
  automake \
  autoconf \
  pkg-config \
  apt-utils \
  git \
  tig \
  vim \
  tmux \
  curl \
  language-pack-ja-base \
  language-pack-ja \
  ripgrep \
  libffi-dev \
  libssl-dev \
  zlib1g-dev \
  liblzma-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  python3 \
  python3-pip \
  neovim
git clone https://github.com/riywo/anyenv $HOME/.anyenv
curl -fsSL https://starship.rs/install.sh > $HOME/starship_install.sh
/bin/bash $HOME/starship_install.sh -y

git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
$HOME/.fzf/install

git clone https://github.com/heyyou3/dotfiles.git "$HOME/dotfiles"

curl -sLf https://spacevim.org/install.sh | bash

mkdir "$HOME/.xmonad"

cd "$HOME/dotfiles" && make deploy

chmod +x /usr/local/bin/diff-highlight

pip3 install neovim

git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
tmux start-server
tmux new-session -d "sleep 1"
sleep 0.1
TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/"; /bin/bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"

