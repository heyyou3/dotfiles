-- This file was converted from .vimrc by an AI assistant.
-- It uses lazy.nvim for plugin management. Deprecated plugins have been
-- replaced with modern Neovim alternatives.

--[[
================================================================================
  General Settings
================================================================================
]]

-- Environment variables
vim.env.LANG = "ja_JP"

-- リーダーキーをスペースに設定
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.ambiwidth = "double"
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.belloff = "all"
vim.opt.clipboard = "unnamed"
vim.opt.encoding = "utf-8"
vim.opt.expandtab = true
vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = "ucs-boms,utf-8,euc-jp,cp932"
vim.opt.fileformats = "unix,dos,mac"
vim.opt.history = 5000
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.laststatus = 2
vim.opt.list = true
vim.opt.listchars = "tab:»-,nbsp:%,eol:↲"
vim.opt.number = true
vim.opt.ruler = true
vim.opt.shiftwidth = 2
vim.opt.showcmd = true
vim.opt.smartcase = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.updatetime = 100
vim.opt.wildmenu = true
vim.opt.hidden = true
vim.opt.termguicolors = true -- Recommended for modern colorschemes

-- Enable filetype detection, plugins and indentation
vim.cmd("filetype plugin indent on")
vim.cmd("syntax on")

--[[
================================================================================
  Highlights & Autocommands
================================================================================
]]

-- Highlight full-width spaces and other special characters
vim.api.nvim_set_hl(0, "ZenkakuSpace", { reverse = true, ctermfg = "DarkMagenta" })
vim.api.nvim_set_hl(0, "SpecialKey", { ctermfg = "darkmagenta" })
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" }) -- Make background transparent

local zenkaku_augroup = vim.api.nvim_create_augroup("ZenkakuSpaceGroup", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "ColorScheme" }, {
	group = zenkaku_augroup,
	pattern = "*",
	callback = function()
		-- Re-apply highlight definition in case colorscheme cleared it
		vim.api.nvim_set_hl(0, "ZenkakuSpace", { reverse = true, ctermfg = "DarkMagenta" })
		-- The pattern is the full-width space character
		vim.fn.matchadd("ZenkakuSpace", "　")
	end,
})

-- General Autocommands
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "*.md",
	command = "set filetype=markdown",
})

-- Set conceallevel for markdown files to enable obsidian.nvim UI features.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.conceallevel = 2
	end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*",
	command = "set nopaste",
})
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
	pattern = "*grep*",
	command = "cwindow",
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinEnter" }, {
	pattern = "*",
	command = "checktime",
})

-- Git commit diff view
vim.api.nvim_create_autocmd("FileType", {
	pattern = "gitcommit",
	command = "DiffGitCached | wincmd x | resize 10",
})

-- Custom command to insert timestamp
vim.api.nvim_create_user_command("InsertTimestamp", function()
	-- Format: 2025-07-15T00:00:00+09:00
	-- The %:z format specifier is a GNU extension and may not be available on all systems.
	-- We will calculate the timezone offset manually for better portability.
	local now = os.time()
	local timestamp_part = os.date("%Y-%m-%dT%H:%M:%S", now)

	local local_t = os.date("*t", now)
	local utc_t = os.date("!*t", now)
	local offset_seconds = os.time(local_t) - os.time(utc_t)

	local sign = offset_seconds >= 0 and "+" or "-"
	local offset_abs = math.abs(offset_seconds)
	local offset_hours = string.format("%02d", math.floor(offset_abs / 3600))
	local offset_minutes = string.format("%02d", math.floor((offset_abs % 3600) / 60))
	local tz_offset = sign .. offset_hours .. ":" .. offset_minutes

	local timestamp = "## " .. timestamp_part .. tz_offset
	vim.api.nvim_put({ timestamp }, "c", true, true)
end, { desc = "Insert current timestamp in ISO 8601 format" })

-- Custom command to copy file path and line number
vim.api.nvim_create_user_command("CopyLocation", function(opts)
	local file_path = vim.fn.expand("%")
	local line_number = opts.line1
	local location = file_path .. ":" .. line_number
	vim.fn.setreg("+", location)
	vim.notify("Copied: " .. location)
end, { desc = "Copy current file path and line number to clipboard", range = true })

--[[
================================================================================
  Plugin Manager (lazy.nvim)
================================================================================
]]

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

--[[
================================================================================
  Plugin Definitions
================================================================================
]]

require("lazy").setup({
	-- Colorscheme
	{ "dracula/vim", name = "dracula", priority = 1000 },

	-- UI Enhancements (Airline)
	{
		"vim-airline/vim-airline",
		event = "VimEnter",
		dependencies = { "vim-airline/vim-airline-themes" },
		config = function()
			vim.g.airline_theme = "dracula"
			vim.g.airline_solarized_bg = "dark"
			vim.g.airline_section_a = vim.fn["airline#section#create"]({ "mode", "", "branch" })
			vim.g["airline#extensions#tabline#enabled"] = 1
			vim.g["airline#extensions#tabline#show_buffers"] = 0
			vim.g["airline#extensions#tabline#tab_nr_type"] = 1
			vim.g["airline#extensions#tabline#fnamemod"] = ":t"
		end,
	},

	-- Git integration
	{ "tpope/vim-fugitive", cmd = "Git" },
	{ "airblade/vim-gitgutter", event = "BufReadPre" },

	-- Utilities
	"tpope/vim-abolish",
	{ "editorconfig/editorconfig-vim", event = "BufReadPre" },

	-- Linting (ALE)
	{ "dense-analysis/ale", event = { "BufWritePost", "BufReadPost" } },

	-- Snippets
	{ "honza/vim-snippets", dependencies = { "SirVer/ultisnips" } },
	{ "SirVer/ultisnips", event = "InsertEnter" },

	-- LSP and Autocompletion
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
	{
		"epwalsh/obsidian.nvim",
		version = "*", -- recommended, use latest release instead of latest commit
		lazy = true,
		ft = "markdown",
		dependencies = {
			-- Required.
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			workspaces = {
				{
					name = "current-dir",
					path = vim.fn.getcwd(),
				},
			},
			ui = {
				enable = true, -- set to false to disable all additional syntax features
				update_debounce = 200, -- update delay after a text change (in milliseconds)
				max_file_length = 5000, -- disable UI features for files with more than this many lines
				-- Define how various check-boxes are displayed
				checkboxes = {
					-- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
					[" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
					["x"] = { char = "", hl_group = "ObsidianDone" },
					[">"] = { char = "", hl_group = "ObsidianRightArrow" },

					["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
					["!"] = { char = "", hl_group = "ObsidianImportant" },
					-- Replace the above with this if you don't have a patched font:

					-- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
					-- ["x"] = { char = "✔", hl_group = "ObsidianDone" },

					-- You can also add more custom ones...
				},

				-- Use bullet marks for non-checkbox lists.
				bullets = { char = "•", hl_group = "ObsidianBullet" },
				external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
				-- Replace the above with this if you don't have a patched font:
				-- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },

				reference_text = { hl_group = "ObsidianRefText" },
				highlight_text = { hl_group = "ObsidianHighlightText" },
				tags = { hl_group = "ObsidianTag" },
				block_ids = { hl_group = "ObsidianBlockID" },
				hl_groups = {
					-- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
					ObsidianTodo = { bold = true, fg = "#f78c6c" },

					ObsidianDone = { bold = true, fg = "#89ddff" },

					ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
					ObsidianTilde = { bold = true, fg = "#ff5370" },
					ObsidianImportant = { bold = true, fg = "#d73128" },
					ObsidianBullet = { bold = true, fg = "#89ddff" },
					ObsidianRefText = { underline = true, fg = "#c792ea" },
					ObsidianExtLinkIcon = { fg = "#c792ea" },
					ObsidianTag = { italic = true, fg = "#89ddff" },
					ObsidianBlockID = { italic = true, fg = "#89ddff" },
					ObsidianHighlightText = { bg = "#75662e" },
				},
			},
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
	},
})

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })

require("telescope").setup({
	defaults = {
		-- レイアウトとサイズに関する設定
		layout_strategy = "horizontal",
		layout_config = {
			width = 0.95,
			height = 0.90,
		},

		borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },

		sorting_strategy = "ascending",
	},
	pickers = {
		find_files = {
			hidden = true,
		},
	},
})

--[[
================================================================================
  Post-Plugin Setup
================================================================================
]]
vim.opt.background = "dark"
vim.cmd.colorscheme("dracula")
