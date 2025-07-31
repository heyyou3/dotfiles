
return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      -- Autocompletion Engine (nvim-cmp)
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      { "quangnguyen30192/cmp-nvim-ultisnips", dependencies = { "SirVer/ultisnips" } },
    },
    config = function()
      local cmp = require("cmp")
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["UltiSnips#Anon"](args.body)
          end,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "ultisnips" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
      })

      -- To add a new language server, install it and then add a setup call.
      -- Example for rust-analyzer:
      -- lspconfig.rust_analyzer.setup{ capabilities = capabilities }
      -- Example for gopls:
      -- lspconfig.gopls.setup{ capabilities = capabilities }
    end,
  },
}
