return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("telescope").setup({
				defaults = {
					-- レイアウトとサイズに関する設定
					layout_strategy = "horizontal",
					layout_config = {
						prompt_position = "bottom",
						preview_cutoff = 120,
					},
					borderchars = { "-", "|", "-", "|", "+", "+", "+", "|" },

					sorting_strategy = "ascending",
					vimgrep_arguments = {
						"rg",
						"--color=never",
						"--column",
						"--hidden",
						"--line-number",
						"--no-heading",
						"--smart-case",
						"--with-filename",
						"--glob",
						"!**/.git/*",
					},
				},
				pickers = {
					find_files = {
						hidden = true,
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_ivy({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}
