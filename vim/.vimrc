"========== START functions =========="
function! ZenkakuSpace()
    highlight ZenkakuSpace cterm=reverse ctermfg=DarkMagenta gui=reverse guifg=DarkMagenta
endfunction
"========== END functions =========="

"========== START default settings =========="
let $LANG = 'ja_JP'
let $BASH_ENV = '~/dotfiles/bash/.bash_vim'

set ambiwidth=double
set autoindent
set autoread
set autowrite
set belloff=all
set clipboard+=unnamed
set encoding=utf-8
set expandtab
set fileencoding=utf-8
set fileencodings=ucs-boms,utf-8,euc-jp,cp932
set fileformats=unix,dos,mac
set history=5000
set hlsearch
set ignorecase
set incsearch
set langmenu=en_US
set laststatus=2
set list
set listchars=tab:»-,nbsp:%,eol:↲
set number
set relativenumber
set ruler
set shiftwidth=2
set showcmd
set showmode
set smartcase
set softtabstop=2
set tabstop=2
set ttyfast
set updatetime=100
set wildmenu
set hidden

filetype plugin indent on
highlight Normal ctermbg=none

scriptencoding utf-8

autocmd BufRead,BufNewFile *.md set filetype=markdown
autocmd InsertLeave * set nopaste
autocmd QuickFixCmdPost *grep* cwindow
autocmd InsertEnter,WinEnter * checktime

highlight SpecialKey ctermfg=darkmagenta

if has('syntax')
    augroup ZenkakuSpace
        autocmd!
        autocmd ColorScheme       * call ZenkakuSpace()
        autocmd VimEnter,WinEnter * match ZenkakuSpace /　/
    augroup END
    call ZenkakuSpace()
endif

" git commit 時に差分を表示する
autocmd FileType gitcommit DiffGitCached | wincmd x | resize 10

"========== END default settings =========="

"========== START vim plugins settings =========="
let s:vim_plug_file = $HOME.'/.vim/autoload/plug.vim'
let s:vim_plug_dir = $HOME.'/.vim/plugged'

function! LoadPlugins()
  call plug#begin(s:vim_plug_dir)
    Plug 'airblade/vim-gitgutter'
    Plug 'editorconfig/editorconfig-vim'
    Plug 'elzr/vim-json'
    Plug 'jremmen/vim-ripgrep'
    Plug 'leafgarland/typescript-vim'
    Plug 'prabirshrestha/vim-lsp'
    Plug 'tpope/vim-abolish'
    Plug 'tpope/vim-fugitive'
    Plug 'vim-airline/vim-airline'
    Plug 'w0rp/ale'
    Plug 'honza/vim-snippets'
    Plug 'prabirshrestha/asyncomplete-ultisnips.vim'
    Plug 'arcticicestudio/nord-vim'
    " Plug 'edkolev/tmuxline.vim'
    Plug 'vim-airline/vim-airline-themes'
  call plug#end()
endfunction

if !filereadable(s:vim_plug_file)
  call system('curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
  call LoadPlugins()
  finish
endif

call LoadPlugins()

syntax on
set t_Co=256
set background=dark
colorscheme nord

"let g:tmuxline_preset = {
"  \'a'    : ['#{git_status}'],
"  \'c'    : [''],
"  \'win'  : ['#I', '#W'],
"  \'cwin' : ['#I', '#W', '#F'],
"  \'x'    : '',
"  \'y'    : ['#{pane_current_path}'],
"  \'z'    : '#S'}
"let g:tmuxline_powerline_separators = 1

let g:airline_theme='nord'
let g:airline_solarized_bg='dark'
let g:airline_section_a = airline#section#create(['mode','','branch'])
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#tab_nr_type = 1
let g:airline#extensions#tabline#fnamemod = ':t'

let g:vim_json_syntax_conceal = 0

let g:vim_markdown_folding_disabled = 1

let g:go_list_type = 'quickfix'
let g:go_fmt_command = 'goimports'
let g:go_textobj_include_function_doc = 0
let g:go_fmt_fail_silently = 1
let g:go_addtags_transform = 'camelcase'
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_build_constraints = 1
let g:go_metalinter_enabled = ['vet', 'golint', 'errcheck']
let g:go_metalinter_autosave = 1
let g:go_metalinter_autosave_enabled = ['vet', 'golint']
let g:go_metalinter_deadline = '5s'
let g:go_def_mode = 'godef'
let g:go_decls_includes = 'func,type'
let g:go_auto_type_info = 1
let g:go_auto_sameids = 1
let g:go_gocode_unimported_packages = 1

" 拡張子とファイルタイプの関連付け
autocmd BufNewFile,BufRead *.{asciidoc,adoc,asc} set filetype=asciidoc
let g:previm_open_cmd = 'open -a Google\ Chrome'

set runtimepath+=~/dotfiles/vim/UltiSnips
let g:UltiSnipsSnippetDirectories=[$HOME.'/dotfiles/vim/UltiSnips', 'UltiSnips']

if executable('rls')
  au User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'stable', 'rls']},
        \ 'workspace_config': {'rust': {'clippy_preference': 'on'}},
        \ 'whitelist': ['rust'],
        \ })
endif

let g:rustfmt_autosave = 1

if has('python3')
  let g:UltiSnipsExpandTrigger="<tab>"
  call asyncomplete#register_source(asyncomplete#sources#ultisnips#get_source_options({
        \ 'name': 'ultisnips',
        \ 'whitelist': ['*'],
        \ 'completor': function('asyncomplete#sources#ultisnips#completor'),
        \ }))
endif
"========== END vim plugins settings =========="
