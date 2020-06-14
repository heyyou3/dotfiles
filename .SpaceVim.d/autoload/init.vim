let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:spacevim_disabled_plugins = ['vim-startify']

function! init#before() abort
  execute 'source '.s:path.'/before.vim'
endfunction

function! init#after() abort
  execute 'source '.s:path.'/after.vim'
endfunction

