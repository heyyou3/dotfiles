"========== START functions =========="
function! ZenkakuSpace()
    highlight ZenkakuSpace cterm=reverse ctermfg=DarkMagenta gui=reverse guifg=DarkMagenta
endfunction

command! -nargs=* Jump call Jump(<f-args>)
function! Jump(line, char)
  execute 'normal ' . a:line . 'G'
  execute 'normal f' . a:char
endfunction
"========== END functions =========="

"========== START default settings =========="
let $LANG = 'en_US'
let $BASH_ENV = '~/dotfiles/bash/.bash_vim'

set belloff=all
set encoding=utf-8
set spell
set spelllang=en,cjk
set langmenu=en_US
set clipboard+=unnamed
set fileencoding=utf-8
set fileencodings=ucs-boms,utf-8,euc-jp,cp932
set fileformats=unix,dos,mac
set ambiwidth=double
set laststatus=2
set showmode
set showcmd
set ruler
set wildmenu
set history=5000
set expandtab
set tabstop=2
set softtabstop=2
set autoindent
set smartindent
set shiftwidth=2
set incsearch
set ignorecase
set smartcase
set hlsearch
set number
set cursorline
set list
set listchars=tab:»-,trail:-,nbsp:%,eol:↲
set autowrite

filetype plugin indent on
highlight Normal ctermbg=none

scriptencoding utf-8

autocmd BufRead,BufNewFile *.md set filetype=markdown
autocmd InsertLeave * set nopaste
autocmd QuickFixCmdPost *grep* cwindow

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

"========== START key binds =========="
noremap <C-n> :cnext<CR>
noremap <C-p> :cprevious<CR>
noremap <C-_> :split<CR>
noremap <C-_><C-_> :vsplit<CR>

nnoremap <leader>d :<C-u>Denite file_rec<CR>
nnoremap <leader>f :<C-u>Jump 
nnoremap <leader>/ :<C-u>Ag 
nnoremap <leader>c :<C-u>cclose<CR>

tnoremap <C-[> <C-w><S-n>
"========== END key binds =========="

"========== START vim plugins settings =========="
let s:vim_plug_file = $HOME.'/.vim/autoload/plug.vim'
let s:vim_plug_dir = $HOME.'/.vim/plugged'

if !filereadable(s:vim_plug_file)
  call system('curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
  call plug#begin(s:vim_plug_dir)
    Plug 'prabirshrestha/async.vim'
    Plug 'prabirshrestha/vim-lsp'
    Plug 'bronson/vim-trailing-whitespace'
    Plug 'vim-airline/vim-airline'
    Plug 'SirVer/ultisnips'
    Plug 'kannokanno/previm'
    Plug 'fatih/vim-go'
    Plug 'tpope/vim-fugitive'
    Plug 'editorconfig/editorconfig-vim'
    Plug 'mattn/emmet-vim'
    Plug 'w0rp/ale'
    Plug 'tpope/vim-abolish'
    Plug 'airblade/vim-gitgutter'
    Plug 'elzr/vim-json'
    Plug 'edkolev/tmuxline.vim'
    Plug 'jacoborus/tender.vim'
    Plug 'jremmen/vim-ripgrep'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
  call plug#end()
  source %
endif

call plug#begin(s:vim_plug_dir)
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'bronson/vim-trailing-whitespace'
Plug 'vim-airline/vim-airline'
Plug 'SirVer/ultisnips'
Plug 'kannokanno/previm'
Plug 'fatih/vim-go'
Plug 'tpope/vim-fugitive'
Plug 'editorconfig/editorconfig-vim'
Plug 'mattn/emmet-vim'
Plug 'w0rp/ale'
Plug 'tpope/vim-abolish'
Plug 'airblade/vim-gitgutter'
Plug 'elzr/vim-json'
Plug 'edkolev/tmuxline.vim'
Plug 'jacoborus/tender.vim'
Plug 'jremmen/vim-ripgrep'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
call plug#end()

syntax on
set t_Co=256
set background=dark
colorscheme tender


let g:tmuxline_preset = {
  \'a'    : '#S',
  \'c'    : ['#{pane_current_path}[#(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD)]'],
  \'win'  : ['#I', '#W'],
  \'cwin' : ['#I', '#W', '#F'],
  \'x'    : '#(date)',
  \'y'    : [''],
  \'z'    : ''}

let g:airline_theme='tender'
let g:airline_section_a = airline#section#create(['mode','','branch'])
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#tab_nr_type = 1
let g:airline#extensions#tabline#fnamemod = ':t'

let g:vim_json_syntax_conceal = 0

let g:vim_markdown_folding_disabled = 1

let g:deoplete#enable_at_startup = 1

let g:go_list_type = 'quickfix'
function! s:build_go_files()
    let l:file = expand('%')
    if l:file =~# '^\f\+_test\.go$'
        call go#test#Test(0, 1)
    elseif l:file =~# '^\f\+\.go$'
        call go#cmd#Build(0)
    endif
endfunction
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
set updatetime=100
let g:go_auto_sameids = 1
let g:go_gocode_unimported_packages = 1

let g:terraform_align = 1
let g:terraform_fold_sections = 1
let g:terraform_remap_spacebar = 1
let g:terraform_fmt_on_save = 1
"========== END vim plugins settings =========="
