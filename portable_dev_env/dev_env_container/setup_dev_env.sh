#!/bin/bash
set -eux

apt update -y && \
apt install software-properties-common -y && \
add-apt-repository ppa:git-core/ppa && \
add-apt-repository ppa:x4121/ripgrep && \
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
  ripgrep
git clone https://github.com/riywo/anyenv ~/.anyenv

echo -e 'if [ -d $HOME/.anyenv ]\n then \n  \n export PATH="$HOME/.anyenv/bin:$PATH" \neval "$(anyenv init -)" \nfi' >> ~/.bashrc

git clone https://github.com/heyyou3/dotfiles.git "$HOME/dotfiles"

ln -s "$HOME/dotfiles/git/diff-highlight" /usr/local/bin/diff-highlight
chmod +x /usr/local/bin/diff-highlight

cd "$HOME/dotfiles" && /bin/bash ./set_symbolic_link.sh

vim +'PlugInstall --sync' +q +q

git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
tmux start-server
tmux new-session -d "sleep 1"
sleep 0.1
TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/"; /bin/bash "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"

