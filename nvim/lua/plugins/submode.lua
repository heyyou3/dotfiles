return {
  "submode.nvim",
  config = function()
    local builtin = require("telescope.builtin")
    local M = {}

    M.state = {
      active = false,
      name = "",
      active_maps = {},
    }

    local function wincmd(cmd)
      return function()
        vim.cmd("wincmd " .. cmd)
      end
    end

    local modes = {
      lsp = {
        name = "lsp",
        keymaps = {
          D = { vim.lsp.buf.declaration, "LSP Declaration" },
          H = { vim.lsp.buf.hover, "LSP Hover" },
          a = { vim.lsp.buf.code_action, "LSP Code Action" },
          d = { builtin.lsp_definitions, "LSP Definition" },
          e = { function()
            builtin.diagnostics({ bufnr = 0 })
          end, "LSP Diagnostics" },
          i = { vim.lsp.buf.implementation, "LSP Implementation" },
          r = { builtin.lsp_references, "LSP References" },
        },
      },
      window = {
        name = "window",
        keymaps = {
          h = { wincmd "h", "Window left" },
          j = { wincmd "j", "Window down" },
          k = { wincmd "k", "Window up" },
          l = { wincmd "l", "Window right" },
          v = { wincmd "v", "Split vertically" },
          s = { wincmd "s", "Split horizontally" },
          c = { wincmd "c", "Close window" },
          o = { wincmd "o", "Close other windows" },
          ["="] = { wincmd "=", "Equalize window sizes" },
          ["+"] = { wincmd "+", "Increase window height" },
          ["-"] = { wincmd "-", "Decrease window height" },
          [">"] = { wincmd ">", "Increase window width" },
          ["<"] = { wincmd "<", "Decrease window width" },
        },
      },
      buffer = {
        name = "buffer",
        keymaps = {
          L = { function() vim.cmd.blast() end, "Last buffer" },
          f = { function() vim.cmd.bfirst() end, "First buffer" },
          l = { builtin.buffers, "List buffers" },
          n = { function() vim.cmd.bnext() end, "Next buffer" },
          p = { function() vim.cmd.bprevious() end, "Previous buffer" },
          s = { function() vim.cmd.wa() end, "Save all buffers" },
          x = { function() vim.cmd.bdelete() end, "Delete buffer" },
        },
      },
    }

    local function clear_keymaps()
      for key, _ in pairs(M.state.active_maps) do
        pcall(vim.keymap.del, "n", key)
      end
      M.state.active_maps = {}
    end

    function M.exit_mode()
      if not M.state.active then
        return
      end
      clear_keymaps()
      M.state.active = false
      M.state.name = ""
      if pcall(require, "lualine") then
        require("lualine").refresh()
      end
    end

    function M.enter_mode(mode)
      if M.state.active and M.state.name == mode.name then
        M.exit_mode()
        return
      elseif M.state.active then
        M.exit_mode()
      end

      M.state.active = true
      M.state.name = mode.name

      vim.keymap.set("n", "q", M.exit_mode, { nowait = true, desc = "Exit " .. mode.name .. " mode" })
      M.state.active_maps["q"] = true

      for key, mapping in pairs(mode.keymaps) do
        local func, desc = unpack(mapping)
        vim.keymap.set("n", key, func, { nowait = true, desc = desc })
        M.state.active_maps[key] = true
      end

      if pcall(require, "lualine") then
        require("lualine").refresh()
      end
    end

    _G.submode_status = function()
      if M.state.active then
        return string.format("[%s]", M.state.name)
      end
      return ""
    end

    vim.keymap.set("n", "[", function() M.enter_mode(modes.lsp) end, { desc = "Enter LSP submode" })
    vim.keymap.set("n", "<leader>w", function() M.enter_mode(modes.window) end, { desc = "Enter Window submode" })
    vim.keymap.set("n", "<leader>b", function() M.enter_mode(modes.buffer) end, { desc = "Enter Buffer submode" })
  end,
}
