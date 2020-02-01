#!/bin/bash
set_symbolic_link() {
  if ! [ -e "$1" ]; then
    ln -sf "$2" "$1"
  else
    echo "$1 found."
    echo "Create $1.org"
    mv "$1" "$1".org
    ln -sf "$2" "$1"
  fi
}
set_symbolic_link "$HOME/.vimrc" "$HOME/dotfiles/vim/.vimrc"
set_symbolic_link "$HOME/.zshrc" "$HOME/dotfiles/zsh/.zshrc"
set_symbolic_link "$HOME/.tmux.conf" "$HOME/dotfiles/tmux/.tmux.conf"
set_symbolic_link "$HOME/.tigrc" "$HOME/dotfiles/tig/.tigrc"
set_symbolic_link "$HOME/.bashrc" "$HOME/dotfiles/bash/.bashrc"
