
return {
  "dracula/vim",
  name = "dracula",
  priority = 1000,
  config = function()
    vim.opt.background = "dark"
    vim.cmd.colorscheme("dracula")
  end,
}
