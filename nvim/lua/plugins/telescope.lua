return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "MunifTanjim/nui.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
            "nvim-tree/nvim-web-devicons",
            {
                "nvim-telescope/telescope-live-grep-args.nvim",
                version = "^1.0.0",
            },
        },
        config = function()
            local telescope = require("telescope")
            local lga_actions = require("telescope-live-grep-args.actions")
            telescope.setup({
                defaults = {
                    -- レイアウトとサイズに関する設定
                    layout_strategy = "horizontal",
                    layout_config = {
                        prompt_position = "bottom",
                        preview_cutoff = 120,
                    },
                    borderchars = { "-", "|", "-", "|", "+", "+", "+", "|" },

                    sorting_strategy = "ascending",
                    vimgrep_arguments = {
                        "rg",
                        "--color=never",
                        "--column",
                        "--hidden",
                        "--line-number",
                        "--no-heading",
                        "--smart-case",
                        "--with-filename",
                        "--glob",
                        "!**/.git/*",
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                    },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_ivy({}),
                    },
                    ["live_grep_args"] = {
                        auto_quoting = true,
                        mappings = {
                            i = {
                                ["<C-k>"] = lga_actions.quote_prompt(),
                                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob "}),
                            }
                        }
                    }
                },
            })
            telescope.load_extension("ui-select")
            telescope.load_extension("live_grep_args")
        end,
    },
}
