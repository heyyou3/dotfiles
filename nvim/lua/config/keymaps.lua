local builtin = require("telescope.builtin")
local utils = require("config.utils")
vim.keymap.set("n", "<leader>dd", function()
    builtin.diagnostics({ bufnr = 0 })
end, { desc = "Telescope diagnostics" })
vim.keymap.set("n", "<leader>''", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>;;", "<cmd>OverseerRun<CR>", { desc = "overseer run" })
vim.keymap.set("n", "<leader>fp", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>xx", function()
    vim.cmd("on")
end, { desc = "Only buffer" })

-- Live grep with empty input in normal mode
vim.keymap.set("n", "<leader>ff", function()
    require("telescope").extensions.live_grep_args.live_grep_args()
end, { desc = "Telescope live grep" })

-- Live grep with visual selection in visual mode
vim.keymap.set("v", "<leader>ff", function()
    vim.cmd('noau normal! "ay"')
    local text = vim.fn.getreg("a")
    text = text:gsub("\n", " ")
    require("telescope").extensions.live_grep_args.live_grep_args({ default_text = text })
end, { desc = "Telescope live grep selection" })

vim.keymap.set("n", "<leader>/", function()
    require("telescope.builtin").live_grep({
        search_dirs = { vim.fn.expand("%:p") },
        default_text = "",
    })
end, { desc = "Telescope live grep current directory" })

vim.keymap.set("v", "<leader>/", function()
    vim.cmd('noau normal! "ay"')
    local text = vim.fn.getreg("a")
    text = text:gsub("\n", " ")
    require("telescope.builtin").live_grep({
        search_dirs = { vim.fn.expand("%:p") },
        default_text = text,
    })
end, { desc = "Telescope live grep current directory" })

vim.keymap.set("n", "<leader>rr", function()
    vim.cmd("e!")
end, { desc = "Reload" })

vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>ti", utils.insert_timestamp, { desc = "Insert current timestamp" })
vim.keymap.set("n", "[d", builtin.lsp_definitions, { desc = "Telescope lsp_definitions" })
vim.keymap.set("n", "[r", builtin.lsp_references, { desc = "Telescope lsp_references" })
vim.keymap.set({ "n", "v" }, "<C-j>", "<cmd>HopChar1<CR>", { desc = "Jump" })
vim.keymap.set("n", "<leader>gd", ":Gitsigns diffthis<CR>", { desc = "Gitsigns diff" })

-- Buffer operations (Ctrl+Shift)
-- Note: Many terminals don't distinguish Ctrl+Shift+letter from Ctrl+letter.
-- If these don't work distinctly, consider mapping terminal keybindings to send unique sequences.
vim.keymap.set("n", "<C-S-x>", "<cmd>bdelete<CR>", { desc = "Buffer delete (Ctrl+Shift+X)" })
vim.keymap.set("n", "<C-S-n>", "<cmd>bnext<CR>", { desc = "Next buffer (Ctrl+Shift+N)" })
vim.keymap.set("n", "<C-S-p>", "<cmd>bprevious<CR>", { desc = "Previous buffer (Ctrl+Shift+P)" })

-- Alacritty CSI u sequences for Ctrl+Shift+X/N/P
vim.keymap.set("n", "<Esc>[120;6u", "<cmd>BufferDelete<CR>", { desc = "Buffer delete (CSI u)" })
vim.keymap.set("n", "<Esc>[110;6u", "<cmd>BufferNext<CR>", { desc = "Next buffer (CSI u)" })
vim.keymap.set("n", "<Esc>[112;6u", "<cmd>BufferPrevious<CR>", { desc = "Previous buffer (CSI u)" })

vim.keymap.set("n", "<leader>m", ":Grapple toggle<cr>", { desc = "Grapple toggle tag" })
vim.keymap.set("n", "<leader>M", ":Grapple toggle_tags<cr>", { desc = "Grapple open tags window" })
vim.keymap.set("n", "<leader>n", ":Grapple cycle_tags next<cr>", { desc = "Grapple cycle next tag" })
vim.keymap.set("n", "<leader>p", ":Grapple cycle_tags prev<cr>", { desc = "Grapple cycle previous tag" })
