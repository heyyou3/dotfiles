
-- You can add your plugins here
-- Each plugin is a table, and you can add multiple plugins in a single file

local plugins = {
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

  -- Task
  require("plugins.task"),
}

local languages_path = vim.fn.stdpath "config" .. "/lua/plugins/languages"
local lua_path = vim.fn.stdpath "config" .. "/lua"

local files = vim.fn.glob(languages_path .. "/**/*.lua", true, true)
for _, file in ipairs(files) do
  local module_path = file:sub(#lua_path + 2):gsub(".lua", ""):gsub("/", ".")
  table.insert(plugins, require(module_path))
end

return plugins
