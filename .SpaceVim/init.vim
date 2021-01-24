"=============================================================================
" init.vim --- Entry file for neovim
" Copyright (c) 2016-2019 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg at 163.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================
let g:python_host_prog = $PYENV_ROOT.'/shims/python'
let g:python3_host_prog = $PYENV_ROOT.'/shims/python3'

execute 'source' fnamemodify(expand('<sfile>'), ':h').'/main.vim'
set shellcmdflag=-ic

