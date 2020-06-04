if executable("rg")
  set grepprg=rg\ --vimgrep\ --no-heading
  set grepformat=%f:%l:%c:%m,%f:%l:%m
endif

autocmd QuickFixCmdPost *grep* cwindow

let vim_project_dir = '.vim_project_conf'

if $VIM_PROJECT_CONF != "" && isdirectory($VIM_PROJECT_CONF.'/'.vim_project_dir)
  execute 'source '.$VIM_PROJECT_CONF.'/'.vim_project_dir.'/*.vim'
endif

