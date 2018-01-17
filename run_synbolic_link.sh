#!/bin/sh
# vimrc
mv ~/.vimrc ~/.vimrc.org
ln -s ~/dotfiles/vimrc/_vimrc ~/.vimrc
# zshrc
mv ~/.zshrc ~/.zshrc.org
ln -s ~/dotfiles/zshrc/_zshrc ~/.zshrc
# dein.toml
mv ~/.vim/rc/dein.toml ~/.vim/rc/dein.toml.org
ln -s ~/dotfiles/vimrc/_dein.toml ~/.vim/rc/dein.toml
# dein_lazy.toml
mv ~/.vim/rc/dein_lazy.toml ~/.vim/rc/dein_lazy.toml.org
ln -s ~/dotfiles/vimrc/_dein_lazy.toml ~/.vim/rc/dein_lazy.toml
