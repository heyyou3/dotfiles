-- This file was converted from .vimrc by an AI assistant.
-- It uses lazy.nvim for plugin management. Deprecated plugins have been
-- replaced with modern Neovim alternatives.

--[[
================================================================================
  General Settings
================================================================================
]]

-- Environment variables
vim.env.LANG = 'ja_JP'

-- Options
vim.opt.ambiwidth = 'double'
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.belloff = 'all'
vim.opt.clipboard = 'unnamed'
vim.opt.encoding = 'utf-8'
vim.opt.expandtab = true
vim.opt.fileencoding = 'utf-8'
vim.opt.fileencodings = 'ucs-boms,utf-8,euc-jp,cp932'
vim.opt.fileformats = 'unix,dos,mac'
vim.opt.history = 5000
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.laststatus = 2
vim.opt.list = true
vim.opt.listchars = 'tab:»-,nbsp:%,eol:↲'
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

-- Enable filetype detection, plugins and indentation
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')

--[[
================================================================================
  Highlights & Autocommands
================================================================================
]]

-- Highlight full-width spaces and other special characters
vim.api.nvim_set_hl(0, "ZenkakuSpace", { reverse = true, ctermfg = "DarkMagenta" })
vim.api.nvim_set_hl(0, "SpecialKey", { ctermfg = "darkmagenta" })
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" }) -- Make background transparent

local zenkaku_augroup = vim.api.nvim_create_augroup("ZenkakuSpaceGroup", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "ColorScheme" }, {
  group = zenkaku_augroup,
  pattern = "*",
  callback = function()
    -- Re-apply highlight definition in case colorscheme cleared it
    vim.api.nvim_set_hl(0, "ZenkakuSpace", { reverse = true, ctermfg = "DarkMagenta" })
    -- The pattern is the full-width space character
    vim.fn.matchadd("ZenkakuSpace", "　")
  end,
})

-- General Autocommands
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.md",
  command = "set filetype=markdown",
})
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  command = "set nopaste",
})
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = "*grep*",
  command = "cwindow",
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinEnter" }, {
  pattern = "*",
  command = "checktime",
})

-- Git commit diff view
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  command = "DiffGitCached | wincmd x | resize 10",
})


--[[
================================================================================
  Plugin Manager (lazy.nvim)
================================================================================
]]

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--[[
================================================================================
  Plugin Definitions
================================================================================
]]

require("lazy").setup({
  -- Colorscheme
  { "dracula/vim", name = "dracula", priority = 1000 },

  -- UI Enhancements (Airline)
  {
    "vim-airline/vim-airline",
    event = "VimEnter",
    dependencies = { "vim-airline/vim-airline-themes" },
    config = function()
      vim.g.airline_theme = 'dracula'
      vim.g.airline_solarized_bg = 'dark'
      vim.g.airline_section_a = vim.fn['airline#section#create']({'mode','','branch'})
      vim.g['airline#extensions#tabline#enabled'] = 1
      vim.g['airline#extensions#tabline#show_buffers'] = 0
      vim.g['airline#extensions#tabline#tab_nr_type'] = 1
      vim.g['airline#extensions#tabline#fnamemod'] = ':t'
    end,
  },

  -- Git integration
  { "tpope/vim-fugitive", cmd = "Git" },
  { "airblade/vim-gitgutter", event = "BufReadPre" },

  -- Utilities
  "tpope/vim-abolish",
  { "editorconfig/editorconfig-vim", event = "BufReadPre" },

  -- Linting (ALE)
  { "dense-analysis/ale", event = {"BufWritePost", "BufReadPost"} },

  -- Snippets
  { "honza/vim-snippets", dependencies = {"SirVer/ultisnips"} },
  { "SirVer/ultisnips", event = "InsertEnter" },

  -- LSP and Autocompletion
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      -- Autocompletion Engine (nvim-cmp)
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      { "quangnguyen30192/cmp-nvim-ultisnips", dependencies = {"SirVer/ultisnips"} },
    },
    config = function()
      local cmp = require('cmp')
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["UltiSnips#Anon"](args.body)
          end,
        },
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'ultisnips' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        }),
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
      })

      -- To add a new language server, install it and then add a setup call.
      -- Example for rust-analyzer:
      -- lspconfig.rust_analyzer.setup{ capabilities = capabilities }
      -- Example for gopls:
      -- lspconfig.gopls.setup{ capabilities = capabilities }
    end,
  },
})

--[[
================================================================================
  Post-Plugin Setup
================================================================================
]]
vim.opt.background = 'dark'
vim.cmd.colorscheme "dracula"
