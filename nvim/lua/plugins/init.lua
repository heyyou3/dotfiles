
-- You can add your plugins here
-- Each plugin is a table, and you can add multiple plugins in a single file

return {
  -- Colorscheme
  require("plugins.colorscheme"),

  -- UI Enhancements
  require("plugins.ui"),

  -- Git integration
  require("plugins.git"),

  -- Utilities
  require("plugins.utils"),

  -- Linting
  require("plugins.linting"),

  -- Snippets
  require("plugins.snippets"),

  -- LSP and Autocompletion
  require("plugins.lsp"),
  require("plugins.cmp"),

  -- Obsidian
  require("plugins.obsidian"),

  -- Telescope
  require("plugins.telescope"),
}
