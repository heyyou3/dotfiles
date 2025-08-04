local lua_ls_opts = require('lsp.lua_ls')
vim.lsp.config('lua_ls', lua_ls_opts)
vim.lsp.enable('lua_ls')

local vtsls_opts = require('lsp.vtsls')
vim.lsp.config('vtsls', vtsls_opts)
vim.lsp.enable('vtsls')
