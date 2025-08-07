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
  {
      "mvllow/modes.nvim",
      config = function()
          require('modes').setup({
              colors = {
                bg = "#282a36",
                copy = "#f1fa8c",
                delete = "#ff5555",
                change = "#ffb86c",
                format = "#8be9fd",
                insert = "#50fa7b",
                replace = "#ff79c6",
                select = "#bd93f9",
                visual = "#bd93f9",
            },

            -- Set opacity for cursorline and number background
            line_opacity = 0.15,

            -- Enable cursor highlights
            set_cursor = true,

            -- Enable cursorline initially, and disable cursorline for inactive windows
            -- or ignored filetypes
            set_cursorline = true,


            -- Enable line number highlights to match cursorline
            set_number = true,


            -- Enable sign column highlights to match cursorline
            set_signcolumn = true,

            -- Disable modes highlights for specified filetypes
            -- or enable with prefix "!" if otherwise disabled (please PR common patterns)
            -- Can also be a function fun():boolean that disables modes highlights when true
            -- ignore = { 'NvimTree', 'TelescopePrompt', '!minifiles' }
          })
      end,
  }
}
