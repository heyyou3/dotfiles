"=============================================================================
" init.vim --- Entry file for neovim
" Copyright (c) 2016-2019 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg at 163.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================
execute 'source' fnamemodify(expand('<sfile>'), ':h').'/config/main.vim'
let g:python_host_skip_check = 1
let g:python3_host_skip_check = 1
:set shellcmdflag=-ic

