let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function! init#before() abort
  execute 'source '.s:path.'/before.vim'
endfunction

function! init#after() abort
  execute 'source '.s:path.'/after.vim'
endfunction

