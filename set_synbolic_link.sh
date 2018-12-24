#!/bin/bash
set_synbolic_link() {
  if [ -e "$1" && -e "$2" ]; then
    mv "$1" "$1".org
    ln -s "$2" "$1"
  else
    echo 'Argument file not found...'
  fi
}
set_synbolic_link '~/.vimrc' '~/dotfiles/vim/_vimrc'
set_synbolic_link '~/.zshrc' '~/dotfiles/zsh/_zshrc'
set_synbolic_link '~/.vim/rc/dein.toml' '~/dotfiles/vim/_dein.toml'
set_synbolic_link '~/.vim/rc/dein_lazy.toml' '~/dotfiles/vim/_dein_lazy.toml'
set_synbolic_link '~/.config/nvim/init.vim' '~/dotfiles/vim/_init.vim'
