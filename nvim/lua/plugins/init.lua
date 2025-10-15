
-- You can add your plugins here
-- Each plugin is a table, and you can add multiple plugins in a single file

local plugins = {}

local plugins_path = vim.fn.stdpath("config") .. "/lua/plugins"
local lua_path = vim.fn.stdpath("config") .. "/lua"

-- Get all .lua files in the plugins directory and subdirectories
local files = vim.fn.glob(plugins_path .. "/**/*.lua", true, true)

for _, file in ipairs(files) do
  -- Construct the module path from the file path
  local module_path = file:sub(#lua_path + 2):gsub(".lua", ""):gsub("/", ".")

  -- Exclude this file (init.lua)
  if module_path ~= "plugins.init" then
    table.insert(plugins, require(module_path))
  end
end

return plugins
