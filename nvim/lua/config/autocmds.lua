
-- Highlight full-width spaces and other special characters
vim.api.nvim_set_hl(0, "ZenkakuSpace", { reverse = true, ctermfg = "DarkMagenta" })
vim.api.nvim_set_hl(0, "SpecialKey", { ctermfg = "darkmagenta" })
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" }) -- Make background transparent

local zenkaku_augroup = vim.api.nvim_create_augroup("ZenkakuSpaceGroup", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "ColorScheme" }, {
  group = zenkaku_augroup,
  pattern = "*",
  callback = function()
    -- Re-apply highlight definition in case colorscheme cleared it
    vim.api.nvim_set_hl(0, "ZenkakuSpace", { reverse = true, ctermfg = "DarkMagenta" })
    -- The pattern is the full-width space character
    vim.fn.matchadd("ZenkakuSpace", "　")
  end,
})

-- General Autocommands
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.md",
  command = "set filetype=markdown",
})

-- Set conceallevel for markdown files to enable obsidian.nvim UI features.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  command = "set nopaste",
})
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = "*grep*",
  command = "cwindow",
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinEnter" }, {
  pattern = "*",
  command = "checktime",
})

-- Git commit diff view
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  command = "DiffGitCached | wincmd x | resize 10",
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
    pattern = "*",
    callback = function()
        vim.cmd("checktime")
    end,
    group = vim.api.nvim_create_augroup("AutoReload", { clear = true }),
})
