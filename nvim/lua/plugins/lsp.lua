return {
    {
        "neovim/nvim-lspconfig",
        event = "BufReadPre",
        config = function()
            -- Use vim.lsp.config as required by the deprecation warning

            -- Load custom settings from files in lsp/
            local lua_ls_opts = require("lsp.lua_ls")
            local vtsls_opts = require("lsp.vtsls")
            local gopls_opts = require("lsp.gopls")
            local terraform_opts = require("lsp.terraform_ls")

            -- Configure servers
            vim.lsp.config("lua_ls", lua_ls_opts)
            vim.lsp.config("vtsls", vtsls_opts)
            vim.lsp.config("gopls", gopls_opts)
            vim.lsp.config("terraformls", terraform_opts) -- Use 'terraformls' as the server name

            vim.lsp.enable("lua_ls")
            vim.lsp.enable("vtsls")
            vim.lsp.enable("gopls")
            vim.lsp.enable("terraformls")
        end,
    },
}
