return {
    "smoka7/hop.nvim",
    config = function()
        require("hop").setup({
            multi_windows = true,
        })
    end,
    keys = {
        { mode = "", "<leader><leader>", "<cmd>HopChar1<CR>", desc = "説明" },
    },
}
