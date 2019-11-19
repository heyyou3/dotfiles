#!/bin/bash
set_synbolic_link() {
  if ! [ -e "$1" ]; then
    ln -sf "$2" "$1"
  else
    echo "$1 found."
    echo "Create $1.org"
    mv "$1" "$1".org
    ln -sf "$2" "$1"
  fi
}
set_synbolic_link "$HOME/.vimrc" "$HOME/dotfiles/vim/_vimrc"
set_synbolic_link "$HOME/.zshrc" "$HOME/dotfiles/zsh/_zshrc"
set_synbolic_link "$HOME/.tmux.conf" "$HOME/dotfiles/tmux/_tmux.conf"
set_synbolic_link "$HOME/.tigrc" "$HOME/dotfiles/tig/_tigrc"
set_synbolic_link "$HOME/.bashrc" "$HOME/dotfiles/bash/.bashrc"
