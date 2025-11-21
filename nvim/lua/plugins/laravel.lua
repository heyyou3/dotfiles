return {
    "adalessa/laravel.nvim",
    dependencies = {
        "tpope/vim-dotenv",
        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-neotest/nvim-nio",
        "ravitemer/mcphub.nvim",
    },
    cmd = { "Laravel" },
    event = { "VeryLazy" },
    opts = {
        features = {
            pickers = {
                provider = "telescope", -- "snacks | telescope | fzf-lua | ui-select"
            },
        },
    },
}
