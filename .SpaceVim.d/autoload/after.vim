if executable("rg")
  set grepprg=rg\ --vimgrep\ --no-heading
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

autocmd QuickFixCmdPost *grep* cwindow

augroup neosnippet_group
  autocmd FileType neosnippet setlocal noexpandtab
augroup END
