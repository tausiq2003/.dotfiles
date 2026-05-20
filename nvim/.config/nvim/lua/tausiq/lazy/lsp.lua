return {
    "neovim/nvim-lspconfig",
    event = {"BufReadPre", "BufNewFile"},
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
        "onsails/lspkind.nvim",
        "olrtg/emmet-language-server",
        "rafamadriz/friendly-snippets",
        "NvChad/nvim-colorizer.lua",
        "roobert/tailwindcss-colorizer-cmp.nvim",
    },

    config = function()
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),

            cmp_lsp.default_capabilities())

            capabilities.textDocument.completion.completionItem.snippetSupport = true

            require("fidget").setup({})

            -- Configure lua_ls globally with love2d support
            vim.lsp.config('lua_ls', {
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = {
                            globals = { "vim", "love" },
                        },
                        workspace = {
                            library = {
                                vim.env.VIMRUNTIME,
                                "${3rd}/love2d/library",
                                "${3rd}/luv/library",
                            },
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
            })

            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "rust_analyzer",
                    --cpp
                    "clangd",
                    --python
                    "pyright",
                    "ruff",

                    --golang
                    "gopls",
                    --webdev
                    "ts_ls",
                    "tailwindcss",
                },
                handlers = {
                    function(server_name) -- default handler (optional)

                        require("lspconfig")[server_name].setup {
                            capabilities = capabilities
                        }
                    end,



                    ["ts_ls"] = function()
                        require("lspconfig").ts_ls.setup{
                            capabilities = capabilities, -- ADD THIS
                            filetypes = { "typescript", "typescriptreact", "typescript.tsx"},
                            cmd = {"typescript-language-server" ,"--stdio"}
                        }
                    end,
                    ["pyright"] = function()
                        require("lspconfig").pyright.setup{
                            capabilities = capabilities,
                            filetypes={"python"}
                        }


                    end,
                    ["emmet_language_server"] = function()
                        require("lspconfig").emmet_language_server.setup({
                            capabilities = capabilities,
                            filetypes = { "css", "eruby", "html", "javascript", "javascriptreact", "less", "sass", "scss", "pug", "typescriptreact" },
                        })
                    end,


                }
            })

            local cmp_select = { behavior = cmp.SelectBehavior.Select }


            cmp.setup({
                formatting = {
                    format = function(entry, item)
                        require('lspkind').cmp_format({ width_text = false, maxwidth = 50 })(entry, item)
                        return require("tailwindcss-colorizer-cmp").formatter(entry, item)
                    end
                },
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    -- ["<C-Space>"] = cmp.mapping.complete(),
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' }, -- For `luasnip` users.
                }, {
                    { name = 'buffer' },
                })
            })

            require("luasnip.loaders.from_vscode").lazy_load()
            require("luasnip.loaders.from_vscode").lazy_load({
                paths = { vim.fn.stdpath("config") .. "/lua/tausiq/my-own-snippets" }
            })
            require("luasnip").filetype_extend("javascriptreact", { "html" })
            require("luasnip").filetype_extend("typescriptreact", { "html" })
            require("colorizer").setup({
                user_default_options = {
                    tailwind = true,
                },
            })


            require('lspkind').init({
                -- DEPRECATED (use mode instead): enables text annotations
                --
                -- default: true
                -- with_text = true,

                -- defines how annotations are shown
                -- default: symbol
                -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
                mode = 'symbol_text',

                -- default symbol map
                -- can be either 'default' (requires nerd-fonts font) or
                -- 'codicons' for codicon preset (requires vscode-codicons font)
                --
                -- default: 'default'
                preset = 'codicons',

                -- override preset symbols
                --
                -- default: {}
                symbol_map = {
                    Text = "󰉿",
                    Method = "󰆧",
                    Function = "󰊕",
                    Constructor = "",
                    Field = "󰜢",
                    Variable = "󰀫",
                    Class = "󰠱",
                    Interface = "",
                    Module = "",
                    Property = "󰜢",
                    Unit = "󰑭",
                    Value = "󰎠",
                    Enum = "",
                    Keyword = "󰌋",
                    Snippet = "",
                    Color = "󰏘",
                    File = "󰈙",
                    Reference = "󰈇",
                    Folder = "󰉋",
                    EnumMember = "",
                    Constant = "󰏿",
                    Struct = "󰙅",
                    Event = "",
                    Operator = "󰆕",
                    TypeParameter = "",
                },
            })
            vim.diagnostic.config({
                -- update_in_insert = true,
                float = {
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            })
        end
    }
