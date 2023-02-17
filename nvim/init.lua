vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.opt.colorcolumn = "80"
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.spell = true
vim.opt.syntax = "enable"
vim.opt.tabstop = 4

vim.api.nvim_create_autocmd("BufRead", {
	command = [[
        if &ft !~# 'commit\|rebase' && line("'\"") > 1 && line("'\"") <= line("$")
            exe 'normal! g`"'
        endif
    ]],
})

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

local lazy = require("lazy")
lazy.setup({
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "dev-v2",
		--   branch = 'v1.x',
		dependencies = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" }, -- Required
			{ "williamboman/mason.nvim" }, -- Optional
			{ "williamboman/mason-lspconfig.nvim" }, -- Optional

			-- Autocompletion
			{
				"hrsh7th/nvim-cmp", -- Required
				config = function()
					local cmp = require("cmp")

					cmp.setup({
						mapping = cmp.mapping.preset.insert({
							["<C-Space>"] = cmp.mapping.complete(),
							["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
						}),
					})
				end,
			},
			{ "hrsh7th/cmp-nvim-lsp" }, -- Required
			{ "hrsh7th/cmp-buffer" }, -- Optional
			{ "hrsh7th/cmp-path" }, -- Optional
			{ "saadparwaiz1/cmp_luasnip" },
			{ "hrsh7th/cmp-nvim-lua" },

			-- Snippets
			{ "L3MON4D3/LuaSnip" }, -- Required
			-- {'rafamadriz/friendly-snippets'}, -- Optional
		},
		config = function()
			local lsp_zero = require("lsp-zero")
			lsp_zero.preset("recommended")
			-- (Optional) Configure lua language server for neovim
			lsp_zero.nvim_workspace()
			lsp_zero.setup()
		end,
	},
	{
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			local null_ls = require("null-ls")
			local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
			null_ls.setup({
				sources = {
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.completion.spell,
				},
				-- https://github.com/jose-elias-alvarez/null-ls.nvim/wiki/Formatting-on-save
				on_attach = function(client, bufnr)
					if client.supports_method("textDocument/formatting") then
						vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
						vim.api.nvim_create_autocmd("BufWritePre", {
							group = augroup,
							buffer = bufnr,
							callback = function()
								vim.lsp.buf.format({ bufnr = bufnr })
							end,
						})
					end
				end,
			})
		end,
		dependencies = {
			{ "nvim-lua/plenary.nvim" }, -- Required
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			local treesitter = require("nvim-treesitter")
			treesitter.setup()

			local treesitter_configs = require("nvim-treesitter.configs")
			treesitter_configs.setup({
				-- Automatically install missing parsers when entering buffer
				-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
				auto_install = (vim.fn.executable("tree-sitter") == 1),
				highlight = {
					enable = true,
				},
			})
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			{
				"navarasu/onedark.nvim",
				config = function()
					local onedark = require("onedark")
					onedark.setup({ style = "darker" })
					onedark.load()
				end,
			},
		},
		opts = {
			options = {
				icons_enabled = false,
				theme = "onedark",
				section_separators = "",
				component_separators = "",
			},
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
			{ "BurntSushi/ripgrep" },
			{ "natecraddock/workspaces.nvim", config = true },
			{ "nvim-telescope/telescope-github.nvim" },
		},
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")

			telescope.setup({
				defaults = {
					file_ignore_patterns = { "_output" },
					show_remote_tracking_branches = false,
				},
			})
			telescope.load_extension("workspaces")

			vim.keymap.set("n", "<leader>ws", telescope.extensions.workspaces.workspaces, {})
			vim.keymap.set("n", "<leader>pr", telescope.extensions.gh.pull_request, {})
			vim.keymap.set("n", "<leader>git", builtin.git_status, {})
			vim.keymap.set("n", "<leader>br", function()
				builtin.git_branches({ show_remote_tracking_branches = false })
			end, {})
			vim.keymap.set("n", "<leader>b", builtin.buffers, {})
			vim.keymap.set("n", "<leader>f", builtin.find_files, {})
			vim.keymap.set("n", "<leader>g", builtin.live_grep, {})
		end,
	},
	{ "tomtom/tcomment_vim" },
	{ "google/vim-jsonnet" },
	{ "lewis6991/gitsigns.nvim", config = true },
	{ "gorbit99/codewindow.nvim", opts = { auto_enable = true } },
})

vim.api.nvim_create_autocmd("FileType", {
	desc = "Lua specific editor options",
	pattern = { "lua" },
	callback = function(opts)
		vim.opt_local.expandtab = false
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	desc = "JSON/YAML specific editor options",
	pattern = { "jsonnet", "json", "yaml" },
	callback = function(opts)
		vim.opt.shiftwidth = 2
		vim.opt.tabstop = 2
	end,
})
