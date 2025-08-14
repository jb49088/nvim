return {
    "saghen/blink.cmp",
    -- enabled = false,
    event = { "InsertEnter", "CmdlineEnter" },
    version = "1.*",
    dependencies = {
        "rafamadriz/friendly-snippets",
        "folke/lazydev.nvim",
        "archie-judd/blink-cmp-words",
    },
    opts = {
        keymap = {
            preset = "enter",
            ["<C-y>"] = { "select_and_accept" },
        },
        appearance = {
            nerd_font_variant = "mono",
        },
        completion = {
            ghost_text = {
                enabled = false,
            },
            menu = {
                border = "rounded",
                scrollbar = true,
                draw = {
                    columns = {
                        { "kind_icon" },
                        { "label", "label_description", "kind", gap = 1 },
                    },
                    components = {
                        kind_icon = {
                            text = function(ctx)
                                local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
                                return kind_icon .. " "
                            end,
                            highlight = function(ctx)
                                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                                return hl
                            end,
                        },
                        kind = {
                            highlight = function(ctx)
                                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                                return hl
                            end,
                        },
                    },
                    treesitter = {
                        "lsp",
                    },
                },
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 200,
                window = {
                    border = "rounded",
                    scrollbar = true,
                },
            },
            list = {
                selection = {
                    preselect = false,
                    auto_insert = true,
                },
            },
        },
        cmdline = {
            enabled = false,
        },
        sources = {
            -- default = { "lsp", "path", "snippets", "buffer", "lazydev" },
            default = { "lsp", "path", "snippets", "buffer", "lazydev", "dictionary" },
            providers = {
                lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
                dictionary = {
                    name = "blink-cmp-words",
                    module = "blink-cmp-words.dictionary",
                    opts = {
                        dictionary_search_threshold = 3,
                        score_offset = 0,
                        definition_pointers = { "!", "&", "^" },
                    },
                },
            },
        },
        snippets = { preset = "luasnip" },
        fuzzy = { implementation = "lua" },
        signature = {
            enabled = true,
            window = {
                show_documentation = true,
                border = "rounded",
            },
        },
    },
}

-- return {
--     "saghen/blink.cmp",
--     version = "1.*",
--     opts = {},
-- }
