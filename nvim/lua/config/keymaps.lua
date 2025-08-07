local builtin = require("telescope.builtin")
local utils = require("config.utils")
vim.keymap.set("n", "<leader>dd", builtin.diagnostics, { desc = "Telescope diagnostics" })
vim.keymap.set("n", "<leader>;;", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fp", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>xx", function()
  vim.cmd("on")
end, { desc = "Only buffer" })

-- Live grep with empty input in normal mode
vim.keymap.set("n", "<leader>ff", builtin.live_grep, { desc = "Telescope live grep" })

-- Live grep with visual selection in visual mode
vim.keymap.set("v", "<leader>ff", function()
  -- Yank the visual selection to a dedicated register 'a' to avoid side effects
  vim.cmd('noau normal! "ay"')
  local text = vim.fn.getreg('a')
  text = text:gsub("\n", " ")
  builtin.live_grep({ default_text = text })
end, { desc = "Telescope live grep selection" })

vim.keymap.set("n", "<leader>rr", function()
  vim.cmd("e!")
end, { desc = "Reload" })

vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>ti", utils.insert_timestamp, { desc = "Insert current timestamp" })
vim.keymap.set("n", "[d", builtin.lsp_definitions, { desc = "Telescope lsp_definitions"})
vim.keymap.set("n", "[r", builtin.lsp_references, { desc = "Telescope lsp_references"})
