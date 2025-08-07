
return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- To add a new language server, install it and then add a setup call.
      -- Example for rust-analyzer:
      -- lspconfig.rust_analyzer.setup{ capabilities = capabilities }
      -- Example for gopls:
      -- lspconfig.gopls.setup{ capabilities = capabilities }
    end,
  },
}
