set list

inoremap jk <Esc>
inoremap ｊｋ <Esc>

function! TranslateGoogle(country) abort
  exec "'<,'>!trans -b ".a:country
endfunction

command! TransJaToEn call TranslateGoogle('ja:en')
command! TransEnToJa call TranslateGoogle('en:ja')

call SpaceVim#custom#SPC('nnoremap', ['a', 't'], 'ShowMyTodo', 'ShowMyTodo', 1)
call SpaceVim#custom#SPC('nnoremap', ['g', 't'], 'Tig', 'Tig', 1)
call SpaceVim#custom#SPCGroupName(['a', 'g'], '+Google')
call SpaceVim#custom#SPC('nnoremap', ['a', 'g', 'e'], 'TransJaToEn', 'Translate Japanese to English.', 1)
call SpaceVim#custom#SPC('nnoremap', ['a', 'g', 'j'], 'TransEnToJa', 'Translate English to Japanese', 1)

