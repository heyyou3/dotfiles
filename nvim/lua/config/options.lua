
-- set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- set options
vim.opt.ambiwidth = "double"
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.belloff = "all"
vim.opt.clipboard = "unnamedplus"
vim.opt.encoding = "utf-8"
vim.opt.expandtab = true
vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = "ucs-boms,utf-8,euc-jp,cp932"
vim.opt.fileformats = "unix,dos,mac"
vim.opt.history = 5000
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.laststatus = 2
vim.opt.list = true
vim.opt.listchars = "tab:»-,nbsp:%,eol:↲"
vim.opt.number = true
vim.opt.ruler = true
vim.opt.shiftwidth = 2
vim.opt.showcmd = true
vim.opt.smartcase = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.updatetime = 100
vim.opt.wildmenu = true
vim.opt.hidden = true
vim.opt.termguicolors = true -- Recommended for modern colorschemes

-- enable filetype detection, plugins and indentation
vim.cmd("filetype plugin indent on")
vim.cmd("syntax on")

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
