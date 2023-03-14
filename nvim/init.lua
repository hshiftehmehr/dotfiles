vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.opt.background = "dark"
vim.opt.colorcolumn = "80"
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.spell = true
vim.opt.syntax = "enable"
vim.opt.tabstop = 4

-- Restore the last known cursor position when a buffer is loaded
vim.api.nvim_create_autocmd("BufRead", {
	command = [[
        if &ft !~# 'commit\|rebase' && line("'\"") > 1 && line("'\"") <= line("$")
            exe 'normal! g`"'
        endif
    ]],
})

-- Initialize the plugin manager
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

require("lazy").setup({
	{
		"jay-babu/mason-null-ls.nvim",
		config = function()
			require("mason-null-ls").setup({
				ensure_installed = {
					-- Lua
					"stylua",
					"lua-language-server",
					-- jsonnet
					"jsonnet-language-server",
					-- YAML
					"yaml-language-server",
					-- Go
					"golangci-lint",
					"gopls",
					-- puppet
					"puppet-editor-services",
				},
				automatic_setup = true,
			})
			require("mason-null-ls").setup_handlers()
		end,
		dependencies = {
			{
				"williamboman/mason-lspconfig.nvim",
				dependencies = {
					{ "neovim/nvim-lspconfig" },
					{ "williamboman/mason.nvim" },
					{
						"hrsh7th/nvim-cmp",
						config = function()
							local cmp = require("cmp")
							local luasnip = require("luasnip")

							cmp.setup({
								mapping = cmp.mapping.preset.insert({
									["<C-Space>"] = cmp.mapping.complete(),
									["<CR>"] = cmp.mapping.confirm({
										select = true,
										behavior = cmp.ConfirmBehavior.Replace,
									}),
									["<Tab>"] = cmp.mapping(function(fallback)
										if cmp.visible() then
											cmp.select_next_item()
										elseif luasnip.expand_or_jumpable() then
											luasnip.expand_or_jump()
										else
											fallback()
										end
									end, { "i", "s" }),
									["<S-Tab>"] = cmp.mapping(function(fallback)
										if cmp.visible() then
											cmp.select_prev_item()
										elseif luasnip.jumpable(-1) then
											luasnip.jump(-1)
										else
											fallback()
										end
									end, { "i", "s" }),
								}),
								sources = cmp.config.sources({
									{ name = "nvim_lsp" },
									{ name = "luasnip" },
									{ name = "buffer" },
									{ name = "path" },
								}),
								snippet = {
									expand = function(args)
										require("luasnip").lsp_expand(args.body)
									end,
								},
							})
						end,
						dependencies = {
							{ "hrsh7th/cmp-nvim-lsp" },
							{
								"L3MON4D3/LuaSnip",
								-- install jsregexp (optional!).
								-- build = "make install_jsregexp",
							},
							{ "hrsh7th/cmp-path" }, -- Optional
							{ "hrsh7th/cmp-buffer" }, -- Optional
							-- { "saadparwaiz1/cmp_luasnip" }, -- Optional
						},
					},
				},
				config = function()
					require("mason").setup()
					require("mason-lspconfig").setup()

					local default_capabilities = require("cmp_nvim_lsp").default_capabilities()

					-- automatically set up LSP servers `:h mason-lspconfig-automatic-server-setup`
					require("mason-lspconfig").setup_handlers({
						function(server_name) -- default handler (optional)
							require("lspconfig")[server_name].setup({
								capabilities = default_capabilities,
							})
						end,
					})
				end,
			},
			{
				"jose-elias-alvarez/null-ls.nvim",
				dependencies = { { "nvim-lua/plenary.nvim" } },
				config = function()
					local null_ls = require("null-ls")

					null_ls.setup({
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
			},
		},
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
				telescope.extensions.file_browser.file_browser({ dir_icon = "/" })
			end, {})
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
		"nvim-tree/nvim-tree.lua",
		config = function()
			require("nvim-tree").setup({
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
			})

			-- Quit if nvim-tree is the last open buffer
			vim.api.nvim_create_autocmd("BufEnter", {
				nested = true,
				callback = function()
					if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
						vim.cmd("quit")
					end
				end,
			})

			-- Toggle nvim-tree when nvim starts
			vim.api.nvim_create_autocmd({ "VimEnter" }, {
				callback = function(data)
					local real_file = vim.fn.filereadable(data.file) == 1
					local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

					if not real_file and not no_name then
						return
					end

					require("nvim-tree.api").tree.toggle({ focus = false, find_file = true })
				end,
			})
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
			{ "lewis6991/gitsigns.nvim", config = true },
			{ "kevinhwang91/nvim-hlslens", config = true },
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			options = {
				icons_enabled = false,
				section_separators = "",
				component_separators = "",
			},
			sections = {
				lualine_c = {
					{
						"filename",
						path = 1, -- Show relative path
					},
				},
			},
		},
		dependencies = {
			{
				"folke/tokyonight.nvim",
				config = function()
					vim.cmd([[colorscheme tokyonight-night]])
				end,
			},
		},
	},
	{
		"numToStr/FTerm.nvim",
		config = function()
			local shell = require("FTerm")
			shell.setup({})

			vim.keymap.set("n", "<leader>sh", shell.toggle, {})
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		opts = {
			show_current_context = true,
			show_current_context_start = true,
		},
	},
	{ "tomtom/tcomment_vim" },
	{ "michaeljsmith/vim-indent-object" },
	{ "google/vim-jsonnet" },
	{ "rodjek/vim-puppet" },
})

vim.api.nvim_create_autocmd("FileType", {
	desc = "JSON/YAML specific editor options",
	pattern = { "jsonnet", "json", "yaml" },
	callback = function()
		vim.opt.shiftwidth = 2
		vim.opt.tabstop = 2
	end,
})
