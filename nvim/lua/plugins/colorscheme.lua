return {
    {
        "nvim-lualine/lualine.nvim",
        opts = function()
            local opts = {
                options = {
                    theme = vim.g.colors_name,
                    refresh = {
                        statusline = 1000,
                    },
                    section_separators = "",
                    component_separators = "",
                },
                sections = {
                    lualine_a = { "branch" },
                    lualine_b = {
                        "location",
                    },
                    lualine_c = {
                        "diff",
                        "filetype",
                        {
                            "diagnostics",
                            source = { "nvim-lsp" },
                        },
                    },
                    lualine_x = {},
                    lualine_y = {},
                    lualine_z = {},
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = {},
                    lualine_x = {},
                    lualine_y = {},
                    lualine_z = {},
                },

                tabline = {},
                extensions = {},
            }
            return opts
        end,
    },
    { "nvim-treesitter/nvim-treesitter", branch = "master", lazy = false, build = ":TSUpdate" },
    {
        "Mofiqul/dracula.nvim",
        config = function()
            vim.cmd.colorscheme("dracula")
        end,
    },
}
