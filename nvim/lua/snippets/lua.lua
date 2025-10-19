-- Custom Lua snippets for Lua filetype
local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        "overseer.register_template",
        fmt(
            [[
require("overseer").register_template({{
    name = "{}",
    condition = {{
        filetype = {{
            {}
        }}
    }},
    builder = function()
        return {{
            cmd = {{ "echo" }},
            args = {{ "hoge" }},
            components = {{
                {{ "open_output", focus = true, direction = "vertical" }},
                "default",
            }},
        }}
    end,
}})
]],
            {
                i(1, "template_name"),
                i(2, "condition"),
            }
        ),
        {
            show_condition = function()
                return vim.fn.expand("%:t") == ".nvim.lua"
            end
        }
    ),
}
