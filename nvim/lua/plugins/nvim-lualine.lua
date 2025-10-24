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
                        "diff",
                    },
                    lualine_c = {
                        {
                            "filename",
                            path = 1,
                        },
                    },
                    lualine_x = {
                        {
                            "diagnostics",
                            source = { "nvim-lsp" },
                        },
                    },
                    lualine_y = {},
                    lualine_z = {},
                },
                inactive_sections = {
                    lualine_a = {
                        {
                            "filename",
                            path = 1,
                        },
                    },
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
}
