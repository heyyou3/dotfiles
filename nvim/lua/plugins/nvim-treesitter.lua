return {
    {
        "nvim-treesitter/nvim-treesitter",
        tags = "v0.10.0",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                highlight = {
                    enable = true,
                },
                ensure_installed = {
                    "blade",
                    "go",
                    "html",
                    "javascript",
                    "lua",
                    "php",
                    "php",
                    "python",
                    "sql",
                    "typescript",
                },
            })
        end,
    },
}
