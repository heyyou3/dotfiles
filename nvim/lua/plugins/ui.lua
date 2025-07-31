
return {
  "vim-airline/vim-airline",
  event = "VimEnter",
  dependencies = { "vim-airline/vim-airline-themes" },
  config = function()
    vim.g.airline_theme = "dracula"
    vim.g.airline_solarized_bg = "dark"
    vim.g.airline_section_a = vim.fn["airline#section#create"]({ "mode", "", "branch" })
    vim.g["airline#extensions#tabline#enabled"] = 1
    vim.g["airline#extensions#tabline#show_buffers"] = 0
    vim.g["airline#extensions#tabline#tab_nr_type"] = 1
    vim.g["airline#extensions#tabline#fnamemod"] = ":t"
  end,
}
