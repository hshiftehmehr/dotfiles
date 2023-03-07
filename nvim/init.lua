vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
-- vim.opt.background = "dark"
vim.opt.colorcolumn = "80"
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.spell = true
vim.opt.syntax = "enable"
vim.opt.tabstop = 4

if vim.g.neovide then
	vim.cmd([[ cd ~/Repositories/ ]])
	vim.g.neovide_fullscreen = true
	vim.g.neovide_input_use_logo = true -- enable use of the logo (cmd) key
	vim.keymap.set("v", "<D-c>", '"+y') -- Copy
	vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
	vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
	vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
	vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode
end

-- Allow clipboard copy paste in neovim
vim.g.neovide_input_use_logo = true
vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })

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
		branch = "v2.x",
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
			local lsp = require("lsp-zero").preset({
				name = "minimal",
				set_lsp_keymaps = true,
				manage_nvim_cmp = true,
				suggest_lsp_servers = false,
			})

			-- (Optional) Configure lua language server for neovim
			lsp.nvim_workspace()

			lsp.setup()
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
					null_ls.builtins.formatting.prettier,
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
			options = (function()
				if vim.g.neovide then
					return {
						theme = "onedark",
					}
				else
					return {
						theme = "onedark",
						icons_enabled = false,
						section_separators = "",
						component_separators = "",
					}
				end
			end)(),
		},
	},
	{
		"nvim-tree/nvim-tree.lua",
		opts = (function()
			vim.api.nvim_create_autocmd({ "VimEnter" }, {
				callback = function(data)
					-- buffer is a real file on the disk
					local real_file = vim.fn.filereadable(data.file) == 1

					-- buffer is a [No Name]
					local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

					if not real_file and not no_name then
						return
					end

					-- open the tree, find the file but don't focus it
					require("nvim-tree.api").tree.toggle({ focus = false, find_file = true })
				end,
			})

			if vim.g.neovide then
				return {
					update_focused_file = {
						enable = true,
						update_root = true,
					},
				}
			else
				return {
					update_focused_file = {
						enable = true,
						update_root = true,
					},
					renderer = {
						icons = {
							show = {
								file = false,
								folder = false,
								folder_arrow = false,
								git = false,
								modified = false,
							},
						},
					},
				}
			end
		end)(),
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
			{ "BurntSushi/ripgrep" },
			{
				"natecraddock/workspaces.nvim",
				opts = {
					hooks = {
						open = "Telescope find_files",
					},
				},
			},
			{ "nvim-telescope/telescope-github.nvim" },
			{ "nvim-telescope/telescope-file-browser.nvim" },
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
			telescope.load_extension("file_browser")

			vim.keymap.set("n", "<leader>ws", telescope.extensions.workspaces.workspaces, {})
			vim.keymap.set("n", "<leader>pr", telescope.extensions.gh.pull_request, {})
			vim.keymap.set("n", "<leader>ls", function()
				telescope.extensions.file_browser.file_browser((function()
					if vim.g.neovide then
						return nil
					else
						return { dir_icon = "/" }
					end
				end)())
			end, {})
			vim.keymap.set("n", "<leader>git", builtin.git_status, {})
			vim.keymap.set("n", "<leader>br", function()
				builtin.git_branches({ show_remote_tracking_branches = false })
			end, {})
			vim.keymap.set("n", "<leader>b", builtin.buffers, {})
			vim.keymap.set("n", "<leader>f", builtin.find_files, {})
			vim.keymap.set("n", "<leader>g", builtin.live_grep, {})
			vim.keymap.set("n", "<leader>d", builtin.diagnostics, {})
		end,
	},
	{
		"akinsho/toggleterm.nvim",
		config = function()
			local Terminal = require("toggleterm.terminal").Terminal
			vim.keymap.set("n", "<leader>sh", function()
				Terminal:new({ direction = "float" }):toggle()
			end)
		end,
	},
	{
		"petertriho/nvim-scrollbar",
		config = function()
			require("scrollbar").setup()
			require("scrollbar.handlers.gitsigns").setup()
			require("scrollbar.handlers.search").setup()
		end,
		dependencies = {
			{ "lewis6991/gitsigns.nvim",   config = true },
			{ "kevinhwang91/nvim-hlslens", config = true },
		},
	},
	{ "tomtom/tcomment_vim" },
	{ "michaeljsmith/vim-indent-object" },
	{ "google/vim-jsonnet" },
	{ "rodjek/vim-puppet" },
})

vim.api.nvim_create_autocmd("BufEnter", {
	nested = true,
	callback = function()
		if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
			vim.cmd("quit")
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	desc = "Lua specific editor options",
	pattern = { "lua" },
	callback = function()
		vim.opt_local.expandtab = false
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	desc = "JSON/YAML specific editor options",
	pattern = { "jsonnet", "json", "yaml" },
	callback = function()
		vim.opt.shiftwidth = 2
		vim.opt.tabstop = 2
	end,
})
