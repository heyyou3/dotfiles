return {
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    opts = {
        opts = {
            log_level = "DEBUG",
        },
    },
    adapters = {
        acp = {
            gemini_cli = function()
                return require("codecompanion.adapters").extend("gemini_cli", {
                    env = {
                        api_key = "cmd:op read op://personal/Gemini/credential --no-newline",
                    },
                })
            end,
        },
    },
}
