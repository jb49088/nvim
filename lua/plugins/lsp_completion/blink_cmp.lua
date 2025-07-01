return {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    version = "1.*",
    dependencies = {
        {
            "L3MON4D3/LuaSnip",
            version = "2.*",
            build = (function()
                if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
                    return
                end
                return "make install_jsregexp"
            end)(),
            dependencies = {},
            opts = {},
        },
        "folke/lazydev.nvim",
    },
    opts = {
        keymap = {
            preset = "enter",
        },
        appearance = {
            nerd_font_variant = "mono",
        },
        completion = {
            menu = {
                border = "rounded",
                scrollbar = false,
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 500,
                window = {
                    border = "rounded",
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
            keymap = {
                preset = "inherit",
            },
            completion = {
                menu = { auto_show = true },
                list = {
                    selection = {
                        preselect = false,
                        auto_insert = true,
                    },
                },
            },
        },
        sources = {
            default = { "lsp", "path", "snippets", "lazydev" },
            providers = {
                lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
                cmdline = {
                    -- ignores cmdline completions when executing shell commands (:! enumerates all executables in Windows path otherwise)
                    enabled = function()
                        local cmdtype = vim.fn.getcmdtype()
                        local cmdline = vim.fn.getcmdline()
                        if
                            cmdtype == ":"
                            and (
                                cmdline:match("^%s*[%%0-9,'<>%-]*!%s*") -- :! or :%! etc.
                                or cmdline:match("^%s*w!?%s+!%s*") -- :w ! or :w! !
                            )
                        then
                            return false
                        end
                        return true
                    end,
                    -- when typing a command, only show when the keyword is 3 characters or longer
                    min_keyword_length = function(ctx)
                        if ctx.mode == "cmdline" and string.find(ctx.line, " ") == nil then
                            return 3
                        end
                        return 0
                    end,
                },
            },
        },
        snippets = { preset = "luasnip" },
        fuzzy = { implementation = "lua" },
        signature = {
            enabled = false,
            window = {
                border = "rounded",
            },
        },
    },
}
