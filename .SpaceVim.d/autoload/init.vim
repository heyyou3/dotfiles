let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:spacevim_disabled_plugins = ['vim-startify']
let g:spacevim_guifont = 'Cica:h16'

function! init#before() abort
  execute 'source '.s:path.'/before.vim'
  execute 'source '.getcwd().'/.SpaceVim.d/autoload/project_before.vim'
endfunction

function! init#after() abort
  execute 'source '.s:path.'/after.vim'
  execute 'source '.getcwd().'/.SpaceVim.d/autoload/project_after.vim'
endfunction

