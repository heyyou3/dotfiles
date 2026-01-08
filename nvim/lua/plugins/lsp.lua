return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    config = function()
        local lspconfig = require("lspconfig")
        local mason = require("mason")
        local mason_lspconfig = require("mason-lspconfig")
        local util = require("lspconfig.util")

        mason.setup()

        mason_lspconfig.setup({
            ensure_installed = {
                "gopls",
                "laravel_ls",
                "lua_ls",
                "phpactor",
                "pyright",
                "terraformls",
                "vtsls",
            },
            handlers = {
                function(server_name)
                    -- デフォルトのオプションを準備
                    local server_opts = (servers and servers[server_name]) or {}

                    -- terraformls の場合のみ特別な設定を注入
                    if server_name == "terraformls" then
                        server_opts = vim.tbl_deep_extend("force", server_opts, {
                            -- root_dir が nil にならないよう、プロジェクトルートを特定させる
                            root_dir = util.root_pattern(".terraform", ".git", "main.tf"),
                            -- 二重起動を抑制
                            single_file_support = false,
                            -- インデックス作成と警告抑制の設定
                            init_options = {
                                ignoreSingleFileWarning = true,
                                experimentalFeatures = {
                                    prefillRequiredFields = true,
                                }
                            },
                        })
                    end

                    lspconfig[server_name].setup(server_opts)
                end,
            },
        })
    end,
}
