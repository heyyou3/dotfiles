return {
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup({
        -- your personnal icons can be defined here
        -- you can specify a filetype name or the full file name
        -- default = true will use the default icon provided
        -- and override any icon defined in this setup function
        override = {
          -- zsh = {
          --   icon = "",
          --   color = "#428850",
          --   name = "Zsh",
          -- },
        },
        -- globally enable default icons (default to false)
        -- will get overriden by `get_icons` option
        default = true,
      })
    end,
  },
}
