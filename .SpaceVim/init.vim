"=============================================================================
" init.vim --- Entry file for neovim
" Copyright (c) 2016-2019 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg at 163.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================

execute 'source' fnamemodify(expand('<sfile>'), ':h').'/config/main.vim'
let $BASH_ENV = '~/dotfiles/bash/.bash_vim'

let vim_settings_dir = getcwd().'/.SpaceVim.d'

if isdirectory(vim_settings_dir)
  execute 'source '.vim_settings_dir.'/settings*.vim'
endif
