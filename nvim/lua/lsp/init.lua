-- Modern LSP setup using lspconfig

local lspconfig = require('lspconfig')

-- Setup for each language server
-- The configuration is read from the corresponding file in this directory

lspconfig.lua_ls.setup(require('lsp.lua_ls'))

lspconfig.vtsls.setup(require('lsp.vtsls'))

lspconfig.gopls.setup(require('lsp.gopls'))

-- Note: The server name for lspconfig is 'terraformls', not 'terraform_ls'
lspconfig.terraformls.setup(require('lsp.terraform_ls'))