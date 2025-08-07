return {
	{
		"nvim-lualine/lualine.nvim",
		opts = function()
			local opts = {
				options = {
					theme = vim.g.colors_name,
					refresh = {
						statusline = 1000,
					},
					section_separators = "",
					component_separators = "",
				},
				sections = {
					lualine_a = { "branch" },
					lualine_b = {
						"location",
					},
					lualine_c = {
						"diff",
						"filetype",
						{
							"diagnostics",
							source = { "nvim-lsp" },
						},
					},
					lualine_x = {},
					lualine_y = {},
					lualine_z = {},
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = {},
				},

				tabline = {},
				extensions = {},
			}
			return opts
		end,
	},
	{ "nvim-treesitter/nvim-treesitter", branch = "master", lazy = false, build = ":TSUpdate" },
	{
		"maxmx03/dracula.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			---@type dracula
			local dracula = require("dracula")

			dracula.setup({
				transparent = false,
				plugins = {
					["nvim-treesitter"] = true,
					["rainbow-delimiters"] = true,
					["nvim-lspconfig"] = true,
					["nvim-navic"] = true,
					["nvim-cmp"] = true,
					["indent-blankline.nvim"] = true,

					["neo-tree.nvim"] = true,
					["nvim-tree.lua"] = true,
					["which-key.nvim"] = true,
					["dashboard-nvim"] = true,
					["gitsigns.nvim"] = true,

					["neogit"] = true,
					["todo-comments.nvim"] = true,
					["lazy.nvim"] = true,
					["telescope.nvim"] = true,
					["noice.nvim"] = true,
					["hop.nvim"] = true,
					["mini.starter"] = true,
					["mini.cursorword"] = true,
					["bufferline.nvim"] = true,
				},
			})
			vim.cmd.colorscheme("dracula")
		end,
	},
}
